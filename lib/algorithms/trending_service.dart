import 'package:cloud_firestore/cloud_firestore.dart';

/// Raw trending signals for a single hostel, all scoped to a time window.
///
/// Every count defaults to zero so the scoring algorithm never needs to
/// guard against null — missing or absent Firestore data is treated as zero.
class HostelTrendingData {
  /// Firestore document ID of the hostel.
  final String hostelId;

  /// Confirmed bookings created within the time window.
  final int recentBookings;

  /// Reviews submitted within the time window.
  final int recentReviews;

  /// Wishlist adds within the time window.
  final int recentWishlistAdds;

  /// Hostel views (recentlyViewed upserts) within the time window.
  final int recentViews;

  const HostelTrendingData({
    required this.hostelId,
    this.recentBookings = 0,
    this.recentReviews = 0,
    this.recentWishlistAdds = 0,
    this.recentViews = 0,
  });

  /// Returns true when every signal is zero (no activity in the window).
  bool get isEmpty =>
      recentBookings == 0 &&
      recentReviews == 0 &&
      recentWishlistAdds == 0 &&
      recentViews == 0;
}

/// Fetches time-windowed activity signals for a set of hostels from Firestore.
///
/// Primary window  : last 30 days.
/// Fallback window : last 90 days — used automatically when fewer than
///                   [_minimumActiveHostels] hostels have ANY activity in the
///                   primary window. This keeps the "Trending Now" section
///                   populated on low-traffic deployments.
///
/// Data sources and their Firestore paths / timestamp fields:
///
///   Signal           Collection path                    Timestamp    hostel link
///   ──────────────────────────────────────────────────────────────────────────
///   Bookings         bookings  (top-level)              bookingDate  hostelId
///   Reviews          reviews   (top-level)              createdAt    hostelId
///   Wishlist adds    users/{uid}/wishlist (group)        addedAt      hostelId
///   Views            users/{uid}/recentlyViewed (group)  viewedAt     hostelId
///
/// All four queries run in parallel via [Future.wait] to minimise latency.
/// Firestore [whereIn] is limited to 30 values — large hostel ID lists are
/// automatically chunked.
class TrendingService {
  TrendingService._();

  static final TrendingService instance = TrendingService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Primary trending window in days.
  static const int _primaryWindowDays = 30;

  /// Fallback window used when the primary window yields too little activity.
  static const int _fallbackWindowDays = 90;

  /// Minimum number of hostels that must have at least one activity signal
  /// within the primary window before the fallback is skipped.
  static const int _minimumActiveHostels = 3;

