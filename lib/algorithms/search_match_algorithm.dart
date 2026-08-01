import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/search_criteria.dart';
import 'distance_algorithm.dart';

/// Pairs a hostel document with the match percentage calculated against the
/// student's current search criteria.
class SearchMatchResult {
  final QueryDocumentSnapshot doc;

  /// Match percentage 0–100.  Represents how closely this hostel matches
  /// what the student explicitly searched for in this session.
  final int matchPercent;

  const SearchMatchResult({required this.doc, required this.matchPercent});
}

/// Calculates how well each hostel matches the student's CURRENT search.
///
/// ── Design principles ────────────────────────────────────────────────────
///
/// 1. NO DEFAULTS.
///    Every criterion only contributes points when the student explicitly
///    provided it.  A null / empty field contributes exactly 0 — no assumed
///    room type, no minimum-security fallback, no proximity bonus.
///
/// 2. PROPORTIONAL REDISTRIBUTION.
///    The base weights are:
///      Location     30 %
///      Budget       25 %
///      Distance     15 %
///      Room Type    15 %
///      Hostel Type  10 %
///      Facilities    5 %
///                  ──────
///      Total       100 %
///
///    When the student omits one or more criteria those weights are removed
///    from the denominator and the remaining weights are rescaled so the
///    percentages always sum to 100 % across the criteria that were provided.
///    This means a student who only enters Location + Budget cannot be
///    penalised for not entering Distance — they can still receive 100 %.
///
/// 3. SEARCH-ONLY.
///    This algorithm is ONLY used on the Search Results screen and the
///    "Based on your recent search" home section.  It must NEVER be used
///    by Recommended For You, Trending Now, Budget Friendly, or location
///    sections — those have their own dedicated algorithms.
///
/// ── Criterion scoring rules ───────────────────────────────────────────────
///
///  Location   — full points when hostel location contains the preferred
///               location string (case-insensitive partial match both ways).
///
///  Budget     — full points when the relevant room price falls within the
///               student's min–max range.  Partial points for being close:
///               within 10 % over budget → 50 % of budget weight.
///               Uses singlePrice when roomType == "Single" (or unset),
///               doublePrice when roomType == "Double".
///
///  Distance   — full points when hostel distance falls within the chosen
///               bucket.  Partial credit (50 % of weight) when the hostel
///               is one bucket away.
///
///  Room Type  — full points when the relevant price field is non-empty
///               (i.e. that room type is actually offered).
///
///  Hostel Type — full points for exact type match.  Partial points (50 %)
///                when the hostel is Mixed and the student wanted a specific
///                type (Mixed accommodates all genders).
///
///  Facilities — proportional: (matching facilities / requested facilities).
///               Each matched facility earns an equal share of the weight.
///
/// ── Hard exclusions ───────────────────────────────────────────────────────
///
///  None.  Hard exclusions (dropping hostels that don't match at all) are not
///  applied here because the student may still want to *see* hostels that
///  partially match.  The match % will be low for poor matches, which is
///  informative in itself.  GuidedSearchScreen already lets the student pick
///  "Any distance" / skip hostel-type if they want wider results.
///
class SearchMatchAlgorithm {
  // ── Base weights (must sum to 100) ────────────────────────────────────────
  static const int _wLocation    = 30;
  static const int _wBudget      = 25;
  static const int _wDistance    = 15;
  static const int _wRoomType    = 15;
  static const int _wHostelType  = 10;
  static const int _wFacilities  =  5;

