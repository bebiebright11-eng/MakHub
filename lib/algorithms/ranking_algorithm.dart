import 'package:cloud_firestore/cloud_firestore.dart';

/// A hostel document paired with the relevance score that determined its rank.
/// Exposed so the UI can optionally show a "relevance" indicator.
class RankedHostel {
  final QueryDocumentSnapshot doc;

  /// Raw relevance score — higher means more relevant to the query.
  final int score;

  const RankedHostel({required this.doc, required this.score});
}

/// Ranks a list of hostels for a search result page.
///
/// Unlike the recommendation algorithm (which uses the *student's saved
/// preferences*), this ranks whatever set of hostels the text-search step
/// already filtered, sorting them by objective quality signals so the best
/// results appear first.
///
/// Scoring breakdown (higher = better):
///   +30  Has available rooms (availableRooms > 0)
///   +25  Price tier: lower price = higher bonus
///          ≤ 300 000 UGX  → +25
///          ≤ 500 000 UGX  → +15
///          > 500 000 UGX  → +5
///   +20  Security rating bonus  (securityRating × 4, max 20)
///   +15  Distance tier  (closer = better)
///          ≤ 0.5 km  → +15
///          ≤ 1.0 km  → +10
///          ≤ 2.0 km  → +5
///   +10  Facility richness  (1 pt per facility, capped at 10)
///
/// Text-match score (from SearchAlgorithm) is passed through as a tie-breaker:
/// when two hostels have the same rank score the one with the higher text-match
/// score appears first.
class SearchRankingAlgorithm {
  static List<RankedHostel> rank({
    required List<QueryDocumentSnapshot> hostels,

    /// Optional text-match scores keyed by document ID (from SearchAlgorithm).
    /// When supplied they act as a tie-breaker.
    Map<String, int> textScores = const {},

    /// Optional price cap: hostels above this are penalised (-10 pts).
    int? maxBudget,
  }) {
    if (hostels.isEmpty) return [];

    final List<_Entry> entries = [];

    for (final hostel in hostels) {
      final data = hostel.data() as Map<String, dynamic>;
      int score = 0;

      // ── 1. Availability (+30) ─────────────────────────────────────────────
      final int availableRooms = _parseInt(data['availableRooms']) ?? 0;
      if (availableRooms > 0) score += 30;

      // ── 2. Price tier (+5 to +25) ─────────────────────────────────────────
      // Use single-room price as the baseline comparison price.
      final int singlePrice = _parsePrice(data['singlePrice']);
      if (singlePrice > 0) {
        if (singlePrice <= 300000) {
          score += 25;
        } else if (singlePrice <= 500000) {
          score += 15;
        } else {
          score += 5;
        }
      }
      // Optional budget penalty
      if (maxBudget != null && singlePrice > maxBudget) score -= 10;

      // ── 3. Security rating (+0 to +20) ────────────────────────────────────
      // securityRating stored as a number 1–5.
      final int securityRating = _parseInt(data['securityRating']) ?? 0;
      score += (securityRating * 4).clamp(0, 20);

      // ── 4. Distance tier (+0 to +15) ─────────────────────────────────────
      // distance stored as a string like "0.8 km" or "1.2km".
      final double? distanceKm = _parseDistanceKm(data['distance']);
      if (distanceKm != null) {
        if (distanceKm <= 0.5) {
          score += 15;
        } else if (distanceKm <= 1.0) {
          score += 10;
        } else if (distanceKm <= 2.0) {
          score += 5;
        }
      }

      // ── 5. Facility richness (+1 per facility, max +10) ───────────────────
      final List facilities = data['facilities'] ?? [];
      score += facilities.length.clamp(0, 10);

      entries.add(_Entry(
        doc: hostel,
        rankScore: score,
        textScore: textScores[hostel.id] ?? 0,
      ));
    }

    // Sort: primary = rankScore desc, secondary = textScore desc
    entries.sort((a, b) {
      final cmp = b.rankScore.compareTo(a.rankScore);
      return cmp != 0 ? cmp : b.textScore.compareTo(a.textScore);
    });

    return entries
        .map((e) => RankedHostel(doc: e.doc, score: e.rankScore))
        .toList();
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

  /// Parses strings like "0.8 km", "1.2km", "800 m", "800m" into kilometres.
  static double? _parseDistanceKm(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().toLowerCase().trim();

    // Try metres first: "800 m" or "800m"
    final metresMatch = RegExp(r'([\d.]+)\s*m(?:$|\s)').firstMatch(str);
    if (metresMatch != null) {
      final metres = double.tryParse(metresMatch.group(1)!);
      if (metres != null) return metres / 1000;
    }

    // Try kilometres: "0.8 km" or "0.8km"
    final kmMatch = RegExp(r'([\d.]+)\s*km').firstMatch(str);
    if (kmMatch != null) return double.tryParse(kmMatch.group(1)!);

    // Bare number — assume kilometres
    return double.tryParse(str.replaceAll(RegExp(r'[^0-9.]'), ''));
  }
}

class _Entry {
  final QueryDocumentSnapshot doc;
  final int rankScore;
  final int textScore;
  const _Entry(
      {required this.doc, required this.rankScore, required this.textScore});
}
