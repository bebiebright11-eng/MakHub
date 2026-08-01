import 'package:cloud_firestore/cloud_firestore.dart';
import 'distance_algorithm.dart';
import 'location_service.dart';

/// A hostel document paired with its computed location score (0.0–1.0).
class LocationRecommendation {
  final QueryDocumentSnapshot doc;

  /// Normalised composite score in the range [0.0, 1.0].
  /// 1.0 means the hostel ranks highest across all five signals for its
  /// location section.
  final double score;

  const LocationRecommendation({required this.doc, required this.score});
}

/// Ranks hostels within a single location section (Kikumi, Main Gate, or
/// Kikoni) using a proximity-first value model.
///
/// ── Signals and weights ───────────────────────────────────────────────────
///
///   Signal                Weight   Direction
///   ──────────────────────────────────────────────────────────────────────
///   Distance to campus     50 %    INVERTED  — closer hostel → higher score
///   Average rating         20 %    normal    — higher rating → higher score
///   Wishlist count         15 %    normal    — more wishlists → higher score
///   Confirmed bookings     10 %    normal    — more bookings → higher score
///   View count              5 %    normal    — more views → higher score
///
/// ── Distance inversion ───────────────────────────────────────────────────
/// After min-max normalisation, the distance signal is inverted:
///
///   distNorm         = (dist - min) / (max - min)  // 0 = closest, 1 = furthest
///   invertedDistNorm = 1.0 - distNorm              // 1 = closest, 0 = furthest
///
/// Hostels with no parseable distance string receive the neutral score (0.0)
/// for the distance signal — they are neither rewarded nor penalised.
///
/// ── Tiebreaker (built-in via weights) ────────────────────────────────────
/// When two hostels have identical distances, the tiebreaker flows naturally:
///   1. Higher average rating  (+20 %)
///   2. More wishlists         (+15 %)
///   3. More confirmed bookings (+10 %)
///   4. More views              (+5 %)
///
/// ── Normalisation ────────────────────────────────────────────────────────
/// Every signal is min-max normalised independently across the hostels passed
/// in.  When max == min the signal returns 0.0 for every hostel (neutral).
///
/// ── Final formula ─────────────────────────────────────────────────────────
///   score = (invertedDistNorm × 0.50)
///         + (ratingNorm       × 0.20)
///         + (wishlistNorm     × 0.15)
///         + (bookingNorm      × 0.10)
///         + (viewNorm         × 0.05)
///
/// Hostels are sorted descending — closest + highest quality first.
class LocationRecommendationAlgorithm {
  // Weight constants — must sum to 1.0.
  static const double _weightDistance = 0.50;
  static const double _weightRating   = 0.20;
  static const double _weightWishlist = 0.15;
  static const double _weightBookings = 0.10;
  static const double _weightViews    = 0.05;

