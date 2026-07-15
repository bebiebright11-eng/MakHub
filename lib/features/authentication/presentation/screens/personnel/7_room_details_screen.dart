import 'package:flutter/material.dart';
import '8_update_room_status_screen.dart';

class RoomDetailsScreen extends StatelessWidget {
  final String roomNumber;
  const RoomDetailsScreen({super.key, required this.roomNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Room $roomNumber Details', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.bed, size: 80, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text('General Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _detailRow('Room Type', 'Single'),
            _detailRow('Current Occupancy', '1/1'),
            _detailRow('Status', 'Occupied'),
            const SizedBox(height: 24),
            const Text('Room Features', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _featureItem('Near Balcony'),
            _featureItem('Self-contained'),
            _featureItem('Bathroom Distance: 0m (En-suite)'),
            _featureItem('Window View: Campus Main Gate'),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _navigateToUpdate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: BorderRadius.circular(12),
                    ),
                    child: const Text('Update Status', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToUpdate(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateRoomStatusScreen(roomNumber: roomNumber)));
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _featureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Text(feature, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
