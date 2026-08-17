import 'package:cloud_firestore/cloud_firestore.dart';

/// Writes in-app notifications to:
///   users/{userId}/notifications/{docId}
///
/// Document schema (matches what NotificationsScreen reads):
///   { title, subtitle, type, createdAt, isRead }
///
/// Notification types used across the app:
///   'booking'  — booking created, confirmed, rejected
///   'payment'  — payment received, confirmed
///   'room'     — room released, room reserved
///   'general'  — system messages
class NotificationAlgorithm {
  const NotificationAlgorithm._();

  // ── Core writer ──────────────────────────────────────────────────────────

  static Future<void> send({
    required String userId,
    required String title,
    required String subtitle,
    required String type,
  }) async {
    assert(userId.isNotEmpty, 'userId must not be empty');
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': title,
      'subtitle': subtitle,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  // ── Convenience methods ─────────────────────────────────────────────────

  /// Notify student that their booking was received.
  static Future<void> bookingSubmitted({
    required String studentId,
    required String bookingId,
    required String hostelName,
  }) =>
      send(
        userId: studentId,
        title: 'Booking Submitted',
        subtitle: 'Your booking for $hostelName (ID: $bookingId) is pending review.',
        type: 'booking',
      );

  /// Notify student that their payment was received and booking is confirmed.
  static Future<void> paymentReceived({
    required String studentId,
    required String bookingId,
    required String amount,
  }) =>
      send(
        userId: studentId,
        title: 'Payment Received',
        subtitle: 'Payment of $amount for booking $bookingId has been received.',
        type: 'payment',
      );

  /// Notify student that personnel confirmed their payment.
  static Future<void> bookingConfirmed({
    required String studentId,
    required String hostelName,
    required String roomNumber,
  }) =>
      send(
        userId: studentId,
        title: 'Booking Confirmed ✓',
        subtitle: 'Your room $roomNumber at $hostelName is confirmed. Welcome!',
        type: 'booking',
      );

  /// Notify student that their booking was rejected.
  static Future<void> bookingRejected({
    required String studentId,
    required String hostelName,
    String reason = '',
  }) =>
      send(
        userId: studentId,
        title: 'Booking Rejected',
        subtitle: reason.isNotEmpty
            ? 'Your booking at $hostelName was rejected. Reason: $reason'
            : 'Your booking at $hostelName was rejected. Please try again.',
        type: 'booking',
      );

  /// Notify student that their booking was cancelled and room is released.
  static Future<void> bookingCancelled({
    required String studentId,
    required String hostelName,
  }) =>
      send(
        userId: studentId,
        title: 'Booking Cancelled',
        subtitle: 'Your booking at $hostelName has been cancelled and the room released.',
        type: 'booking',
      );

  /// Notify a waiting student that a room they might want is now available.
  static Future<void> roomNowAvailable({
    required String studentId,
    required String hostelName,
    required String roomNumber,
  }) =>
      send(
        userId: studentId,
        title: 'Room Available 🏠',
        subtitle: 'Room $roomNumber at $hostelName is now available. Book before it fills up!',
        type: 'room',
      );

  /// Notify student that their room is reserved after successful payment.
  static Future<void> roomReserved({
    required String studentId,
    required String bookingId,
  }) =>
      send(
        userId: studentId,
        title: 'Payment Received',
        subtitle:
            'Your payment has been received successfully.\n'
            'Your room has been reserved successfully.\n'
            'Booking ID: $bookingId',
        type: 'payment',
      );

  /// Notify personnel that a new booking needs review.
  static Future<void> newBookingForPersonnel({
    required String personnelId,
    required String bookingId,
    required String studentName,
  }) =>
      send(
        userId: personnelId,
        title: 'New Booking',
        subtitle: '$studentName submitted booking $bookingId. Please review.',
        type: 'booking',
      );

  /// Notify personnel that a payment was submitted and needs confirmation.
  static Future<void> paymentPendingForPersonnel({
    required String personnelId,
    required String bookingId,
    required String amount,
  }) =>
      send(
        userId: personnelId,
        title: 'Payment Pending',
        subtitle: 'Payment of $amount for booking $bookingId awaits your confirmation.',
        type: 'payment',
      );

  /// Notify student to report before the reporting date.
  /// Sent automatically right after [roomReserved] when a payment is confirmed.
  ///
  /// Fetches:
  ///   - Student display name  from users/{studentId}
  ///   - Reporting date        from hostels/{hostelId}  (reportingDate field)
  ///
  /// Falls back gracefully when either value is unavailable.
  static Future<void> reportingDateReminder({
    required String studentId,
    required String bookingId,
    required String hostelId,
  }) async {
    assert(studentId.isNotEmpty, 'studentId must not be empty');

    // ── Fetch student name ────────────────────────────────────────────────
    String studentName = 'Student';
    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .get();
      if (userSnap.exists) {
        studentName =
            (userSnap.data()?['fullName'] ?? '').toString().trim();
        if (studentName.isEmpty) studentName = 'Student';
      }
    } catch (_) {
      // Non-fatal — fall back to generic salutation.
    }

    // ── Fetch reporting date ──────────────────────────────────────────────
    String reportingDateStr =
        'Reporting date will be communicated by the hostel.';
    try {
      if (hostelId.isNotEmpty) {
        final hostelSnap = await FirebaseFirestore.instance
            .collection('hostels')
            .doc(hostelId)
            .get();
        if (hostelSnap.exists) {
          final ts =
              hostelSnap.data()?['reportingDate'] as Timestamp?;
          if (ts != null) {
            final d = ts.toDate();
            reportingDateStr =
                '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
          }
        }
      }
    } catch (_) {
      // Non-fatal — fall back to generic message.
    }

    final bool hasDate =
        reportingDateStr != 'Reporting date will be communicated by the hostel.';

    final String subtitle = hasDate
        ? 'Dear $studentName, remember to report not later than '
            '$reportingDateStr. Otherwise your room may be allocated to '
            'another student.\n\nNote: Booking fee is non-refundable.'
        : 'Dear $studentName, $reportingDateStr\n\n'
            'Note: Booking fee is non-refundable.';

    await send(
      userId: studentId,
      title: 'Reporting Reminder',
      subtitle: subtitle,
      type: 'general',
    );
  }

  /// Notify hostel personnel that a room has been reserved by a student.
  /// Triggered automatically when a student successfully pays.
  ///
  /// The notification is written to:
  ///   users/{personnelId}/notifications/{docId}
  ///
  /// Schema stored:
  ///   title      : 'New Room Reservation'
  ///   subtitle   : full message with room number, student name,
  ///                booking ID and date
  ///   type       : 'reservation'
  ///   bookingId  : for fast lookup from the notification card
  ///   createdAt  : server timestamp
  ///   isRead     : false
  static Future<void> newReservationForPersonnel({
    required String personnelId,
    required String roomNumber,
    required String studentName,
    required String bookingId,
    required DateTime bookingDate,
  }) {
    final day   = bookingDate.day.toString().padLeft(2, '0');
    final month = bookingDate.month.toString().padLeft(2, '0');
    final year  = bookingDate.year.toString();
    final dateStr = '$day/$month/$year';

    return FirebaseFirestore.instance
        .collection('users')
        .doc(personnelId)
        .collection('notifications')
        .add({
      'title': 'New Room Reservation',
      'subtitle':
          'Room $roomNumber has been reserved by $studentName.\n'
          'Booking ID: $bookingId\n'
          'Date: $dateStr',
      'type': 'reservation',
      'bookingId': bookingId,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }
}
