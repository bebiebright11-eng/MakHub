import 'package:cloud_firestore/cloud_firestore.dart';

/// Ranks competing booking requests for the same room by priority score.
///
/// Scoring:
///   +50  Payment completed (paymentStatus == 'confirmed' or booking == 'payment_received')
///   +30  Student is verified (users/{id}.isVerified == true)
///   +20  Earliest booking date (the oldest booking among competitors scores +20,
///         others score proportionally less based on how much later they booked)
///
/// Returns competitors sorted best-first with their priority score.
class BookingPriorityAlgorithm {
  const BookingPriorityAlgorithm._();

  /// Ranks all pending/payment_received bookings for a given room.
  ///
  /// [hostelId], [floorId], [roomId] — identify the contested room.
  static Future<List<PrioritisedBooking>> rankForRoom({
    required String hostelId,
    required String floorId,
    required String roomId,
  }) async {
    // Get all active bookings for this room
    final bookingsSnap = await FirebaseFirestore.instance
        .collection('bookings')
        .where('hostelId', isEqualTo: hostelId)
        .where('floorId', isEqualTo: floorId)
        .where('roomId', isEqualTo: roomId)
        .where('bookingStatus', whereIn: ['pending', 'payment_received'])
        .get();

    if (bookingsSnap.docs.isEmpty) return [];

    // Sort by bookingDate ascending to compute relative time bonus
    final docs = bookingsSnap.docs.toList()
      ..sort((a, b) {
        final aTime = (a.data()['bookingDate'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final bTime = (b.data()['bookingDate'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return aTime.compareTo(bTime);
      });

    final int totalBookings = docs.length;
    final List<PrioritisedBooking> results = [];

    for (int i = 0; i < docs.length; i++) {
      final doc = docs[i];
      final data = doc.data();
      final String studentId = (data['studentId'] ?? '').toString();
      int score = 0;

      // ── 1. Payment (+50) ───────────────────────────────────────────────
      final bookingStatus = (data['bookingStatus'] ?? '').toString();
      if (bookingStatus == 'payment_received' || bookingStatus == 'confirmed') {
        score += 50;
      } else {
        // Check payments collection
        final paymentSnap = await FirebaseFirestore.instance
            .collection('payments')
            .where('bookingId', isEqualTo: doc.id)
            .where('paymentStatus', isEqualTo: 'confirmed')
            .limit(1)
            .get();
        if (paymentSnap.docs.isNotEmpty) score += 50;
      }

      // ── 2. Verified student (+30) ──────────────────────────────────────
      if (studentId.isNotEmpty) {
        final userSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .get();
        if (userSnap.exists && userSnap.data()?['isVerified'] == true) {
          score += 30;
        }
      }

      // ── 3. Booking date bonus (+0 to +20) ─────────────────────────────
      // Earliest booking = +20, latest = +1 (linear scale among competitors)
      if (totalBookings == 1) {
        score += 20;
      } else {
        final datePts = 20 - ((i / (totalBookings - 1)) * 19).round();
        score += datePts.clamp(1, 20);
      }

      results.add(PrioritisedBooking(
        bookingId: doc.id,
        studentId: studentId,
        score: score,
        bookingDate: (data['bookingDate'] as Timestamp?)?.toDate(),
        bookingStatus: bookingStatus,
      ));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }
}

class PrioritisedBooking {
  final String bookingId;
  final String studentId;
  final int score;
  final DateTime? bookingDate;
  final String bookingStatus;

  const PrioritisedBooking({
    required this.bookingId,
    required this.studentId,
    required this.score,
    required this.bookingDate,
    required this.bookingStatus,
  });
}
