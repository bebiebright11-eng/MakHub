import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'popularity_service.dart';

/// A hostel document paired with its computed recommendation score (0.0–1.0).
class PopularityRecommendation {
  final QueryDocumentSnapshot doc;

  /// Normalised composite score in the range [0.0, 1.0].
  /// 1.0 means the hostel ranked highest across all four signals.
  final double score;

  const PopularityRecommendation({required this.doc, required this.score});
}

/// Ranks hostels for the "Recommended For You" section using four
/// popularity signals with the following weights:
///
///   Signal               Weight
///   ─────────────────────────────
///   Average rating         35 %
///   Confirmed bookings     30 %
///   Wishlist count         20 %
///   View count             15 %
///
/// ── How normalisation works ───────────────────────────────────────────────
/// Each raw metric is min-max normalised independently across the current
/// hostel set so that every signal contributes on a 0–1 scale regardless of
/// its absolute magnitude.
///
///   normalisedValue = (value - min) / (max - min)
///
/// When all hostels have the same value for a signal (i.e. max == min) every
/// hostel receives a normalised score of 0.0 for that signal — the signal
/// becomes neutral and does not distort the ranking.
///
/// ── Final score formula ───────────────────────────────────────────────────
///   score = (ratingNorm  × 0.35)
///         + (bookingNorm × 0.30)
///         + (wishlistNorm× 0.20)
///         + (viewNorm    × 0.15)
///
/// Hostels are sorted descending by score so the best match appears first.
class PopularityRecommendationAlgorithm {
  // Weight constants — must sum to 1.0.
  static const double _weightRating   = 0.35;
  static const double _weightBookings = 0.30;
  static const double _weightWishlist = 0.20;
  static const double _weightViews    = 0.15;

  /// Scores and sorts [hostels] using [popularityData].
  ///
  /// [hostels]        — the already-filtered list of hostel documents.
  /// [popularityData] — map of hostelId → [HostelPopularityData] from
  ///                    [PopularityService.fetchPopularityData].
  ///
  /// Returns a list sorted by score descending (highest first).
  static List<PopularityRecommendation> rank({
    required List<QueryDocumentSnapshot> hostels,
    required Map<String, HostelPopularityData> popularityData,
  }) {
    if (hostels.isEmpty) return [];

    // ── Step 1: extract raw metric values ─────────────────────────────────
    final List<_RawEntry> raw = hostels.map((doc) {
      final data     = doc.data() as Map<String, dynamic>;
      final popularity = popularityData[doc.id] ??
          const HostelPopularityData(hostelId: '');

      return _RawEntry(
        doc:      doc,
        rating:   _parseDouble(data['averageRating']),    // Firestore field
        bookings: popularity.confirmedBookings.toDouble(),
        wishlist: popularity.wishlistCount.toDouble(),
        views:    popularity.viewCount.toDouble(),
      );
    }).toList();

    // ── Step 2: find min/max for each signal ──────────────────────────────
    final double minRating   = _min(raw, (e) => e.rating);
    final double maxRating   = _max(raw, (e) => e.rating);
    final double minBookings = _min(raw, (e) => e.bookings);
    final double maxBookings = _max(raw, (e) => e.bookings);
    final double minWishlist = _min(raw, (e) => e.wishlist);
    final double maxWishlist = _max(raw, (e) => e.wishlist);
    final double minViews    = _min(raw, (e) => e.views);
    final double maxViews    = _max(raw, (e) => e.views);

    // ── Step 3: normalise and compute weighted composite score ────────────
    final List<PopularityRecommendation> scored = raw.map((e) {
      final double normRating   = _normalise(e.rating,   minRating,   maxRating);
      final double normBookings = _normalise(e.bookings, minBookings, maxBookings);
      final double normWishlist = _normalise(e.wishlist, minWishlist, maxWishlist);
      final double normViews    = _normalise(e.views,    minViews,    maxViews);

      final double score =
          (normRating   * _weightRating) +
          (normBookings * _weightBookings) +
          (normWishlist * _weightWishlist) +
          (normViews    * _weightViews);

      // ── Debug logging ─────────────────────────────────────────────────
      final data = e.doc.data() as Map<String, dynamic>;
      final name = (data['hostelName'] ?? e.doc.id).toString();
      dev.log(
        '[RecommendedForYou] $name | '
        'rating=${e.rating.toStringAsFixed(2)} '
        'bookings=${e.bookings.toStringAsFixed(0)} '
        'wishlist=${e.wishlist.toStringAsFixed(0)} '
        'views=${e.views.toStringAsFixed(0)} | '
        'normR=${normRating.toStringAsFixed(3)} '
        'normB=${normBookings.toStringAsFixed(3)} '
        'normW=${normWishlist.toStringAsFixed(3)} '
        'normV=${normViews.toStringAsFixed(3)} | '
        'score=${score.toStringAsFixed(4)}',
        name: 'RecommendedForYou',
      );

      return PopularityRecommendation(doc: e.doc, score: score);
    }).toList();

    // ── Step 4: sort descending — highest score first ─────────────────────
    scored.sort((a, b) => b.score.compareTo(a.score));

    // ── Debug: sorted ranking summary ─────────────────────────────────────
    dev.log(
      '[RecommendedForYou] Final ranking (${scored.length} hostels):',
      name: 'RecommendedForYou',
    );
    for (int i = 0; i < scored.length; i++) {
      final data = scored[i].doc.data() as Map<String, dynamic>;
      final name = (data['hostelName'] ?? scored[i].doc.id).toString();
      dev.log(
        '  #${i + 1}  $name  score=${scored[i].score.toStringAsFixed(4)}',
        name: 'RecommendedForYou',
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

  /// Parses any numeric-ish Firestore value to a non-negative double.
  /// Returns 0.0 for null, empty, or unparseable values.
  static double _parseDouble(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble().clamp(0.0, double.infinity);
    final parsed = double.tryParse(
      raw.toString().replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    return (parsed ?? 0.0).clamp(0.0, double.infinity);
  }

  static double _min(List<_RawEntry> entries, double Function(_RawEntry) fn) =>
      entries.fold(double.infinity, (prev, e) => fn(e) < prev ? fn(e) : prev);

  static double _max(List<_RawEntry> entries, double Function(_RawEntry) fn) =>
      entries.fold(-double.infinity, (prev, e) => fn(e) > prev ? fn(e) : prev);
}

/// Internal data holder — not exposed outside this file.
class _RawEntry {
  final QueryDocumentSnapshot doc;
  final double rating;
  final double bookings;
  final double wishlist;
  final double views;

  const _RawEntry({
    required this.doc,
    required this.rating,
    required this.bookings,
    required this.wishlist,
    required this.views,
  });
}
