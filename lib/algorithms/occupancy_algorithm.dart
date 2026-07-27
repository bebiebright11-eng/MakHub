import 'package:cloud_firestore/cloud_firestore.dart';

/// Calculates occupancy percentage for a hostel.
///
/// Formula: occupiedRooms / totalRooms × 100
///
/// Rooms are read from:
///   hostels/{hostelId}/floors/{floorId}/rooms/{roomId}
class OccupancyAlgorithm {
  const OccupancyAlgorithm._();

  /// Computes the occupancy for a single hostel.
  /// [hostelId] — the Firestore document ID of the hostel.
  static Future<OccupancyResult> compute(String hostelId) async {
    // Use collectionGroup scoped by path to avoid cross-hostel bleed
    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('rooms')
        .get();

    int total = 0;
    int occupied = 0;
    int available = 0;
    int reserved = 0;

    for (final doc in snapshot.docs) {
      if (!doc.reference.path.contains('hostels/$hostelId/')) continue;
      total++;
      final status = (doc.data()['status'] ?? '').toString();
      if (status == 'Occupied') {
        occupied++;
      } else if (status == 'Available') {
        available++;
      } else if (status == 'Reserved') {
        reserved++;
      }
    }

    final double percentage =
        total == 0 ? 0.0 : double.parse(((occupied / total) * 100).toStringAsFixed(1));

    return OccupancyResult(
      total: total,
      occupied: occupied,
      available: available,
      reserved: reserved,
      percentage: percentage,
    );
  }

  /// Computes occupancy across ALL hostels (platform-wide for admin).
  static Future<OccupancyResult> computeAll() async {
    final snapshot =
        await FirebaseFirestore.instance.collectionGroup('rooms').get();

    int total = 0;
    int occupied = 0;
    int available = 0;
    int reserved = 0;

    for (final doc in snapshot.docs) {
      total++;
      final status = (doc.data()['status'] ?? '').toString();
      if (status == 'Occupied') {
        occupied++;
      } else if (status == 'Available') {
        available++;
      } else if (status == 'Reserved') {
        reserved++;
      }
    }

    final double percentage =
        total == 0 ? 0.0 : double.parse(((occupied / total) * 100).toStringAsFixed(1));

    return OccupancyResult(
      total: total,
      occupied: occupied,
      available: available,
      reserved: reserved,
      percentage: percentage,
    );
  }
}

class OccupancyResult {
  final int total;
  final int occupied;
  final int available;
  final int reserved;

  /// e.g. 80.0 means 80 % occupied.
  final double percentage;

  const OccupancyResult({
    required this.total,
    required this.occupied,
    required this.available,
    required this.reserved,
    required this.percentage,
  });

  /// e.g. "80% occupied (80 / 100 rooms)"
  String get summary => '$percentage% occupied ($occupied / $total rooms)';
}
