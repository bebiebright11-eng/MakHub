import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_algorithm.dart';

/// Expected payment amount — must match PaymentConstants.totalAmount
/// used in payment_screen.dart (50,000 UGX booking fee).
const int kExpectedPaymentAmount = 50000;

/// Verifies a payment and performs all downstream updates:
///   1. Confirms payment exists
///   2. Verifies the amount is correct
///   3. Updates payment status → 'confirmed'
///   4. Updates booking status → 'confirmed'
///   5. Reserves the room (increments occupied, sets status to Reserved or Occupied)
///   6. Notifies the student
class PaymentVerificationAlgorithm {
  const PaymentVerificationAlgorithm._();

  /// [paymentId] — Firestore document ID from the `payments` collection.
  static Future<PaymentVerificationResult> verify(String paymentId) async {
    // ── 1. Fetch payment ──────────────────────────────────────────────────
    final paymentRef = FirebaseFirestore.instance
        .collection('payments')
        .doc(paymentId);

    final paymentSnap = await paymentRef.get();
    if (!paymentSnap.exists) {
      return const PaymentVerificationResult.failed('Payment record not found.');
    }

    final payment = paymentSnap.data()!;
    final currentStatus = (payment['paymentStatus'] ?? '').toString();

    if (currentStatus == 'confirmed') {
      return const PaymentVerificationResult.failed('Payment already confirmed.');
    }

    // ── 2. Verify amount ──────────────────────────────────────────────────
    final raw = payment['amount'];
    final int? amount =
        raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');

    if (amount == null || amount < kExpectedPaymentAmount) {
      return PaymentVerificationResult.failed(
        'Amount mismatch. Expected UGX $kExpectedPaymentAmount, got UGX ${amount ?? 0}.',
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
    String hostelName = '';
    String roomNumber = '';

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

    // ── 5. Reserve the room ───────────────────────────────────────────────
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
        roomNumber = (rd['roomNumber'] ?? roomId).toString();
        final int capacity =
            (rd['capacity'] is int ? rd['capacity'] : int.tryParse(rd['capacity'].toString())) ?? 1;
        final int currentOccupied =
            (rd['occupied'] is int ? rd['occupied'] : int.tryParse(rd['occupied'].toString())) ?? 0;
        final int newOccupied = (currentOccupied + 1).clamp(0, capacity);

        await roomRef.update({
          'occupied': newOccupied,
          'status': newOccupied >= capacity ? 'Occupied' : 'Reserved',
        });
      }

      // Fetch hostel name
      final hostelSnap = await FirebaseFirestore.instance
          .collection('hostels')
          .doc(hostelId)
          .get();
      if (hostelSnap.exists) {
        hostelName =
            (hostelSnap.data()?['hostelName'] ?? hostelId).toString();
      }
    }

    // ── 6. Notify student ─────────────────────────────────────────────────
    if (studentId.isNotEmpty) {
      await NotificationAlgorithm.bookingConfirmed(
        studentId: studentId,
        hostelName: hostelName,
        roomNumber: roomNumber,
      );
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
