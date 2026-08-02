import 'package:cloud_firestore/cloud_firestore.dart';

/// Generates and persists a human-readable Booking ID for a confirmed booking.
///
/// Format:  HOSTELCODE-YYMMDD-XXX
/// Example: DW-260802-001
///
/// Rules:
///   • The sequence resets every day.
///   • The sequence is per-hostel — two hostels may both have -001 on the same day.
///   • Concurrency is handled by a Firestore transaction on a daily counter doc
///     stored at:  hostels/{hostelId}/bookingCounters/{YYMMDD}
///   • The generated ID is written into the booking document as the field
///     `bookingId`.  The Firestore document ID is never modified.
///   • If the booking document already has a `bookingId` field the method
///     returns that existing value without touching Firestore again, making it
///     safe to call more than once.
class BookingIdService {
  const BookingIdService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Assigns a human-readable Booking ID to [bookingDocId] and returns it.
  ///
  /// [bookingDocId] — Firestore document ID of the booking.
  /// [hostelId]     — Firestore document ID of the hostel.
  ///
  /// The method is idempotent: if `bookingId` is already set on the booking
  /// document it is returned immediately without any writes.
  static Future<String> assignBookingId({
    required String bookingDocId,
    required String hostelId,
  }) async {
    final bookingRef = _db.collection('bookings').doc(bookingDocId);

    // ── 1. Idempotency guard — return early if already assigned ───────────
    final existingSnap = await bookingRef.get();
    if (existingSnap.exists) {
      final existing = (existingSnap.data()?['bookingId'] ?? '').toString();
      if (existing.isNotEmpty) return existing;
    }

    // ── 2. Read the hostel code ────────────────────────────────────────────
    final hostelSnap = await _db.collection('hostels').doc(hostelId).get();
    final hostelCode =
        (hostelSnap.data()?['hostelCode'] ?? '').toString().toUpperCase();

    // Fall back to a sanitised prefix of the hostelId when the code is missing
    // so the feature degrades gracefully for hostels not yet given a code.
    final prefix = hostelCode.isNotEmpty
        ? hostelCode
        : hostelId.substring(0, hostelId.length.clamp(0, 3)).toUpperCase();

    // ── 3. Determine the date string ──────────────────────────────────────
    final now = DateTime.now();
    final dateKey = _yymmdd(now); // e.g. "260802"

    // ── 4. Atomically increment the daily counter and write the field ─────
    final counterRef = _db
        .collection('hostels')
        .doc(hostelId)
        .collection('bookingCounters')
        .doc(dateKey);

    late String humanId;

    await _db.runTransaction((tx) async {
      final counterSnap = await tx.get(counterRef);

      final int prev =
          counterSnap.exists ? (counterSnap.data()?['count'] ?? 0) as int : 0;
      final int next = prev + 1;

      // Format sequence as zero-padded 3-digit number.
      // Allows up to 999 bookings per hostel per day before overflowing.
      final seq = next.toString().padLeft(3, '0');
      humanId = '$prefix-$dateKey-$seq';

      // Write / update counter
      tx.set(counterRef, {'count': next, 'date': dateKey});

      // Write the human-readable ID to the booking document
      tx.update(bookingRef, {'bookingId': humanId});
    });

    return humanId;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Formats a [DateTime] as YYMMDD (e.g. 2026-08-02 → "260802").
  static String _yymmdd(DateTime dt) {
    final yy = dt.year.toString().substring(2); // last 2 digits
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '$yy$mm$dd';
  }
}
