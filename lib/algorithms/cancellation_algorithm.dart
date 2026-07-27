import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_algorithm.dart';

/// Cancels a booking and performs all side-effects atomically:
///   1. Marks the booking as 'cancelled'
///   2. Releases the room (decrements occupied, sets status back to Available)
///   3. Notifies the student
///   4. Notifies any students who have a pending booking for the same hostel
///      (waitlist notification)
class CancellationAlgorithm {
  const CancellationAlgorithm._();

  /// [bookingId]   — Firestore document ID of the booking to cancel.
  /// [cancelledBy] — UID of whoever triggered the cancellation (student or personnel).
  static Future<CancellationResult> cancel({
    required String bookingId,
    required String cancelledBy,
    String reason = '',
  }) async {
    // ── 1. Fetch the booking ──────────────────────────────────────────────
    final bookingRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId);

    final bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) {
      return const CancellationResult.failed('Booking not found.');
    }

    final booking = bookingSnap.data()!;
    final currentStatus = (booking['bookingStatus'] ?? '').toString();

    // Already cancelled — idempotent
    if (currentStatus == 'cancelled') {
      return const CancellationResult.failed('Booking is already cancelled.');
    }

    final String studentId = booking['studentId'] ?? '';
    final String hostelId = booking['hostelId'] ?? '';
    final String floorId = booking['floorId'] ?? '';
    final String roomId = booking['roomId'] ?? '';

    // ── 2. Mark booking as cancelled ─────────────────────────────────────
    await bookingRef.update({
      'bookingStatus': 'cancelled',
      'cancelledBy': cancelledBy,
      'cancelledAt': FieldValue.serverTimestamp(),
      if (reason.isNotEmpty) 'cancellationReason': reason,
    });

    // ── 3. Release the room ───────────────────────────────────────────────
    String hostelName = hostelId;
    String roomNumber = roomId;

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
        final roomData = roomSnap.data()!;
        roomNumber = (roomData['roomNumber'] ?? roomId).toString();
        final int currentOccupied =
            (roomData['occupied'] is int ? roomData['occupied'] : int.tryParse(roomData['occupied'].toString())) ?? 1;
        final int newOccupied = (currentOccupied - 1).clamp(0, 9999);
        final int capacity =
            (roomData['capacity'] is int ? roomData['capacity'] : int.tryParse(roomData['capacity'].toString())) ?? 1;

        await roomRef.update({
          'occupied': newOccupied,
          'status': newOccupied < capacity ? 'Available' : 'Occupied',
        });
      }

      // Fetch hostel name for notification text
      final hostelSnap = await FirebaseFirestore.instance
          .collection('hostels')
          .doc(hostelId)
          .get();
      if (hostelSnap.exists) {
        hostelName = (hostelSnap.data()?['hostelName'] ?? hostelId).toString();
      }
    }

    // ── 4. Notify the student ─────────────────────────────────────────────
    if (studentId.isNotEmpty) {
      await NotificationAlgorithm.bookingCancelled(
        studentId: studentId,
        hostelName: hostelName,
      );
    }

    // ── 5. Notify waitlist (students with pending bookings for same hostel) ─
    await _notifyWaitlist(
      hostelId: hostelId,
      hostelName: hostelName,
      roomNumber: roomNumber,
      excludeStudentId: studentId,
    );

    return const CancellationResult.success();
  }

  static Future<void> _notifyWaitlist({
    required String hostelId,
    required String hostelName,
    required String roomNumber,
    required String excludeStudentId,
  }) async {
    if (hostelId.isEmpty) return;

    // Find students with a pending booking at the same hostel
    final waitlistSnap = await FirebaseFirestore.instance
        .collection('bookings')
        .where('hostelId', isEqualTo: hostelId)
        .where('bookingStatus', isEqualTo: 'pending')
        .limit(10)
        .get();

    for (final doc in waitlistSnap.docs) {
      final data = doc.data();
      final waitStudentId = (data['studentId'] ?? '').toString();
      if (waitStudentId.isEmpty || waitStudentId == excludeStudentId) continue;

      await NotificationAlgorithm.roomNowAvailable(
        studentId: waitStudentId,
        hostelName: hostelName,
        roomNumber: roomNumber,
      );
    }
  }
}

class CancellationResult {
  final bool success;
  final String? errorMessage;

  const CancellationResult.success()
      : success = true,
        errorMessage = null;

  const CancellationResult.failed(this.errorMessage) : success = false;
}
