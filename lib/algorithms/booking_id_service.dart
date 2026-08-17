import 'package:cloud_firestore/cloud_firestore.dart';

/// Generates and persists a human-readable Booking ID for a confirmed booking.
///
/// Format:  `HostelInitials-YYYYMMDD-XXX`
/// Example: `BR-20260803-001`
///
/// Rules:
///   • Hostel initials are derived from the hostel name (first letter of each
///     word, up to 4 letters).  A `hostelCode` field on the hostel document
///     overrides this when present.
///   • The sequence resets every day.
///   • The sequence is per-hostel — two hostels may both have -001 on the same day.
///   • Concurrency is handled by a Firestore transaction on a daily counter doc
///     stored at:  hostels/{hostelId}/bookingCounters/{YYYYMMDD}
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

    // ── 2. Derive the hostel prefix ───────────────────────────────────────
    final hostelSnap = await _db.collection('hostels').doc(hostelId).get();
    final hostelData = hostelSnap.data() ?? {};

    // Prefer an explicit hostelCode field when one is set.
    final explicitCode =
        (hostelData['hostelCode'] ?? '').toString().trim().toUpperCase();

    final prefix = explicitCode.isNotEmpty
        ? explicitCode
        : _initialsFromName(
            (hostelData['hostelName'] ?? '').toString(),
            fallback: hostelId.substring(0, hostelId.length.clamp(0, 3)),
          );

    // ── 3. Determine the date string (YYYYMMDD) ───────────────────────────
    final now = DateTime.now();
    final dateKey = _yyyymmdd(now); // e.g. "20260803"

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

      // Zero-padded 3-digit sequence — allows up to 999 bookings per hostel
      // per day before overflowing.
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

  /// Formats a [DateTime] as YYYYMMDD (e.g. 2026-08-03 → "20260803").
  static String _yyyymmdd(DateTime dt) {
    final yyyy = dt.year.toString().padLeft(4, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '$yyyy$mm$dd';
  }

  /// Derives uppercase initials from a hostel name.
  ///
  /// Examples:
  ///   "Bright Road Hostel"  → "BRH"
  ///   "Makerere Annex"      → "MA"
  ///   "Hostel One"          → "HO"
  ///
  /// Returns at most 4 characters.  Falls back to [fallback] (uppercased)
  /// when the name is blank or yields no letters.
  static String _initialsFromName(String name, {required String fallback}) {
    if (name.trim().isEmpty) return fallback.toUpperCase();

    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    final initials = words
        .map((w) => w[0])
        .where((c) => RegExp(r'[A-Za-z]').hasMatch(c))
        .take(4)
        .join()
        .toUpperCase();

    return initials.isNotEmpty ? initials : fallback.toUpperCase();
  }
}
