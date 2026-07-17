import 'package:flutter/material.dart';
import 'room_details_screen.dart';

class StudentRoomListScreen extends StatelessWidget {
  const StudentRoomListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available Rooms', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('First Floor', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildRoomCard(context, 'Room 101', 'Single Room', 'Single', 'Available', 'Empty', Colors.green),
          _buildRoomCard(context, 'Room 104', 'Double Room', 'Double', 'Available', '1/2 Occupied', Colors.orange),
          _buildRoomCard(context, 'Room 110', 'Double Room', 'Double', 'Available', 'Empty', Colors.green),
          _buildRoomCard(context, 'Room 112', 'Single Room', 'Single', 'Available', '1/2 Occupied', Colors.orange),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildRoomCard(BuildContext context, String roomNumber, String roomType, String bedType, String status, String occupancy, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.bed_outlined, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(roomNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(roomType, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(occupancy, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSmallTag(bedType, Colors.grey.shade100, Colors.grey.shade700),
              const SizedBox(width: 8),
              _buildSmallTag(status, const Color(0xFFFFF7ED), const Color(0xFFF97316)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentRoomDetailsScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallTag(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      selectedItemColor: const Color(0xFF2563EB),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Booking'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Notifications'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}
