import 'package:cloud_firestore/cloud_firestore.dart';

/// Raw popularity signals for a single hostel.
///
/// All values default to zero so the scoring algorithm never needs to
/// guard against null — missing Firestore data is treated as zero.
class HostelPopularityData {
  /// Firestore document ID of the hostel.
  final String hostelId;

  /// Number of confirmed bookings for this hostel.
  final int confirmedBookings;

  /// Number of distinct users who have added this hostel to their wishlist.
  final int wishlistCount;

  /// Number of distinct users who have viewed this hostel (recently viewed).
  final int viewCount;

  const HostelPopularityData({
    required this.hostelId,
    this.confirmedBookings = 0,
    this.wishlistCount = 0,
    this.viewCount = 0,
  });
}

/// Fetches popularity signals for a set of hostels from Firestore.
///
/// Data sources:
///   - Confirmed bookings  → top-level `bookings` collection,
///                           filtered by `bookingStatus == 'confirmed'`
///                           and grouped by `hostelId`.
///   - Wishlist count      → scanned across every `users/{uid}/wishlist`
///                           sub-collection document where `hostelId` matches.
///   - View count          → scanned across every `users/{uid}/recentlyViewed`
///                           sub-collection document where `hostelId` matches.
///
/// All three queries run in parallel via [Future.wait] to minimise latency.
/// Results are returned as a map keyed by hostelId for O(1) lookup.
class PopularityService {
  PopularityService._();

  static final PopularityService instance = PopularityService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches and aggregates popularity data for [hostelIds].
  ///
  /// Returns a map of hostelId → [HostelPopularityData].
  /// Hostels that have no activity at all are included with all-zero counts
  /// so the caller never needs to handle a missing key.
  Future<Map<String, HostelPopularityData>> fetchPopularityData(
    List<String> hostelIds,
  ) async {
    if (hostelIds.isEmpty) return {};

    // ── Seed result map with zeros so every hostel is present ────────────
    final Map<String, int> bookingCounts  = { for (final id in hostelIds) id: 0 };
    final Map<String, int> wishlistCounts = { for (final id in hostelIds) id: 0 };
    final Map<String, int> viewCounts     = { for (final id in hostelIds) id: 0 };

    // ── Run all three Firestore reads in parallel ─────────────────────────
    await Future.wait([
      _aggregateBookings(hostelIds, bookingCounts),
      _aggregateWishlists(hostelIds, wishlistCounts),
      _aggregateViews(hostelIds, viewCounts),
    ]);

    // ── Combine into result map ───────────────────────────────────────────
    return {
      for (final id in hostelIds)
        id: HostelPopularityData(
          hostelId: id,
          confirmedBookings: bookingCounts[id] ?? 0,
          wishlistCount:     wishlistCounts[id] ?? 0,
          viewCount:         viewCounts[id] ?? 0,
        ),
    };
  }

  // ── Private aggregation helpers ──────────────────────────────────────────

  /// Counts confirmed bookings per hostel from the top-level `bookings`
  /// collection.  Firestore `whereIn` is limited to 30 values per call, so
  /// we batch the hostel IDs if the list is longer.
  Future<void> _aggregateBookings(
    List<String> hostelIds,
    Map<String, int> out,
  ) async {
    const int chunkSize = 30; // Firestore whereIn limit
    for (int i = 0; i < hostelIds.length; i += chunkSize) {
      final chunk = hostelIds.sublist(
        i,
        (i + chunkSize).clamp(0, hostelIds.length),
      );
      final snap = await _db
          .collection('bookings')
          .where('hostelId', whereIn: chunk)
          .where('bookingStatus', isEqualTo: 'confirmed')
          .get();

      for (final doc in snap.docs) {
        final hostelId = (doc.data()['hostelId'] ?? '').toString();
        if (hostelId.isNotEmpty && out.containsKey(hostelId)) {
          out[hostelId] = (out[hostelId] ?? 0) + 1;
        }
      }
    }
  }

  /// Counts per-hostel wishlist adds by scanning every user's wishlist
  /// sub-collection using a Firestore collection group query.
  ///
  /// This requires a collection-group index on `wishlist` with field
  /// `hostelId`.  If the index is absent Firestore returns an error with a
  /// link to create it automatically.
  Future<void> _aggregateWishlists(
    List<String> hostelIds,
    Map<String, int> out,
  ) async {
    const int chunkSize = 30;
    for (int i = 0; i < hostelIds.length; i += chunkSize) {
      final chunk = hostelIds.sublist(
        i,
        (i + chunkSize).clamp(0, hostelIds.length),
      );
      try {
        final snap = await _db
            .collectionGroup('wishlist')
            .where('hostelId', whereIn: chunk)
            .get();

        for (final doc in snap.docs) {
          final hostelId = (doc.data()['hostelId'] ?? '').toString();
          if (hostelId.isNotEmpty && out.containsKey(hostelId)) {
            out[hostelId] = (out[hostelId] ?? 0) + 1;
          }
        }
      } catch (_) {
        // If the collection-group index does not yet exist, gracefully fall
        // back to zero counts for this signal rather than crashing.
      }
    }
  }

  /// Counts per-hostel views by scanning every user's `recentlyViewed`
  /// sub-collection using a Firestore collection group query.
  ///
  /// Same index requirement as [_aggregateWishlists].
  Future<void> _aggregateViews(
    List<String> hostelIds,
    Map<String, int> out,
  ) async {
    const int chunkSize = 30;
    for (int i = 0; i < hostelIds.length; i += chunkSize) {
      final chunk = hostelIds.sublist(
        i,
        (i + chunkSize).clamp(0, hostelIds.length),
      );
      try {
        final snap = await _db
            .collectionGroup('recentlyViewed')
            .where('hostelId', whereIn: chunk)
            .get();

        for (final doc in snap.docs) {
          final hostelId = (doc.data()['hostelId'] ?? '').toString();
          if (hostelId.isNotEmpty && out.containsKey(hostelId)) {
            out[hostelId] = (out[hostelId] ?? 0) + 1;
          }
        }
      } catch (_) {
        // Graceful fallback: zero view counts if index is absent.
      }
    }
  }
}
