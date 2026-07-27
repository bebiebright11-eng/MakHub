/// Estimates how urgently a room will fill up and produces a label
/// ("High demand", "Filling up", "Available") shown on the room card.
///
/// Formula:
///   availabilityScore = remainingBeds / totalCapacity
///
/// Urgency tiers:
///   score ≤ 0.25  → 🔴 High demand   (≤ 25 % beds left)
///   score ≤ 0.50  → 🟡 Filling up    (26–50 % beds left)
///   score > 0.50  → 🟢 Available     (> 50 % beds left)
///   score == 0    → ⛔ Fully booked
class AvailabilityPredictionAlgorithm {
  const AvailabilityPredictionAlgorithm._();

  /// Returns an [AvailabilityPrediction] for a single room's data map.
  ///
  /// [roomData] — the Firestore document map for the room, expected fields:
  ///   - 'capacity'  (int)
  ///   - 'occupied'  (int)
  ///   - 'status'    (String) e.g. 'Available', 'Occupied', 'Reserved'
  static AvailabilityPrediction predict(Map<String, dynamic> roomData) {
    final int capacity = _parseInt(roomData['capacity']) ?? 1;
    final int occupied = _parseInt(roomData['occupied']) ?? 0;
    final String status = (roomData['status'] ?? '').toString();

    // Hard-blocked rooms
    if (status == 'Occupied' || capacity <= 0) {
      return const AvailabilityPrediction(
        score: 0.0,
        urgency: RoomUrgency.fullyBooked,
        label: 'Fully booked',
        sublabel: 'No beds remaining',
      );
    }

    if (status == 'Reserved') {
      return const AvailabilityPrediction(
        score: 0.1,
        urgency: RoomUrgency.highDemand,
        label: 'Reserved',
        sublabel: 'Room is reserved',
      );
    }

    final int remaining = (capacity - occupied).clamp(0, capacity);
    final double score = remaining / capacity;

    if (remaining == 0) {
      return const AvailabilityPrediction(
        score: 0.0,
        urgency: RoomUrgency.fullyBooked,
        label: 'Fully booked',
        sublabel: 'No beds remaining',
      );
    }

    if (score <= 0.25) {
      return AvailabilityPrediction(
        score: score,
        urgency: RoomUrgency.highDemand,
        label: 'High demand',
        sublabel: 'Only $remaining bed${remaining == 1 ? '' : 's'} left',
      );
    }

    if (score <= 0.50) {
      return AvailabilityPrediction(
        score: score,
        urgency: RoomUrgency.fillingUp,
        label: 'Filling up',
        sublabel: '$remaining of $capacity beds left',
      );
    }

    return AvailabilityPrediction(
      score: score,
      urgency: RoomUrgency.available,
      label: 'Available',
      sublabel: '$remaining of $capacity beds available',
    );
  }

  static int? _parseInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }
}

enum RoomUrgency { available, fillingUp, highDemand, fullyBooked }

class AvailabilityPrediction {
  /// 0.0 = full, 1.0 = completely empty.
  final double score;
  final RoomUrgency urgency;

  /// Short label shown on the badge, e.g. "High demand".
  final String label;

  /// Longer sub-label, e.g. "Only 1 bed left".
  final String sublabel;

  const AvailabilityPrediction({
    required this.score,
    required this.urgency,
    required this.label,
    required this.sublabel,
  });
}