  /// Scores every hostel against [criteria] and returns a ranked list.
  ///
  /// If [criteria] has no criteria at all (hasAnyCriteria == false) every
  /// hostel receives 0 % and the list is returned in Firestore order.
  static List<SearchMatchResult> score({
    required List<QueryDocumentSnapshot> hostels,
    required SearchCriteria criteria,
  }) {
    if (!criteria.hasAnyCriteria) {
      return hostels
          .map((h) => SearchMatchResult(doc: h, matchPercent: 0))
          .toList();
    }

    // ── Build the effective denominator ───────────────────────────────────
    // Only include weights for criteria the student actually provided.
    final bool hasLocation   = _isSet(criteria.location) &&
        !criteria.location!.toLowerCase().contains('any');
    final bool hasBudget     = criteria.minBudget != null ||
        criteria.maxBudget != null;
    final bool hasDistance   = _isSet(criteria.distanceRange);
    final bool hasRoomType   = _isSet(criteria.roomType);
    final bool hasHostelType = _isSet(criteria.hostelType);
    final bool hasFacilities = criteria.facilities.isNotEmpty;

    final int totalWeight =
        (hasLocation   ? _wLocation   : 0) +
        (hasBudget     ? _wBudget     : 0) +
        (hasDistance   ? _wDistance   : 0) +
        (hasRoomType   ? _wRoomType   : 0) +
        (hasHostelType ? _wHostelType : 0) +
        (hasFacilities ? _wFacilities : 0);

    // Shouldn't happen (hasAnyCriteria guards above) but defend anyway.
    if (totalWeight == 0) {
      return hostels
          .map((h) => SearchMatchResult(doc: h, matchPercent: 0))
          .toList();
    }

    // ── Distance bucket bounds ─────────────────────────────────────────────
    final (double? distMin, double? distMax) =
        hasDistance ? _distanceBounds(criteria.distanceRange!) : (null, null);

    final List<MapEntry<QueryDocumentSnapshot, double>> scored = [];

    for (final hostel in hostels) {
      final data = hostel.data() as Map<String, dynamic>;
      double earned = 0.0;

      // ── 1. Location ────────────────────────────────────────────────────
      if (hasLocation) {
        final preferred =
            criteria.location!.toLowerCase().trim();
        final hostelLoc =
            (data['location'] ?? '').toString().toLowerCase();
        final match = hostelLoc.contains(preferred) ||
            preferred.contains(hostelLoc);
        if (match) earned += _wLocation.toDouble();
      }

      // ── 2. Budget ──────────────────────────────────────────────────────
      if (hasBudget) {
        // Pick the right price field based on the room type the student
        // selected.  If no room type was specified use single price as the
        // representative price.
        final bool wantsDouble =
            criteria.roomType?.toLowerCase() == 'double';
        final int roomPrice = _parsePrice(
          wantsDouble ? data['doublePrice'] : data['singlePrice'],
        );

        if (roomPrice > 0) {
          final bool aboveMin =
              criteria.minBudget == null || roomPrice >= criteria.minBudget!;
          final bool belowMax =
              criteria.maxBudget == null || roomPrice <= criteria.maxBudget!;

          if (aboveMin && belowMax) {
            // Perfect match — full weight.
            earned += _wBudget.toDouble();
          } else if (aboveMin && criteria.maxBudget != null) {
            // Slightly over budget — partial credit when within 10 % over.
            final double overBy =
                (roomPrice - criteria.maxBudget!) / criteria.maxBudget!;
            if (overBy <= 0.10) earned += _wBudget * 0.5;
          }
        }
      }

      // ── 3. Distance ────────────────────────────────────────────────────
      if (hasDistance) {
        final double? hostelKm =
            DistanceAlgorithm.parseKm(data['distance']?.toString());

        if (hostelKm != null) {
          final bool exactMatch =
              (distMin == null || hostelKm >= distMin) &&
              (distMax == null || hostelKm < distMax);

          if (exactMatch) {
            earned += _wDistance.toDouble();
          } else {
            // One bucket adjacent → 50 % partial credit.
            final double? adjMin = distMin != null ? distMin - 1.0 : null;
            final double? adjMax = distMax != null ? distMax + 1.5 : null;
            final bool adjacent =
                (adjMin == null || hostelKm >= adjMin) &&
                (adjMax == null || hostelKm < adjMax);
            if (adjacent) earned += _wDistance * 0.5;
          }
        }
        // Hostel with no parseable distance — contributes 0 (no assumption).
      }

      // ── 4. Room type ───────────────────────────────────────────────────
      if (hasRoomType) {
        final bool wantsDouble =
            criteria.roomType!.toLowerCase() == 'double';
        final String priceField = wantsDouble
            ? (data['doublePrice'] ?? '').toString()
            : (data['singlePrice'] ?? '').toString();
        // Room type is available when the relevant price field is non-empty.
        if (priceField.isNotEmpty) earned += _wRoomType.toDouble();
      }

      // ── 5. Hostel type ─────────────────────────────────────────────────
      if (hasHostelType) {
        final String preferred = criteria.hostelType!.toLowerCase();
        final String hostelType =
            (data['type'] ?? '').toString().toLowerCase();

        if (hostelType == preferred) {
          earned += _wHostelType.toDouble();
        } else if (hostelType == 'mixed') {
          // Mixed accommodates all genders — partial credit.
          earned += _wHostelType * 0.5;
        }
      }

      // ── 6. Facilities ──────────────────────────────────────────────────
      if (hasFacilities) {
        final List hostelFacilities = data['facilities'] ?? [];
        int matched = 0;
        for (final String f in criteria.facilities) {
          if (hostelFacilities.contains(f)) matched++;
        }
        final double facilityRatio =
            matched / criteria.facilities.length;
        earned += _wFacilities * facilityRatio;
      }

      scored.add(MapEntry(hostel, earned));
    }

    // ── Sort by earned score descending ───────────────────────────────────
    scored.sort((a, b) => b.value.compareTo(a.value));

    // ── Convert to percentage relative to the effective weight total ──────
    return scored.map((entry) {
      final rawPct = (entry.value / totalWeight * 100).round();
      final pct = rawPct.clamp(0, 100);
      return SearchMatchResult(doc: entry.key, matchPercent: pct);
    }).toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static bool _isSet(String? value) =>
      value != null && value.trim().isNotEmpty;

  static int _parsePrice(dynamic raw) =>
      int.tryParse(
        (raw ?? '0').toString().replaceAll(RegExp(r'[^0-9]'), ''),
      ) ??
      0;

  /// Maps a distanceRange token to a half-open [minKm, maxKm) interval.
  static (double?, double?) _distanceBounds(String token) {
    switch (token) {
      case 'under_1km': return (null, 1.0);
      case '1_2km':     return (1.0,  2.0);
      case '2_5km':     return (2.0,  5.0);
      case '5km_plus':  return (5.0,  null);
      default:          return (null, null);
    }
  }
}
