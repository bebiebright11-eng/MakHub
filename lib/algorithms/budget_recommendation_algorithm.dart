import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'budget_service.dart';

/// A hostel document paired with its computed budget score (0.0–1.0).
class BudgetRecommendation {
  final QueryDocumentSnapshot doc;

  /// Normalised composite score in the range [0.0, 1.0].
  /// 1.0 means the hostel offers the best combination of low price and
  /// high quality signals across the current set.
  final double score;

  const BudgetRecommendation({required this.doc, required this.score});
}

/// Ranks hostels for the "Budget Friendly" section using a value-for-money
/// scoring model.  The goal is NOT simply the cheapest hostel — it is the
/// hostel that combines an affordable price with positive quality signals.
///
/// ── Signals and weights ───────────────────────────────────────────────────
///
///   Signal                Weight   Direction
///   ──────────────────────────────────────────────────────
///   Price (single room)    50 %    INVERTED  — lower price → higher score
///   Average rating         20 %    normal    — higher rating → higher score
///   Wishlist count         15 %    normal    — more wishlists → higher score
///   Confirmed bookings     10 %    normal    — more bookings → higher score
///   View count              5 %    normal    — more views → higher score
///
/// ── Price inversion ───────────────────────────────────────────────────────
/// After min-max normalisation the price signal is inverted:
///
///   priceNorm        = (price - min) / (max - min)   // 0 = cheapest, 1 = most expensive
///   invertedPriceNorm = 1.0 - priceNorm              // 1 = cheapest, 0 = most expensive
///
/// This ensures the cheapest hostel receives a price contribution of 0.50
/// (its full 50 % weight) while the most expensive receives 0.0.
///
/// ── Tiebreaker logic (built-in via weights) ───────────────────────────────
/// When two hostels have identical prices their invertedPriceNorm values are
/// equal, so the tiebreaker falls naturally to:
///   1. Higher average rating  (+20 %)
///   2. More wishlists         (+15 %)
///   3. More confirmed bookings (+10 %)
///   4. More views              (+5 %)
///
/// ── Normalisation ────────────────────────────────────────────────────────
/// Every signal is min-max normalised independently across the current hostel
/// set.  When max == min for a signal (all hostels identical) that signal
/// returns 0.0 for every hostel — it becomes neutral and does not distort
/// the ranking.
///
/// ── Final formula ─────────────────────────────────────────────────────────
///   score = (invertedPriceNorm × 0.50)
///         + (ratingNorm        × 0.20)
///         + (wishlistNorm      × 0.15)
///         + (bookingNorm       × 0.10)
///         + (viewNorm          × 0.05)
///
/// Hostels are sorted descending — highest score (best value) first.
class BudgetRecommendationAlgorithm {
  // Weight constants — must sum to 1.0.
  static const double _weightPrice    = 0.50;
  static const double _weightRating   = 0.20;
  static const double _weightWishlist = 0.15;
  static const double _weightBookings = 0.10;
  static const double _weightViews    = 0.05;

