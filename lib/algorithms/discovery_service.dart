import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'trending_service.dart';

/// Results from a single [DiscoveryService.fetch] call.
class DiscoveryResult {
  /// Low-exposure hostels (few views, bookings, reviews, wishlist adds).
  /// Randomly shuffled on every call.
  final List<QueryDocumentSnapshot> lowExposure;

  /// Newly added hostels — added within [DiscoveryService.newHostelWindowDays].
  /// Randomly shuffled on every call.
  final List<QueryDocumentSnapshot> newHostels;

  const DiscoveryResult({
    required this.lowExposure,
    required this.newHostels,
  });
}

/// Provides the low-exposure and new-hostel pools used by the two discovery
/// sections on the student home dashboard.
///
/// ── Low-exposure criteria ─────────────────────────────────────────────────
/// A hostel is considered "low exposure" when ALL of the following hold:
///   • recentBookings  ≤ [_maxBookings]
///   • recentReviews   ≤ [_maxReviews]
///   • recentWishlist  ≤ [_maxWishlist]
///   • recentViews     ≤ [_maxViews]
///
/// Thresholds are intentionally generous — we want to surface hostels before
/// they become popular, not only hostels that are completely invisible.
///
/// ── New-hostel criteria ───────────────────────────────────────────────────
/// A hostel is considered "new" when its `createdAt` Firestore field is
/// within the last [newHostelWindowDays] days.
/// Hostels without a `createdAt` field are never included in the new pool
/// but may still appear in the low-exposure pool.
///
/// ── No extra Firestore reads ─────────────────────────────────────────────
/// The service accepts the hostel docs and trending data already fetched by
/// the home screen.  It performs zero additional Firestore reads.
///
/// ── Randomisation ────────────────────────────────────────────────────────
/// Both lists are shuffled with a fresh [Random] on every [fetch] call so
/// the displayed order is different on every dashboard open.
class DiscoveryService {
  DiscoveryService._();
  static final DiscoveryService instance = DiscoveryService._();

  // ── Thresholds ─────────────────────────────────────────────────────────
  static const int _maxBookings = 3;
  static const int _maxReviews  = 2;
  static const int _maxWishlist = 5;
  static const int _maxViews    = 10;

  /// Hostels added within this many days are considered "new".
  static const int newHostelWindowDays = 45;

  // ── Public API ────────────────────────────────────────────────────────

  /// Derives the discovery pools from the hostel docs and trending data
  /// already held in memory by the home screen.
  ///
  /// [allHostels]   — the full (already-filtered) hostel list from the stream.
  /// [trendingData] — the trending map; pass an empty map while still loading.
  DiscoveryResult fetch({
    required List<QueryDocumentSnapshot> allHostels,
    required Map<String, HostelTrendingData> trendingData,
  }) {
    final rng = Random();
    final now = DateTime.now();
    final newCutoff = now.subtract(const Duration(days: newHostelWindowDays));

    final List<QueryDocumentSnapshot> lowExposure = [];
    final List<QueryDocumentSnapshot> newHostels  = [];

    for (final doc in allHostels) {
      final data    = doc.data() as Map<String, dynamic>;
      final trending = trendingData[doc.id] ??
          const HostelTrendingData(hostelId: '');

      // ── Low-exposure check ─────────────────────────────────────────
      final bool isLowExposure =
          trending.recentBookings <= _maxBookings &&
          trending.recentReviews  <= _maxReviews  &&
          trending.recentWishlistAdds <= _maxWishlist &&
          trending.recentViews    <= _maxViews;

      if (isLowExposure) lowExposure.add(doc);

      // ── New-hostel check ───────────────────────────────────────────
      final createdAt = data['createdAt'];
      if (createdAt is Timestamp) {
        final created = createdAt.toDate();
        if (created.isAfter(newCutoff)) {
          newHostels.add(doc);
        }
      }
    }

    // Shuffle independently so each section has a fresh random order.
    lowExposure.shuffle(rng);
    newHostels.shuffle(rng);

    return DiscoveryResult(
      lowExposure: lowExposure,
      newHostels:  newHostels,
    );
  }

  /// Returns up to [count] random discovery hostels from [lowExposure]
  /// suitable for mixing into the "Recommended For You" section.
  ///
  /// Excludes any hostel whose ID is already in [excludeIds] so no hostel
  /// appears twice in the same section.
  List<QueryDocumentSnapshot> pickDiscoveryMix({
    required List<QueryDocumentSnapshot> lowExposure,
    required Set<String> excludeIds,
    int count = 2,
  }) {
    final candidates =
        lowExposure.where((d) => !excludeIds.contains(d.id)).toList();
    candidates.shuffle(Random());
    return candidates.take(count).toList();
  }
}
