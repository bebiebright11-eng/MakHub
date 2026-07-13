import 'package:flutter/material.dart';
import 'admin_manage_floors_screen.dart';

class AdminHostelDetailsScreen extends StatelessWidget {
  final String hostelName;

  const AdminHostelDetailsScreen({
    super.key,
    required this.hostelName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(hostelName),
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
              children: const [
                _FacilityChip("WiFi", Icons.wifi),
                _FacilityChip("Kitchen", Icons.kitchen),
                _FacilityChip("DSTV", Icons.tv),
                _FacilityChip("Laundry", Icons.local_laundry_service),
                _FacilityChip("Reading Room", Icons.menu_book),
                _FacilityChip("Swimming Pool", Icons.pool),
                _FacilityChip("Pool Table", Icons.sports_bar),
                _FacilityChip("Shuttle", Icons.directions_bus),
                _FacilityChip("Security", Icons.security),
              ],
            ),
            const SizedBox(height: 24),

            // Hostel Rules
            const Text(
              "Hostel Rules",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const _RuleItem("Keep noise levels low after 10:00 PM."),
            const _RuleItem("No unauthorized visitors inside rooms."),
            const _RuleItem("Maintain cleanliness in shared spaces and bathrooms."),
            const _RuleItem("Report damages or facility issues immediately."),
            const SizedBox(height: 24),

            // Prices
            const Text(
              "Prices",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _priceRow("Single Room Price", "GHS 2,500"),
            const SizedBox(height: 8),
            _priceRow("Double Room Price", "GHS 1,800"),
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
            ElevatedButton.icon(
              onPressed: () {},
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
                          builder: (context) => const AdminManageFloorsScreen(),
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