  /// Scores and sorts [hostels] using [budgetData].
  ///
  /// [hostels]    — the already-filtered list of hostel documents.
  /// [budgetData] — map of hostelId → [HostelBudgetData] from
  ///                [BudgetService].
  ///
  /// Returns a list sorted by score descending (best value first).
  static List<BudgetRecommendation> rank({
    required List<QueryDocumentSnapshot> hostels,
    required Map<String, HostelBudgetData> budgetData,
  }) {
    if (hostels.isEmpty) return [];

    // ── Step 1: extract raw metric values for every hostel ────────────────
    // Use the single-room price as the baseline price signal; fall back to
    // the double-room price when single is absent, then to zero.
    final List<_RawEntry> raw = hostels.map((doc) {
      final data   = doc.data() as Map<String, dynamic>;
      final budget = budgetData[doc.id] ?? HostelBudgetData(hostelId: doc.id);

      final double singlePrice = _parsePrice(data['singlePrice']);
      final double doublePrice = _parsePrice(data['doublePrice']);

      // Prefer single price; use double when single is absent (0).
      final double effectivePrice =
          singlePrice > 0 ? singlePrice : doublePrice;

      return _RawEntry(
        doc:      doc,
        price:    effectivePrice,
        rating:   _parseDouble(data['averageRating']),
        wishlist: budget.wishlistCount.toDouble(),
        bookings: budget.confirmedBookings.toDouble(),
        views:    budget.viewCount.toDouble(),
      );
    }).toList();

    // ── Step 2: find min and max for each signal ──────────────────────────
    final double minPrice    = _min(raw, (e) => e.price);
    final double maxPrice    = _max(raw, (e) => e.price);
    final double minRating   = _min(raw, (e) => e.rating);
    final double maxRating   = _max(raw, (e) => e.rating);
    final double minWishlist = _min(raw, (e) => e.wishlist);
    final double maxWishlist = _max(raw, (e) => e.wishlist);
    final double minBookings = _min(raw, (e) => e.bookings);
    final double maxBookings = _max(raw, (e) => e.bookings);
    final double minViews    = _min(raw, (e) => e.views);
    final double maxViews    = _max(raw, (e) => e.views);

    // ── Step 3: normalise, invert price, apply weights ────────────────────
    final List<BudgetRecommendation> scored = raw.map((e) {
      // Normalise price then invert: 1.0 = cheapest, 0.0 = most expensive.
      final double priceNorm         = _normalise(e.price,    minPrice,    maxPrice);
      final double invertedPriceNorm = 1.0 - priceNorm;

      final double ratingNorm   = _normalise(e.rating,   minRating,   maxRating);
      final double wishlistNorm = _normalise(e.wishlist, minWishlist, maxWishlist);
      final double bookingNorm  = _normalise(e.bookings, minBookings, maxBookings);
      final double viewNorm     = _normalise(e.views,    minViews,    maxViews);

      final double score =
          (invertedPriceNorm * _weightPrice)    +
          (ratingNorm        * _weightRating)   +
          (wishlistNorm      * _weightWishlist) +
          (bookingNorm       * _weightBookings) +
          (viewNorm          * _weightViews);

      // ── Debug logging ─────────────────────────────────────────────────
      final data = e.doc.data() as Map<String, dynamic>;
      final name = (data['hostelName'] ?? e.doc.id).toString();
      dev.log(
        '[BudgetFriendly] $name | '
        'price=${e.price.toStringAsFixed(0)} '
        'rating=${e.rating.toStringAsFixed(2)} '
        'wishlist=${e.wishlist.toStringAsFixed(0)} '
        'bookings=${e.bookings.toStringAsFixed(0)} '
        'views=${e.views.toStringAsFixed(0)} | '
        'invPrice=${invertedPriceNorm.toStringAsFixed(3)} '
        'normR=${ratingNorm.toStringAsFixed(3)} '
        'normW=${wishlistNorm.toStringAsFixed(3)} '
        'normB=${bookingNorm.toStringAsFixed(3)} '
        'normV=${viewNorm.toStringAsFixed(3)} | '
        'score=${score.toStringAsFixed(4)}',
        name: 'BudgetFriendly',
      );

      return BudgetRecommendation(doc: e.doc, score: score);
    }).toList();

    // ── Step 4: sort descending — best value first ────────────────────────
    scored.sort((a, b) => b.score.compareTo(a.score));

    // ── Debug: sorted ranking summary ─────────────────────────────────────
    dev.log(
      '[BudgetFriendly] Final ranking (${scored.length} hostels):',
      name: 'BudgetFriendly',
    );
    for (int i = 0; i < scored.length; i++) {
      final data = scored[i].doc.data() as Map<String, dynamic>;
      final name = (data['hostelName'] ?? scored[i].doc.id).toString();
      dev.log(
        '  #${i + 1}  $name  score=${scored[i].score.toStringAsFixed(4)}',
        name: 'BudgetFriendly',
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

  /// Parses a price field (e.g. "350000", "350,000") to a non-negative double.
  /// Returns 0.0 for null, empty, or unparseable values.
  static double _parsePrice(dynamic raw) {
    if (raw == null) return 0.0;
    final cleaned = raw.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return 0.0;
    return (double.tryParse(cleaned) ?? 0.0).clamp(0.0, double.infinity);
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
  final double price;
  final double rating;
  final double wishlist;
  final double bookings;
  final double views;

  const _RawEntry({
    required this.doc,
    required this.price,
    required this.rating,
    required this.wishlist,
    required this.bookings,
    required this.views,
  });
}
