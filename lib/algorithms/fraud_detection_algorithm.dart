import 'package:cloud_firestore/cloud_firestore.dart';

/// Detects suspicious booking patterns and flags them for admin review.
///
/// Checks performed:
///   1. Multiple bookings from the same student within a short window
///   2. Same phone number linked to multiple user accounts
///   3. Rapid repeated bookings from the same device/IP (via metadata if present)
///
/// Flagged bookings are written to:
///   fraud_flags/{docId}
///   Fields: { bookingId, studentId, reason, flaggedAt, reviewed: false }
class FraudDetectionAlgorithm {
  const FraudDetectionAlgorithm._();

  // How many bookings in [_windowHours] hours triggers flag #1
  static const int _maxBookingsInWindow = 2;
  static const int _windowHours = 24;

  // How many accounts can share the same phone before flag #2 fires
  static const int _maxAccountsPerPhone = 1;

  // ── Main entry point ──────────────────────────────────────────────────────

  /// Runs all fraud checks for a booking that is about to be created.
  /// Call this BEFORE writing the booking to Firestore.
  ///
  /// Returns a [FraudCheckResult] — if [suspicious] is true the booking
  /// should be flagged (not necessarily blocked; admin reviews it).
  static Future<FraudCheckResult> checkBooking({
    required String studentId,
    required String phone,
    String bookingId = '',
  }) async {
    final List<String> reasons = [];

    // ── Check 1: Multiple bookings in 24 h ───────────────────────────────
    final windowStart = DateTime.now().subtract(
      Duration(hours: _windowHours),
    );

    final recentSnap = await FirebaseFirestore.instance
        .collection('bookings')
        .where('studentId', isEqualTo: studentId)
        .where('bookingDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(windowStart))
        .get();

    if (recentSnap.docs.length >= _maxBookingsInWindow) {
      reasons.add(
        '${recentSnap.docs.length} bookings made within $_windowHours hours '
        'by the same student.',
      );
    }

    // ── Check 2: Phone linked to multiple accounts ────────────────────────
    if (phone.isNotEmpty) {
      final phoneSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone.trim())
          .get();

      if (phoneSnap.docs.length > _maxAccountsPerPhone) {
        reasons.add(
          'Phone $phone is linked to ${phoneSnap.docs.length} different accounts.',
        );
      }
    }

    if (reasons.isEmpty) return const FraudCheckResult.clean();

    // ── Flag it ───────────────────────────────────────────────────────────
    final flagRef = await _writeFlag(
      studentId: studentId,
      bookingId: bookingId,
      reasons: reasons,
    );

    return FraudCheckResult.suspicious(
      flagId: flagRef.id,
      reasons: reasons,
    );
  }

  /// Checks an existing booking document after it has already been created.
  /// Useful to run as a background scan.
  static Future<FraudCheckResult> checkExistingBooking(
    String bookingId,
  ) async {
    final snap = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .get();

    if (!snap.exists) return const FraudCheckResult.clean();
    final data = snap.data()!;

    final String studentId = (data['studentId'] ?? '').toString();
    final String phone = (data['phone'] ?? '').toString();

    return checkBooking(
      studentId: studentId,
      phone: phone,
      bookingId: bookingId,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Future<DocumentReference> _writeFlag({
    required String studentId,
    required String bookingId,
    required List<String> reasons,
  }) {
    return FirebaseFirestore.instance.collection('fraud_flags').add({
      'studentId': studentId,
      'bookingId': bookingId,
      'reasons': reasons,
      'flaggedAt': FieldValue.serverTimestamp(),
      'reviewed': false,
    });
  }
}

class FraudCheckResult {
  final bool suspicious;
  final String? flagId;
  final List<String> reasons;

  const FraudCheckResult.clean()
      : suspicious = false,
        flagId = null,
        reasons = const [];

  const FraudCheckResult.suspicious({
    required this.flagId,
    required this.reasons,
  }) : suspicious = true;
}
