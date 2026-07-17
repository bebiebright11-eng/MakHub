import 'package:flutter/material.dart';
import 'room_list_screen.dart';

class StudentFloorSelectionScreen extends StatelessWidget {
  const StudentFloorSelectionScreen({super.key});

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
            Text('Select a Floor', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Kilimanjaro Hostel', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildFloorCard(context, 'Ground Floor', 'Rooms 101-110', 8, Icons.layers, const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
          _buildFloorCard(context, 'First Floor', 'Rooms 111-120', 6, Icons.apartment, const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
          _buildFloorCard(context, 'Second Floor', 'Rooms 121-130', 4, Icons.copy, const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
          _buildFloorCard(context, 'Third Floor', 'Rooms 131-140', 2, Icons.grid_view, const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildFloorCard(BuildContext context, String floor, String rooms, int available, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(floor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: available > 5 ? const Color(0xFFF1F5F9) : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$available available',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: available > 5 ? Colors.grey : const Color(0xFFF97316),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(rooms, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentRoomListScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('View Rooms', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
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
