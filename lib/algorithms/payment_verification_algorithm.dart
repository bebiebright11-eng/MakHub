import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_algorithm.dart';
import 'booking_id_service.dart';
import '/core/constants/payment_constants.dart';

/// Expected payment amount — reads from PaymentConstants so it stays
/// in sync if the booking fee changes in the future.
int get kExpectedPaymentAmount => PaymentConstants.totalAmount;

/// Verifies a payment and performs all downstream updates:
///   1. Confirms payment exists
///   2. Verifies the amount is correct
///   3. Updates payment status → 'confirmed'
///   4. Updates booking status → 'confirmed'
///   5. Updates room occupancy:
///        occupied += 1
///        status → 'Occupied' when occupied >= capacity, else 'Available'
///   6. Notifies the student
class PaymentVerificationAlgorithm {
  const PaymentVerificationAlgorithm._();

  /// Confirms a payment, booking, and room occupancy in one transaction.
  /// This prevents concurrent approvals from overbooking a room.
  static Future<PaymentVerificationResult> verify(String paymentId) async {
    final db = FirebaseFirestore.instance;
    final paymentRef = db.collection('payments').doc(paymentId);
    String bookingId = '';
    String studentId = '';
    String hostelId = '';

    try {
      await db.runTransaction((transaction) async {
        final paymentSnap = await transaction.get(paymentRef);
        if (!paymentSnap.exists) {
          throw StateError('Payment record not found.');
        }
        final payment = paymentSnap.data()!;
        if ((payment['paymentStatus'] ?? '').toString() != 'pending') {
          throw StateError('Only pending payments can be confirmed.');
        }
        final rawAmount = payment['amount'];
        final amount = rawAmount is num
            ? rawAmount.toInt()
            : int.tryParse(rawAmount?.toString() ?? '');
        if (amount != kExpectedPaymentAmount) {
          throw StateError('Payment amount does not match the booking fee.');
        }

        bookingId = (payment['bookingId'] ?? '').toString();
        if (bookingId.isEmpty) {
          throw StateError('Payment has no booking reference.');
        }
        final bookingRef = db.collection('bookings').doc(bookingId);
        final bookingSnap = await transaction.get(bookingRef);
        if (!bookingSnap.exists) {
          throw StateError('Booking record not found.');
        }
        final booking = bookingSnap.data()!;
        if ((booking['bookingStatus'] ?? '').toString() != 'pending') {
          throw StateError('Only pending bookings can be confirmed.');
        }

        studentId = (booking['studentId'] ?? '').toString();
        hostelId = (booking['hostelId'] ?? '').toString();
        final floorId = (booking['floorId'] ?? '').toString();
        final roomId = (booking['roomId'] ?? '').toString();
        if (hostelId.isEmpty || floorId.isEmpty || roomId.isEmpty) {
          throw StateError('Booking is missing room details.');
        }

        final roomRef = db
            .collection('hostels')
            .doc(hostelId)
            .collection('floors')
            .doc(floorId)
            .collection('rooms')
            .doc(roomId);
        final roomSnap = await transaction.get(roomRef);
        if (!roomSnap.exists) {
          throw StateError('The booked room no longer exists.');
        }
        final room = roomSnap.data()!;
        final capacity = room['capacity'] is num
            ? (room['capacity'] as num).toInt()
            : int.tryParse(room['capacity']?.toString() ?? '') ?? 1;
        final occupied = room['occupied'] is num
            ? (room['occupied'] as num).toInt()
            : int.tryParse(room['occupied']?.toString() ?? '') ?? 0;
        if (occupied >= capacity) {
          throw StateError('This room is no longer available.');
        }

        final newOccupied = occupied + 1;
        transaction.update(paymentRef, {
          'paymentStatus': 'confirmed',
          'confirmedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(bookingRef, {'bookingStatus': 'confirmed'});
        transaction.update(roomRef, {
          'occupied': newOccupied,
          'status': newOccupied >= capacity ? 'Occupied' : 'Available',
        });
      });
    } on StateError catch (error) {
      return PaymentVerificationResult.failed(error.message);
    } catch (_) {
      return const PaymentVerificationResult.failed(
        'Unable to confirm payment. Please try again.',
      );
    }

    if (studentId.isNotEmpty) {
      await NotificationAlgorithm.roomReserved(
        studentId: studentId,
        bookingId: bookingId,
      );
    }
    if (bookingId.isNotEmpty && hostelId.isNotEmpty) {
      try {
        await BookingIdService.assignBookingId(
          bookingDocId: bookingId,
          hostelId: hostelId,
        );
      } catch (_) {
        // A display ID can be backfilled without invalidating the reservation.
      }
    }
    return const PaymentVerificationResult.success();
  }

  /// [paymentId] — Firestore document ID from the `payments` collection.
  // ignore: unused_element
  static Future<PaymentVerificationResult> _verifyLegacy(
    String paymentId,
  ) async {
    // ── 1. Fetch payment ──────────────────────────────────────────────────
    final paymentRef = FirebaseFirestore.instance
        .collection('payments')
        .doc(paymentId);

    final paymentSnap = await paymentRef.get();
    if (!paymentSnap.exists) {
      return const PaymentVerificationResult.failed(
        'Payment record not found.',
      );
    }

    final payment = paymentSnap.data()!;
    final currentStatus = (payment['paymentStatus'] ?? '').toString();

    if (currentStatus == 'confirmed') {
      return const PaymentVerificationResult.failed(
        'Payment already confirmed.',
      );
    }

    // ── 2. Verify amount ──────────────────────────────────────────────────
    final raw = payment['amount'];
    final int? amount = raw is num
        ? raw.toInt()
        : int.tryParse(raw?.toString() ?? '');

    if (amount == null || amount < kExpectedPaymentAmount) {
      return PaymentVerificationResult.failed(
        'Amount mismatch. Expected UGX $kExpectedPaymentAmount, '
        'got UGX ${amount ?? 0}.',
      );
    }

    // ── 3. Confirm payment ────────────────────────────────────────────────
    await paymentRef.update({
      'paymentStatus': 'confirmed',
      'confirmedAt': FieldValue.serverTimestamp(),
    });

    // ── 4. Update booking ─────────────────────────────────────────────────
    final String bookingId = (payment['bookingId'] ?? '').toString();
    String studentId = '';
    String hostelId = '';
    String floorId = '';
    String roomId = '';

    if (bookingId.isNotEmpty) {
      final bookingRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId);

      final bookingSnap = await bookingRef.get();
      if (bookingSnap.exists) {
        final b = bookingSnap.data()!;
        studentId = (b['studentId'] ?? '').toString();
        hostelId = (b['hostelId'] ?? '').toString();
        floorId = (b['floorId'] ?? '').toString();
        roomId = (b['roomId'] ?? '').toString();

        await bookingRef.update({'bookingStatus': 'confirmed'});
      }
    }

    // ── 5. Update room occupancy ──────────────────────────────────────────
    //
    // Occupancy rules:
    //   Single room  capacity=1: 0/1 → 1/1 → status 'Occupied'
    //   Double room  capacity=2: 0/2 → 1/2 → status 'Available'
    //                            1/2 → 2/2 → status 'Occupied'
    if (hostelId.isNotEmpty && floorId.isNotEmpty && roomId.isNotEmpty) {
      final roomRef = FirebaseFirestore.instance
          .collection('hostels')
          .doc(hostelId)
          .collection('floors')
          .doc(floorId)
          .collection('rooms')
          .doc(roomId);

      final roomSnap = await roomRef.get();
      if (roomSnap.exists) {
        final rd = roomSnap.data()!;

        final int capacity = rd['capacity'] is int
            ? rd['capacity'] as int
            : int.tryParse(rd['capacity'].toString()) ?? 1;

        final int currentOccupied = rd['occupied'] is int
            ? rd['occupied'] as int
            : int.tryParse(rd['occupied'].toString()) ?? 0;

        final int newOccupied = (currentOccupied + 1).clamp(0, capacity);

        await roomRef.update({
          'occupied': newOccupied,
          'status': newOccupied >= capacity ? 'Occupied' : 'Available',
        });
      }
    }

    // ── 6. Notify student ─────────────────────────────────────────────────
    if (studentId.isNotEmpty && bookingId.isNotEmpty) {
      await NotificationAlgorithm.roomReserved(
        studentId: studentId,
        bookingId: bookingId,
      );
    }

    // ── 7. Generate human-readable Booking ID ─────────────────────────────
    //    Runs only after all prior steps succeed so no ID is wasted.
    if (bookingId.isNotEmpty && hostelId.isNotEmpty) {
      try {
        await BookingIdService.assignBookingId(
          bookingDocId: bookingId,
          hostelId: hostelId,
        );
      } catch (_) {
        // Non-fatal — the booking is already confirmed.  ID can be backfilled.
      }
    }

    return const PaymentVerificationResult.success();
  }
}

class PaymentVerificationResult {
  final bool success;
  final String? errorMessage;

  const PaymentVerificationResult.success()
    : success = true,
      errorMessage = null;

  const PaymentVerificationResult.failed(this.errorMessage) : success = false;
}
