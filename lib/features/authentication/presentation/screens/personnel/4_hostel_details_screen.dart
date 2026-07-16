import 'package:flutter/material.dart';

class HostelDetailsScreen extends StatelessWidget {
  const HostelDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hostel Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hostel Header
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Elite Residency Hostel', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Color(0xFF2563EB)),
                const SizedBox(width: 4),
                Text('0.5 km from Campus', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(width: 16),
                const Icon(Icons.directions_walk, size: 16, color: Color(0xFF2563EB)),
                const SizedBox(width: 4),
                Text('8 mins walk', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 24),

            // Video Tour Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_circle_fill),
                label: const Text('View Tour Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'A modern hostel providing a comfortable and secure environment for students. Equipped with high-speed internet, 24/7 security, and modern amenities.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: 24),

            const Text('Facilities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _facilityChip('Free Wi-Fi', Icons.wifi),
                _facilityChip('24/7 Power', Icons.power),
                _facilityChip('Water Heater', Icons.water_drop),
                _facilityChip('Study Room', Icons.menu_book),
                _facilityChip('Gym', Icons.fitness_center),
              ],
            ),
            const SizedBox(height: 24),

            const Text('Pricing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _priceRow('Single Room', 'UGX 1,200,000 / Semester'),
            _priceRow('Double Room', 'UGX 850,000 / Semester'),
            const SizedBox(height: 24),

            const Text('Hostel Rules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _ruleItem('No visitors after 10 PM'),
            _ruleItem('Maintain silence in study areas'),
            _ruleItem('No pets allowed'),
            const SizedBox(height: 24),

            const Text('Security & Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.security, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Security Rating: 4.8/5.0', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                const Text('Student Reviews: 4.5 (120 reviews)', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _facilityChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _priceRow(String type, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(type, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(price, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _ruleItem(String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.grey),
          const SizedBox(width: 8),
          Text(rule, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
