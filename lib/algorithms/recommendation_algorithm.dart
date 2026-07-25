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

      // Hostel Type
      if ((data['type'] ?? '')
          .toString()
          .toLowerCase()==
          ( preferences['preferredType'] ?? '')
          .toString()
          .toLowerCase()) {
        score += 30;
      }

      // Room Type
      if (preferences['roomType'] == "Single" &&
          (data['singlePrice'] ?? '').toString().isNotEmpty) {
        score += 25;
      }

      if (preferences['roomType'] == "Double" &&
          (data['doublePrice'] ?? '').toString().isNotEmpty) {
        score += 25;
      }

      // Get the correct room price based on selected room type
      int roomPrice = preferences['roomType'] == "Double"
          ? int.tryParse(
                  (data['doublePrice'] ?? "0")
                      .toString()
                      .replaceAll(RegExp(r'[^0-9]'), '')) ??
              0
          : int.tryParse(
                  (data['singlePrice'] ?? "0")
                      .toString()
                      .replaceAll(RegExp(r'[^0-9]'), '')) ??
              0;

      // Budget (supports either old fixed buckets OR a real numeric range)
      String budget = preferences['maxBudget'] ?? "";

      int? minBudget = preferences['minBudget'] is int
          ? preferences['minBudget']
          : int.tryParse((preferences['minBudget'] ?? '').toString());

      int? maxBudget = preferences['maxBudgetValue'] is int
          ? preferences['maxBudgetValue']
          : int.tryParse((preferences['maxBudgetValue'] ?? '').toString());

      if (minBudget != null || maxBudget != null) {
        // New numeric range path
        final withinMin = minBudget == null || roomPrice >= minBudget;
        final withinMax = maxBudget == null || roomPrice <= maxBudget;

        if (withinMin && withinMax) {
          score += 25;
        }
      } else {
        // Old fixed-bucket path (kept for backward compatibility)
        if (budget == "below300000" && roomPrice <= 300000) {
          score += 25;
        }

        if (budget == "300000-500000" &&
            roomPrice >= 300000 &&
            roomPrice <= 500000) {
          score += 25;
        }

        if (budget == "above500000" && roomPrice > 500000) {
          score += 25;
        }
      }

      // Preferred Location ("Any" or empty means no location filter/scoring)
      final preferredLocation =
          (preferences['preferredLocation'] ?? '').toString().toLowerCase();

      final isAnyLocation = preferredLocation.isEmpty ||
          preferredLocation.contains('any');

      if (!isAnyLocation &&
          (data['location'] ?? '')
              .toString()
              .toLowerCase()
              .contains(preferredLocation)) {
        score += 20;
      }

      // Preferred Facilities
      List hostelFacilities = data['facilities'] ?? [];
      List preferredFacilities = preferences['facilities'] ?? [];

      for (String facility in preferredFacilities) {
        if (hostelFacilities.contains(facility)) {
          score += 5;
        }
      }

      scoredHostels.add(MapEntry(hostel, score));
    }

    for (var hostel in scoredHostels) {
      final data = hostel.key.data() as Map<String, dynamic>;

      print(
        "${data['hostelName']} -> Score: ${hostel.value}",
      );
    }
      scoredHostels.sort((a, b) => b.value.compareTo(a.value));

    return scoredHostels.map((e) => e.key).toList();
  }
}