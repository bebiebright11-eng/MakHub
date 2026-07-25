import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendationAlgorithm {
  static List<QueryDocumentSnapshot> recommendHostels({
    required List<QueryDocumentSnapshot> hostels,
    required Map<String, dynamic> preferences,
  }) {
    List<MapEntry<QueryDocumentSnapshot, int>> scoredHostels = [];

    for (var hostel in hostels) {
      final data = hostel.data() as Map<String, dynamic>;
      int score = 0;

      // Hostel type
      if ((data['type'] ?? '') ==
          preferences['preferredType']) {
        score += 30;
      }

      // Room type
      if (preferences['roomType'] == "Single" &&
          (data['singlePrice'] ?? '').toString().isNotEmpty) {
        score += 25;
      }

      if (preferences['roomType'] == "Double" &&
          (data['doublePrice'] ?? '').toString().isNotEmpty) {
        score += 25;
      }

      // Location
      if ((data['location'] ?? '')
          .toString()
          .toLowerCase()
          .contains(
            (preferences['preferredLocation'] ?? '')
                .toString()
                .toLowerCase(),
          )) {
        score += 20;
      }

      // Facilities
      List hostelFacilities =
          data['facilities'] ?? [];

      List preferredFacilities =
          preferences['facilities'] ?? [];

      for (String facility in preferredFacilities) {
        if (hostelFacilities.contains(facility)) {
          score += 5;
        }
      }

      scoredHostels.add(
        MapEntry(hostel, score),
      );
    }

    scoredHostels.sort(
      (a, b) => b.value.compareTo(a.value),
    );

    return scoredHostels
        .map((e) => e.key)
        .toList();
  }
}