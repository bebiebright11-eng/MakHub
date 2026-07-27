/// Utility helpers for budget range parsing and classification.
///
/// Used by RecommendationAlgorithm and the guided search flow to
/// normalise raw user input into comparable numeric ranges.
class BudgetAlgorithm {
  const BudgetAlgorithm._();

  // ── Price parsing ─────────────────────────────────────────────────────────

  /// Extracts an integer price from any raw Firestore value.
  /// Strips non-numeric characters, handles "300,000" or "300k".
  static int parsePrice(dynamic raw) {
    if (raw == null) return 0;
    String s = raw.toString().toLowerCase().trim();

    // Handle "300k" shorthand
    if (s.endsWith('k')) {
      final base = int.tryParse(s.substring(0, s.length - 1));
      if (base != null) return base * 1000;
    }

    return int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  // ── Range classification ──────────────────────────────────────────────────

  /// Returns a human-readable label for the budget tier.
  ///
  ///   ≤ 300 000   → "Budget"
  ///   ≤ 500 000   → "Mid-range"
  ///   > 500 000   → "Premium"
  static String classify(int priceUgx) {
    if (priceUgx <= 300000) return 'Budget';
    if (priceUgx <= 500000) return 'Mid-range';
    return 'Premium';
  }

  // ── Affordability check ───────────────────────────────────────────────────

  /// Returns true if [price] falls within the student's budget range.
  /// If only [maxBudget] is provided, checks price ≤ maxBudget.
  /// If only [minBudget] is provided, checks price ≥ minBudget.
  static bool isAffordable({
    required int price,
    int? minBudget,
    int? maxBudget,
  }) {
    if (minBudget != null && price < minBudget) return false;
    if (maxBudget != null && price > maxBudget) return false;
    return true;
  }

  // ── Score contribution ────────────────────────────────────────────────────

  /// Returns a score (0–25) representing how well [price] fits the budget.
  /// Used internally by RecommendationAlgorithm.
  static int budgetScore({
    required int price,
    int? minBudget,
    int? maxBudget,
  }) {
    if (!isAffordable(price: price, minBudget: minBudget, maxBudget: maxBudget)) {
      return 0;
    }

    // Full score if price is in the lower half of the budget range
    if (maxBudget != null && minBudget != null && maxBudget > minBudget) {
      final double mid = (minBudget + maxBudget) / 2;
      return price <= mid ? 25 : 15;
    }

    return 25;
  }
}
