import 'package:cloud_firestore/cloud_firestore.dart';
import 'distance_algorithm.dart';

/// Holds a hostel document alongside its match percentage (0–100).
class HostelRecommendation {
  final QueryDocumentSnapshot doc;

  /// Match percentage shown to the student, e.g. 95.
  final int matchPercent;

  const HostelRecommendation({required this.doc, required this.matchPercent});
}

/// Scores every hostel against the student's saved preferences and returns
/// a ranked list with a match-percentage attached to each entry.
///
/// Scoring breakdown (max 100 points):
///   +30  Hostel type matches preference (Girls / Boys / Mixed)
///   +25  Budget: room price falls within the student's range
///   +20  Location matches preference
///   +20  Distance from university falls within preferred range  (NEW)
///   +15  Security rating ≥ student's minimum (or ≥ 3 if none set)
///   +10  Room type available (Single / Double price field is set)
///   +2   Each matching facility  (uncapped, can push past 100 → clipped)
///
/// Hard-exclusion: when a distanceRange filter is set and the hostel has a
/// parseable distance value, hostels outside that range are dropped entirely
/// before scoring.
class RecommendationAlgorithm {

  static List<HostelRecommendation> recommendHostels({
    required List<QueryDocumentSnapshot> hostels,
    required Map<String, dynamic> preferences,
  }) {
    // ── Distance filter setup ─────────────────────────────────────────────
    // Map the distanceRange token to a [minKm, maxKm) half-open interval.
    // An empty/absent token means "no filter".
    final String distanceRange =
        (preferences['distanceRange'] ?? '').toString().trim();
    final (double? distMin, double? distMax) = _distanceBounds(distanceRange);
    final bool hasDistanceFilter =
        distanceRange.isNotEmpty && (distMin != null || distMax != null);

    final List<MapEntry<QueryDocumentSnapshot, int>> scored = [];

    for (final hostel in hostels) {
      final data = hostel.data() as Map<String, dynamic>;

      // ── Distance hard-exclusion ──────────────────────────────────────────
      // Only exclude when: filter is set AND the hostel has a parseable
      // distance value. Hostels with no distance stored are kept (benefit of
      // the doubt) but receive zero distance-match bonus points.
      final double? hostelDistKm =
          DistanceAlgorithm.parseKm(data['distance']?.toString());

      if (hasDistanceFilter && hostelDistKm != null) {
        final tooClose = distMin != null && hostelDistKm < distMin;
        final tooFar   = distMax != null && hostelDistKm >= distMax;
        if (tooClose || tooFar) continue; // hard-exclude
      }

      int score = 0;

      // ── 1. Hostel type (+30) ──────────────────────────────────────────────
      final hostelType = (data['type'] ?? '').toString().toLowerCase();
      final preferredType =
          (preferences['preferredType'] ?? '').toString().toLowerCase();
      if (preferredType.isNotEmpty && hostelType == preferredType) {
        score += 30;
      }

      // ── 2. Budget (+25) ───────────────────────────────────────────────────
      final roomType = preferences['roomType']?.toString() ?? 'Single';
      final roomPrice = _parsePrice(
        roomType == 'Double' ? data['doublePrice'] : data['singlePrice'],
      );

      final int? minBudget = _parseInt(preferences['minBudget']);
      final int? maxBudget = _parseInt(preferences['maxBudgetValue']);
      final String budgetBucket = preferences['maxBudget']?.toString() ?? '';

      if (minBudget != null || maxBudget != null) {
        final withinMin = minBudget == null || roomPrice >= minBudget;
        final withinMax = maxBudget == null || roomPrice <= maxBudget;
        if (withinMin && withinMax) score += 25;
      } else if (budgetBucket.isNotEmpty) {
        // Legacy bucket support
        if (budgetBucket == 'below300000' && roomPrice <= 300000) { score += 25; }
        if (budgetBucket == '300000-500000' &&
            roomPrice >= 300000 &&
            roomPrice <= 500000) { score += 25; }
        if (budgetBucket == 'above500000' && roomPrice > 500000) { score += 25; }
      }

      // ── 3. Location (+20) ─────────────────────────────────────────────────
      final preferredLocation =
          (preferences['preferredLocation'] ?? '').toString().toLowerCase();
      final isAnyLocation =
          preferredLocation.isEmpty || preferredLocation.contains('any');
      if (!isAnyLocation) {
        final hostelLocation =
            (data['location'] ?? '').toString().toLowerCase();
        if (hostelLocation.contains(preferredLocation)) score += 20;
      }

      // ── 4. Distance from university (+20) ────────────────────────────────
      // Award full points when the hostel's distance falls within the
      // preferred range.  Partial points for adjacent ranges so the ranking
      // degrades gracefully rather than cliff-dropping.
      if (hasDistanceFilter && hostelDistKm != null) {
        final bool exactMatch =
            (distMin == null || hostelDistKm >= distMin) &&
            (distMax == null || hostelDistKm < distMax);
        if (exactMatch) {
          score += 20;
        } else {
          // One bucket away — give partial credit
          final double? adjMin = distMin != null ? distMin - 1.0 : null;
          final double? adjMax = distMax != null ? distMax + 1.5 : null;
          final bool adjacent =
              (adjMin == null || hostelDistKm >= adjMin) &&
              (adjMax == null || hostelDistKm < adjMax);
          if (adjacent) score += 8;
        }
      } else if (!hasDistanceFilter && hostelDistKm != null) {
        // No filter set — still reward proximity with up to +20 as a tiebreaker
        if (hostelDistKm <= 1.0) {
          score += 20;
        } else if (hostelDistKm <= 2.0) {
          score += 12;
        } else if (hostelDistKm <= 5.0) {
          score += 6;
        }
      }

      // ── 5. Security rating (+15) ──────────────────────────────────────────
      final int minSecurity = _parseInt(preferences['minSecurity']) ?? 3;
      final int hostelSecurity =
          _parseInt(data['securityRating']) ?? 0;
      if (hostelSecurity >= minSecurity) score += 15;

      // ── 6. Room type availability (+10) ───────────────────────────────────
      if (roomType == 'Single' &&
          (data['singlePrice'] ?? '').toString().isNotEmpty) {
        score += 10;
      }
      if (roomType == 'Double' &&
          (data['doublePrice'] ?? '').toString().isNotEmpty) {
        score += 10;
      }

      // ── 7. Facilities (+2 each) ───────────────────────────────────────────
      final List hostelFacilities = data['facilities'] ?? [];
      final List preferredFacilities = preferences['facilities'] ?? [];
      for (final String facility in preferredFacilities) {
        if (hostelFacilities.contains(facility)) score += 2;
      }

      scored.add(MapEntry(hostel, score));
    }

    scored.sort((a, b) => b.value.compareTo(a.value));

    // Convert raw scores to percentage relative to the top scorer so the
    // numbers feel meaningful even when preferences are sparse.
    final int topScore =
        scored.isEmpty ? 1 : (scored.first.value > 0 ? scored.first.value : 1);

    return scored.map((entry) {
      // Clamp to _maxBaseScore so perfect matches can't exceed 100%.
      final rawPct = ((entry.value / topScore) * 100).round();
      final pct = rawPct.clamp(0, 100);
      return HostelRecommendation(doc: entry.key, matchPercent: pct);
    }).toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static int _parsePrice(dynamic raw) =>
      int.tryParse(
        (raw ?? '0').toString().replaceAll(RegExp(r'[^0-9]'), ''),
      ) ??
      0;

  static int? _parseInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw == null) return null;
    return int.tryParse(raw.toString().replaceAll(RegExp(r'[^0-9]'), ''));
  }

  /// Maps a distanceRange token to a half-open [minKm, maxKm) interval.
  /// Returns (null, null) for unknown/empty tokens — meaning "no constraint".
  static (double?, double?) _distanceBounds(String token) {
    switch (token) {
      case 'under_1km':  return (null, 1.0);
      case '1_2km':      return (1.0,  2.0);
      case '2_5km':      return (2.0,  5.0);
      case '5km_plus':   return (5.0,  null);
      default:           return (null, null);
    }
  }
}
