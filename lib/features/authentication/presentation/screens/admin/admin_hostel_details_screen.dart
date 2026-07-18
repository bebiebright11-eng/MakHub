import 'package:flutter/material.dart';
import 'admin_manage_floors_screen.dart';

import 'admin_edit_hostel_screen.dart';

class AdminHostelDetailsScreen extends StatelessWidget {
  final String hostelId;
  final Map<String, dynamic> hostelData;

  const AdminHostelDetailsScreen({
    super.key,
    required this.hostelId,
    required this.hostelData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(hostelData['hostelName'] ?? ''),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Photo gallery placeholder
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(
                child: Icon(Icons.photo_library, size: 60, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),

            // Facilities
            const Text(
              "Facilities",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

           Wrap(
  spacing: 10,
  runSpacing: 10,
  children: (hostelData['facilities'] as List<dynamic>? ?? [])
      .map(
        (facility) => _FacilityChip(
          facility.toString(),
          _getFacilityIcon(facility.toString()),
        ),
      )
      .toList(),
),

           const Text(
  "Hostel Information",
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 12),

_infoCard(
  Icons.location_on,
  "Location",
  hostelData['location'] ?? "Not provided",
),

const SizedBox(height: 12),

Row(
  children: [

    Expanded(
      child: _infoCard(
        Icons.home,
        "Type",
        hostelData['type'] ?? "",
      ),
    ),

    const SizedBox(width: 10),

    Expanded(
      child: _infoCard(
        Icons.straighten,
        "Distance",
        hostelData['distance'] ?? "",
      ),
    ),

  ],
),

const SizedBox(height: 10),

Row(
  children: [

    Expanded(
      child: _infoCard(
        Icons.directions_walk,
        "Walk Time",
        hostelData['walkingTime'] ?? "",
      ),
    ),

    const SizedBox(width: 10),

    Expanded(
      child: _infoCard(
        Icons.atm,
        "ATM",
        hostelData['atm'] ?? "",
      ),
    ),

  ],
),

const SizedBox(height: 10),

Row(
  children: [

    Expanded(
      child: _infoCard(
        Icons.store,
        "Shops",
        hostelData['shops'] ?? "",
      ),
    ),

    const SizedBox(width: 10),

    Expanded(
      child: _infoCard(
        Icons.local_hospital,
        "Hospital",
        hostelData['hospital'] ?? "",
      ),
    ),

  ],
),

const SizedBox(height: 10),

_infoCard(
  Icons.description,
  "Description",
  hostelData['description'] ?? "",
),

const SizedBox(height: 24),



            // Prices
            const Text(
              "Prices",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _priceRow(
              "Single Room Price",
              "UGX ${hostelData['singlePrice']}",
            ),
            const SizedBox(height: 8),
            _priceRow(
                "Double Room Price",
                "UGX ${hostelData['doublePrice']}",
              ),
            const SizedBox(height: 24),

            // Student Reviews
            const Text(
              "Student Reviews",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _reviewCard("Ama K.", 5, "Very clean rooms and the security is excellent. The WiFi is stable too."),
            const SizedBox(height: 10),
            _reviewCard("Kwesi M.", 5, "Great location near campus and the common areas are well maintained."),
            const SizedBox(height: 30),

            // Action buttons
            
              // Action buttons

ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminEditHostelScreen(
          hostelId: hostelId,
          hostelData: hostelData,
        ),
      ),
    );
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  icon: const Icon(Icons.edit),
  label: const Text("Edit Hostel"),
),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminManageFloorsScreen(
                            hostelId: hostelId,
                            hostelName: hostelData['hostelName']?.toString() ?? '',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.layers),
                    label: const Text("Manage Floors"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.people),
                    label: const Text("Manage Personnel"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


Widget _infoCard(
  IconData icon,
  String title,
  String value,
) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.blue,
        ),

        const SizedBox(height: 8),

        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}

  Widget _priceRow(String label, String price) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            price,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(String name, int stars, String comment) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: List.generate(
                  stars,
                  (index) => const Icon(Icons.star, size: 16, color: Colors.amber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(comment, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

IconData _getFacilityIcon(String facility) {
  switch (facility) {
    case "WiFi":
      return Icons.wifi;

    case "Kitchen":
      return Icons.kitchen;

    case "DSTV":
      return Icons.tv;

    case "Laundry":
      return Icons.local_laundry_service;

    case "Reading Room":
      return Icons.menu_book;

    case "Swimming Pool":
      return Icons.pool;

    case "Pool Table":
      return Icons.sports_bar;

    case "Shuttle":
      return Icons.directions_bus;

    case "Security":
      return Icons.security;

    default:
      return Icons.check_circle;
  }
}

class _FacilityChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _FacilityChip(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String text;

  const _RuleItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("•  "),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}