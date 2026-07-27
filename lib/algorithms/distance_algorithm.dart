/// Utilities for parsing and scoring distance values stored on hostel docs.
///
/// Hostel documents store distance as a string like "0.8 km", "800 m", "1.2km".
/// This class normalises those strings to kilometres for consistent comparisons.
class DistanceAlgorithm {
  const DistanceAlgorithm._();

  // ── Parsing ───────────────────────────────────────────────────────────────

  /// Parses a distance string into kilometres.
  /// Returns null if the string cannot be parsed.
  ///
  /// Supported formats:
  ///   "0.8 km", "0.8km", "800 m", "800m", "800", "0.8"
  static double? parseKm(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final s = raw.toLowerCase().trim();

    // Metres: "800 m" or "800m"
    final mMatch = RegExp(r'([\d.]+)\s*m(?:$|\s|eters?)').firstMatch(s);
    if (mMatch != null) {
      final v = double.tryParse(mMatch.group(1)!);
      if (v != null) return v / 1000;
    }

    // Kilometres: "0.8 km" or "0.8km"
    final kmMatch = RegExp(r'([\d.]+)\s*km').firstMatch(s);
    if (kmMatch != null) return double.tryParse(kmMatch.group(1)!);

    // Bare number — assume kilometres
    return double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), ''));
  }

  // ── Scoring ───────────────────────────────────────────────────────────────

  /// Returns a proximity score (0–15) used in SearchRankingAlgorithm.
  ///
  ///   ≤ 0.5 km  → 15
  ///   ≤ 1.0 km  → 10
  ///   ≤ 2.0 km  → 5
  ///   > 2.0 km  → 0
  static int proximityScore(double? distanceKm) {
    if (distanceKm == null) return 0;
    if (distanceKm <= 0.5) return 15;
    if (distanceKm <= 1.0) return 10;
    if (distanceKm <= 2.0) return 5;
    return 0;
  }

  // ── Display ───────────────────────────────────────────────────────────────

  /// Returns a human-readable distance label.
  ///
  ///   0.8 → "800 m away"
  ///   1.2 → "1.2 km away"
  static String format(double? distanceKm) {
    if (distanceKm == null) return 'Distance unknown';
    if (distanceKm < 1.0) {
      final metres = (distanceKm * 1000).round();
      return '$metres m away';
    }
    return '${distanceKm.toStringAsFixed(1)} km away';
  }

  // ── Tier label ────────────────────────────────────────────────────────────

  /// Returns a tier label used on filter chips.
  ///
  ///   ≤ 0.5 km  → "Very close"
  ///   ≤ 1.0 km  → "Walking distance"
  ///   ≤ 2.0 km  → "Nearby"
  ///   > 2.0 km  → "Far"
  static String tier(double? distanceKm) {
    if (distanceKm == null) return 'Unknown';
    if (distanceKm <= 0.5) return 'Very close';
    if (distanceKm <= 1.0) return 'Walking distance';
    if (distanceKm <= 2.0) return 'Nearby';
    return 'Far';
  }
}