  /// Fetches trending data for [hostelIds].
  ///
  /// 1. Queries Firestore with the 30-day window.
  /// 2. If fewer than [_minimumActiveHostels] hostels have any activity,
  ///    re-queries with the 90-day fallback window transparently.
  /// 3. Returns a map of hostelId → [HostelTrendingData] — every requested
  ///    hostel is present, with all-zero counts when inactive.
  Future<Map<String, HostelTrendingData>> fetchTrendingData(
    List<String> hostelIds,
  ) async {
    if (hostelIds.isEmpty) return {};

    // ── Primary 30-day fetch ──────────────────────────────────────────────
    final primaryCutoff = _cutoffTimestamp(_primaryWindowDays);
    var result = await _fetchForWindow(hostelIds, primaryCutoff);

    // ── Fallback: widen to 90 days if activity is too sparse ─────────────
    final activeCount = result.values.where((d) => !d.isEmpty).length;
    if (activeCount < _minimumActiveHostels) {
      final fallbackCutoff = _cutoffTimestamp(_fallbackWindowDays);
      result = await _fetchForWindow(hostelIds, fallbackCutoff);
    }

    return result;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Runs all four windowed queries in parallel and aggregates results.
  Future<Map<String, HostelTrendingData>> _fetchForWindow(
    List<String> hostelIds,
    Timestamp cutoff,
  ) async {
    // Seed with zeros so every hostel is present in the result.
    final Map<String, int> bookingCounts  = {for (final id in hostelIds) id: 0};
    final Map<String, int> reviewCounts   = {for (final id in hostelIds) id: 0};
    final Map<String, int> wishlistCounts = {for (final id in hostelIds) id: 0};
    final Map<String, int> viewCounts     = {for (final id in hostelIds) id: 0};

    await Future.wait([
      _countBookings(hostelIds, cutoff, bookingCounts),
      _countReviews(hostelIds, cutoff, reviewCounts),
      _countWishlistAdds(hostelIds, cutoff, wishlistCounts),
      _countViews(hostelIds, cutoff, viewCounts),
    ]);

    return {
      for (final id in hostelIds)
        id: HostelTrendingData(
          hostelId:           id,
          recentBookings:     bookingCounts[id]  ?? 0,
          recentReviews:      reviewCounts[id]   ?? 0,
          recentWishlistAdds: wishlistCounts[id] ?? 0,
          recentViews:        viewCounts[id]     ?? 0,
        ),
    };
  }

  /// Returns a Firestore [Timestamp] for midnight [days] ago (UTC).
  Timestamp _cutoffTimestamp(int days) {
    final cutoffDt = DateTime.now().toUtc().subtract(Duration(days: days));
    return Timestamp.fromDate(cutoffDt);
  }

  // ── Per-signal aggregation ────────────────────────────────────────────────

  /// Counts confirmed bookings with `bookingDate >= cutoff`.
  ///
  /// Collection: `bookings` (top-level)
  /// Filter:     bookingStatus == 'confirmed'  AND  bookingDate >= cutoff
  Future<void> _countBookings(
    List<String> hostelIds,
    Timestamp cutoff,
    Map<String, int> out,
  ) async {
    await _batchedWhereIn(
      hostelIds: hostelIds,
      query: (chunk) => _db
          .collection('bookings')
          .where('hostelId', whereIn: chunk)
          .where('bookingStatus', isEqualTo: 'confirmed')
          .where('bookingDate', isGreaterThanOrEqualTo: cutoff),
      hostelIdField: 'hostelId',
      out: out,
    );
  }

  /// Counts reviews with `createdAt >= cutoff`.
  ///
  /// Collection: `reviews` (top-level)
  /// Filter:     createdAt >= cutoff
  Future<void> _countReviews(
    List<String> hostelIds,
    Timestamp cutoff,
    Map<String, int> out,
  ) async {
    await _batchedWhereIn(
      hostelIds: hostelIds,
      query: (chunk) => _db
          .collection('reviews')
          .where('hostelId', whereIn: chunk)
          .where('createdAt', isGreaterThanOrEqualTo: cutoff),
      hostelIdField: 'hostelId',
      out: out,
    );
  }

  /// Counts wishlist adds with `addedAt >= cutoff`.
  ///
  /// Collection group: `wishlist` under users/{uid}/wishlist
  /// Filter:           addedAt >= cutoff
  Future<void> _countWishlistAdds(
    List<String> hostelIds,
    Timestamp cutoff,
    Map<String, int> out,
  ) async {
    await _batchedCollectionGroup(
      hostelIds: hostelIds,
      groupName: 'wishlist',
      timestampField: 'addedAt',
      cutoff: cutoff,
      out: out,
    );
  }

  /// Counts views with `viewedAt >= cutoff`.
  ///
  /// Collection group: `recentlyViewed` under users/{uid}/recentlyViewed
  /// Filter:           viewedAt >= cutoff
  Future<void> _countViews(
    List<String> hostelIds,
    Timestamp cutoff,
    Map<String, int> out,
  ) async {
    await _batchedCollectionGroup(
      hostelIds: hostelIds,
      groupName: 'recentlyViewed',
      timestampField: 'viewedAt',
      cutoff: cutoff,
      out: out,
    );
  }

  // ── Query helpers ─────────────────────────────────────────────────────────

  /// Executes a [whereIn] query in batches of 30 (Firestore limit) and
  /// increments [out] for each matching document.
  Future<void> _batchedWhereIn({
    required List<String> hostelIds,
    required Query Function(List<String> chunk) query,
    required String hostelIdField,
    required Map<String, int> out,
  }) async {
    const int chunkSize = 30;
    for (int i = 0; i < hostelIds.length; i += chunkSize) {
      final chunk = hostelIds.sublist(
        i,
        (i + chunkSize).clamp(0, hostelIds.length),
      );
      try {
        final snap = await query(chunk).get();
        for (final doc in snap.docs) {
          final id = (doc.data() as Map<String, dynamic>)[hostelIdField]
              ?.toString() ?? '';
          if (id.isNotEmpty && out.containsKey(id)) {
            out[id] = (out[id] ?? 0) + 1;
          }
        }
      } catch (_) {
        // Graceful fallback: leave counts at zero for this batch on error.
      }
    }
  }

  /// Executes a collection-group [whereIn] + timestamp filter in batches.
  /// Requires a composite index on `hostelId` + [timestampField] for the
  /// named collection group — Firestore will surface a link to create it
  /// automatically on first run if absent.
  Future<void> _batchedCollectionGroup({
    required List<String> hostelIds,
    required String groupName,
    required String timestampField,
    required Timestamp cutoff,
    required Map<String, int> out,
  }) async {
    const int chunkSize = 30;
    for (int i = 0; i < hostelIds.length; i += chunkSize) {
      final chunk = hostelIds.sublist(
        i,
        (i + chunkSize).clamp(0, hostelIds.length),
      );
      try {
        final snap = await _db
            .collectionGroup(groupName)
            .where('hostelId', whereIn: chunk)
            .where(timestampField, isGreaterThanOrEqualTo: cutoff)
            .get();

        for (final doc in snap.docs) {
          final id = doc.data()['hostelId']?.toString() ?? '';
          if (id.isNotEmpty && out.containsKey(id)) {
            out[id] = (out[id] ?? 0) + 1;
          }
        }
      } catch (_) {
        // Graceful fallback: leave counts at zero if the index is absent.
      }
    }
  }
}
