import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'trending_service.dart';

/// A hostel document paired with its computed trending score (0.0–1.0).
class TrendingRecommendation {
  final QueryDocumentSnapshot doc;

  /// Normalised composite score in the range [0.0, 1.0].
  /// 1.0 means the hostel ranked highest across all four recent-activity signals.
  final double score;

  const TrendingRecommendation({required this.doc, required this.score});
}

/// Ranks hostels for the "Trending Now" section using four time-windowed
/// activity signals with the following weights:
///
///   Signal                   Weight
///   ──────────────────────────────────
///   Recent confirmed bookings  40 %
///   Recent reviews             30 %
///   Recent wishlist adds       20 %
///   Recent hostel views        10 %
///
/// ── How normalisation works ───────────────────────────────────────────────
/// Each raw count is min-max normalised independently across the current
/// hostel set so that every signal contributes on a 0–1 scale regardless of
/// its absolute magnitude.
///
///   normalisedValue = (value - min) / (max - min)
///
/// When all hostels share the same value for a signal (max == min) every
/// hostel receives 0.0 for that signal — the signal becomes neutral and does
/// not distort the final ranking.
///
/// ── Final score formula ───────────────────────────────────────────────────
///   score = (bookingNorm  × 0.40)
///         + (reviewNorm   × 0.30)
///         + (wishlistNorm × 0.20)
///         + (viewNorm     × 0.10)
///
/// Hostels are sorted descending by score so the most trending hostel
/// appears first in the list.
class TrendingRecommendationAlgorithm {
  // Weight constants — must sum to 1.0.
  static const double _weightBookings = 0.40;
  static const double _weightReviews  = 0.30;
  static const double _weightWishlist = 0.20;
  static const double _weightViews    = 0.10;

  /// Scores and sorts [hostels] using [trendingData].
  ///
  /// [hostels]      — the already-filtered list of hostel documents.
  /// [trendingData] — map of hostelId → [HostelTrendingData] from
  ///                  [TrendingService.fetchTrendingData].
  ///
  /// Returns a list sorted by score descending (most trending first).
  static List<TrendingRecommendation> rank({
    required List<QueryDocumentSnapshot> hostels,
    required Map<String, HostelTrendingData> trendingData,
  }) {
    if (hostels.isEmpty) return [];

    // ── Step 1: extract raw signal values for every hostel ────────────────
    final List<_RawEntry> raw = hostels.map((doc) {
      // Fall back to all-zero data when a hostel has no trending record.
      final trend = trendingData[doc.id] ?? HostelTrendingData(hostelId: doc.id);

      return _RawEntry(
        doc:      doc,
        bookings: trend.recentBookings.toDouble(),
        reviews:  trend.recentReviews.toDouble(),
        wishlist: trend.recentWishlistAdds.toDouble(),
        views:    trend.recentViews.toDouble(),
      );
    }).toList();

    // ── Step 2: find min and max for each signal across the whole set ─────
    final double minBookings = _min(raw, (e) => e.bookings);
    final double maxBookings = _max(raw, (e) => e.bookings);
    final double minReviews  = _min(raw, (e) => e.reviews);
    final double maxReviews  = _max(raw, (e) => e.reviews);
    final double minWishlist = _min(raw, (e) => e.wishlist);
    final double maxWishlist = _max(raw, (e) => e.wishlist);
    final double minViews    = _min(raw, (e) => e.views);
    final double maxViews    = _max(raw, (e) => e.views);

    // ── Step 3: normalise each signal and compute weighted composite ───────
    final List<TrendingRecommendation> scored = raw.map((e) {
      final double normBookings = _normalise(e.bookings, minBookings, maxBookings);
      final double normReviews  = _normalise(e.reviews,  minReviews,  maxReviews);
      final double normWishlist = _normalise(e.wishlist, minWishlist, maxWishlist);
      final double normViews    = _normalise(e.views,    minViews,    maxViews);

      final double score =
          (normBookings * _weightBookings) +
          (normReviews  * _weightReviews)  +
          (normWishlist * _weightWishlist) +
          (normViews    * _weightViews);

      // ── Debug logging ─────────────────────────────────────────────────
      final data = e.doc.data() as Map<String, dynamic>;
      final name = (data['hostelName'] ?? e.doc.id).toString();
      dev.log(
        '[TrendingNow] $name | '
        'recentBookings=${e.bookings.toStringAsFixed(0)} '
        'recentReviews=${e.reviews.toStringAsFixed(0)} '
        'recentWishlist=${e.wishlist.toStringAsFixed(0)} '
        'recentViews=${e.views.toStringAsFixed(0)} | '
        'normB=${normBookings.toStringAsFixed(3)} '
        'normR=${normReviews.toStringAsFixed(3)} '
        'normW=${normWishlist.toStringAsFixed(3)} '
        'normV=${normViews.toStringAsFixed(3)} | '
        'score=${score.toStringAsFixed(4)}',
        name: 'TrendingNow',
      );

      return TrendingRecommendation(doc: e.doc, score: score);
    }).toList();

    // ── Step 4: sort descending — highest score (most trending) first ─────
    scored.sort((a, b) => b.score.compareTo(a.score));

    // ── Debug: sorted ranking summary ─────────────────────────────────────
    dev.log(
      '[TrendingNow] Final ranking (${scored.length} hostels):',
      name: 'TrendingNow',
    );
    for (int i = 0; i < scored.length; i++) {
      final data = scored[i].doc.data() as Map<String, dynamic>;
      final name = (data['hostelName'] ?? scored[i].doc.id).toString();
      dev.log(
        '  #${i + 1}  $name  score=${scored[i].score.toStringAsFixed(4)}',
        name: 'TrendingNow',
      );
    }

    return scored;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Min-max normalisation. Returns 0.0 when max == min (all equal → neutral).
  static double _normalise(double value, double min, double max) {
    if (max == min) return 0.0;
    return (value - min) / (max - min);
  }

  static double _min(List<_RawEntry> entries, double Function(_RawEntry) fn) =>
      entries.fold(double.infinity, (prev, e) => fn(e) < prev ? fn(e) : prev);

  static double _max(List<_RawEntry> entries, double Function(_RawEntry) fn) =>
      entries.fold(-double.infinity, (prev, e) => fn(e) > prev ? fn(e) : prev);
}

/// Internal data holder — not exposed outside this file.
class _RawEntry {
  final QueryDocumentSnapshot doc;
  final double bookings;
  final double reviews;
  final double wishlist;
  final double views;

  const _RawEntry({
    required this.doc,
    required this.bookings,
    required this.reviews,
    required this.wishlist,
    required this.views,
  });
}
