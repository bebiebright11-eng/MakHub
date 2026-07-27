import 'package:cloud_firestore/cloud_firestore.dart';

/// Holds a room document alongside its match score and a human-readable
/// reason shown to the student (e.g. "Self-contained · Near balcony").
class RoomRecommendation {
  final QueryDocumentSnapshot doc;

  /// Match percentage shown in the UI (0–100).
  final int matchPercent;

  /// Short comma-separated list of the winning features, e.g.
  /// "Self-contained · Near balcony · Window view"
  final String reasonLabel;

  const RoomRecommendation({
    required this.doc,
    required this.matchPercent,
    required this.reasonLabel,
  });
}

/// Scores rooms inside a single hostel and returns them ranked best-first.
///
/// Scoring breakdown (max 100 base points):
///   +30  Room is Available (not Occupied / Reserved)
///   +20  Room type matches student preference (Single / Double)
///   +15  Self-contained (private bathroom)
///   +12  Near balcony
///   +10  Has window view
///   +8   Near bathroom (when not self-contained)
///   +5   Lower occupancy ratio  (more free beds = higher bonus, max 5)
///
/// The top scorer is normalised to 100 % so relative rankings stay intuitive.
class RoomRecommendationAlgorithm {
  static List<RoomRecommendation> rankRooms({
    required List<QueryDocumentSnapshot> rooms,

    /// 'Single' or 'Double' — from the student's preference or the hostel.
    String preferredRoomType = 'Single',
  }) {
    if (rooms.isEmpty) return [];

    final List<_ScoredRoom> scored = [];

    for (final room in rooms) {
      final data = room.data() as Map<String, dynamic>;
      int score = 0;
      final List<String> reasons = [];

      // ── 1. Availability (+30) ─────────────────────────────────────────────
      final status = (data['status'] ?? '').toString();
      if (status == 'Available') {
        score += 30;
        reasons.add('Available');
      }

      // ── 2. Room type match (+20) ──────────────────────────────────────────
      final roomType = (data['roomType'] ?? '').toString();
      if (roomType.toLowerCase() == preferredRoomType.toLowerCase()) {
        score += 20;
        reasons.add('$roomType room');
      }

      // ── 3. Feature-based scoring ──────────────────────────────────────────
      // Features are stored as a Map<String, dynamic> on the room doc, e.g.:
      //   { 'Self-contained': true, 'Near Balcony': true, 'Window View': true,
      //     'Bathroom Distance': '5m' }
      Map<String, dynamic> features = {};
      if (data['features'] is Map) {
        features = Map<String, dynamic>.from(data['features'] as Map);
      }

      final bool selfContained = features['Self-contained'] == true;
      final bool nearBalcony = features['Near Balcony'] == true;
      final bool windowView = features['Window View'] == true;
      final bool nearBathroom = features['Near Bathroom'] == true;

      if (selfContained) {
        score += 15;
        reasons.add('Self-contained');
      }
      if (nearBalcony) {
        score += 12;
        reasons.add('Near balcony');
      }
      if (windowView) {
        score += 10;
        reasons.add('Window view');
      }
      // Near bathroom only adds value when NOT self-contained
      if (!selfContained && nearBathroom) {
        score += 8;
        reasons.add('Near bathroom');
      }

      // ── 4. Occupancy ratio bonus (+0–5) ───────────────────────────────────
      final int capacity = _parseInt(data['capacity']) ?? 1;
      final int occupied = _parseInt(data['occupied']) ?? 0;
      final int freeBeds = (capacity - occupied).clamp(0, capacity);
      // Linear: 1 free bed → +1, full capacity free → +5
      final int occupancyBonus =
          capacity > 0 ? ((freeBeds / capacity) * 5).round() : 0;
      score += occupancyBonus;

      scored.add(_ScoredRoom(
        doc: room,
        score: score,
        reasons: reasons,
      ));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    // Normalise against top score
    final int topScore =
        scored.isEmpty ? 1 : (scored.first.score > 0 ? scored.first.score : 1);

    return scored.map((s) {
      final pct = ((s.score / topScore) * 100).round().clamp(0, 100);
      final label = s.reasons.isEmpty ? 'Standard room' : s.reasons.join(' · ');
      return RoomRecommendation(
        doc: s.doc,
        matchPercent: pct,
        reasonLabel: label,
      );
    }).toList();
  }

  static int? _parseInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }
}

class _ScoredRoom {
  final QueryDocumentSnapshot doc;
  final int score;
  final List<String> reasons;
  const _ScoredRoom(
      {required this.doc, required this.score, required this.reasons});
}
