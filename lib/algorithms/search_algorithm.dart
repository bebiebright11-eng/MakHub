import 'package:cloud_firestore/cloud_firestore.dart';

class SearchAlgorithm {
  static List<QueryDocumentSnapshot> searchHostels({
    required List<QueryDocumentSnapshot> hostels,
    required String query,
  }) {
    if (query.trim().isEmpty) {
      return hostels;
    }

    final search = query.toLowerCase().trim();

    List<Map<String, dynamic>> scoredHostels = [];

    for (var hostel in hostels) {
      final data = hostel.data() as Map<String, dynamic>;

      final hostelName =
          (data['hostelName'] ?? '').toString().toLowerCase();

      final location =
          (data['location'] ?? '').toString().toLowerCase();

      final description =
          (data['description'] ?? '').toString().toLowerCase();

      final facilities =
          List<String>.from(data['facilities'] ?? []);

      int score = 0;

      // Highest priority
      if (hostelName.startsWith(search)) {
        score += 50;
      }

      if (hostelName.contains(search)) {
        score += 30;
      }

      if (location.contains(search)) {
        score += 20;
      }

      if (description.contains(search)) {
        score += 10;
      }

      for (final facility in facilities) {
        if (facility.toLowerCase().contains(search)) {
          score += 15;
        }
      }

      if (score > 0) {
        scoredHostels.add({
          "doc": hostel,
          "score": score,
        });
      }
    }

    scoredHostels.sort(
      (a, b) => b["score"].compareTo(a["score"]),
    );

    return scoredHostels
        .map((e) => e["doc"] as QueryDocumentSnapshot)
        .toList();
  }
}