  /// Scores and sorts [hostels] using [locationData].
  ///
  /// [hostels]      — already filtered to a single location (e.g. all Kikumi
  ///                  hostels).  Do NOT pass the full hostel list.
  /// [locationData] — map of hostelId → [HostelLocationData] from
  ///                  [LocationService].
  ///
  /// Returns a list sorted by score descending (closest + best quality first).
  static List<LocationRecommendation> rank({
    required List<QueryDocumentSnapshot> hostels,
    required Map<String, HostelLocationData> locationData,
  }) {
    if (hostels.isEmpty) return [];

    // ── Step 1: extract raw metric values ─────────────────────────────────
    final List<_RawEntry> raw = hostels.map((doc) {
      final data     = doc.data() as Map<String, dynamic>;
      final locData  = locationData[doc.id] ??
          HostelLocationData(hostelId: doc.id);

      // Parse the distance string stored on the hostel document.
      // Null is kept as null here; handled specially in step 3.
      final double? distKm =
          DistanceAlgorithm.parseKm(data['distance']?.toString());

      return _RawEntry(
        doc:      doc,
        distKm:   distKm,
        rating:   _parseDouble(data['averageRating']),
        wishlist: locData.wishlistCount.toDouble(),
        bookings: locData.confirmedBookings.toDouble(),
        views:    locData.viewCount.toDouble(),
      );
    }).toList();

    // ── Step 2: find min/max for distance using only parseable values ──────
    // Hostels with null distance are excluded from the range calculation so
    // they don't distort the normalisation of hostels that do have distances.
    final parseableDistances =
        raw.where((e) => e.distKm != null).map((e) => e.distKm!).toList();

    final double? minDist =
        parseableDistances.isEmpty ? null : parseableDistances.reduce(_dMin);
    final double? maxDist =
        parseableDistances.isEmpty ? null : parseableDistances.reduce(_dMax);

    // Find min/max for the remaining signals across all hostels.
    final double minRating   = _min(raw, (e) => e.rating);
    final double maxRating   = _max(raw, (e) => e.rating);
    final double minWishlist = _min(raw, (e) => e.wishlist);
    final double maxWishlist = _max(raw, (e) => e.wishlist);
    final double minBookings = _min(raw, (e) => e.bookings);
    final double maxBookings = _max(raw, (e) => e.bookings);
    final double minViews    = _min(raw, (e) => e.views);
    final double maxViews    = _max(raw, (e) => e.views);

    // ── Step 3: normalise, invert distance, apply weights ─────────────────
    final List<LocationRecommendation> scored = raw.map((e) {
      // Distance: normalise then invert.
      // Hostels with no distance get 0.0 (neutral — no bonus, no penalty).
      double invertedDistNorm = 0.0;
      if (e.distKm != null && minDist != null && maxDist != null) {
        final double distNorm = _normalise(e.distKm!, minDist, maxDist);
        invertedDistNorm = 1.0 - distNorm;
      }

      final double ratingNorm   = _normalise(e.rating,   minRating,   maxRating);
      final double wishlistNorm = _normalise(e.wishlist, minWishlist, maxWishlist);
      final double bookingNorm  = _normalise(e.bookings, minBookings, maxBookings);
      final double viewNorm     = _normalise(e.views,    minViews,    maxViews);

      final double score =
          (invertedDistNorm * _weightDistance) +
          (ratingNorm       * _weightRating)   +
          (wishlistNorm     * _weightWishlist) +
          (bookingNorm      * _weightBookings) +
          (viewNorm         * _weightViews);

      return LocationRecommendation(doc: e.doc, score: score);
    }).toList();

    // ── Step 4: sort descending — closest + best quality first ───────────
    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Min-max normalisation. Returns 0.0 when max == min (neutral).
  static double _normalise(double value, double min, double max) {
    if (max == min) return 0.0;
    return (value - min) / (max - min);
  }

  /// Parses any numeric-ish Firestore value to a non-negative double.
  static double _parseDouble(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble().clamp(0.0, double.infinity);
    final parsed = double.tryParse(
      raw.toString().replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    return (parsed ?? 0.0).clamp(0.0, double.infinity);
  }

  static double _min(List<_RawEntry> entries, double Function(_RawEntry) fn) =>
      entries.fold(double.infinity,  (p, e) => fn(e) < p ? fn(e) : p);

  static double _max(List<_RawEntry> entries, double Function(_RawEntry) fn) =>
      entries.fold(-double.infinity, (p, e) => fn(e) > p ? fn(e) : p);

  static double _dMin(double a, double b) => a < b ? a : b;
  static double _dMax(double a, double b) => a > b ? a : b;
}

/// Internal data holder — not exposed outside this file.
class _RawEntry {
  final QueryDocumentSnapshot doc;
  final double? distKm;   // null when no parseable distance on the hostel doc
  final double rating;
  final double wishlist;
  final double bookings;
  final double views;

  const _RawEntry({
    required this.doc,
    required this.distKm,
    required this.rating,
    required this.wishlist,
    required this.bookings,
    required this.views,
  });
}
