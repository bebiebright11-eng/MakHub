import 'package:flutter/material.dart';
import 'booking_details_screen.dart';

class StudentRoomDetailsScreen extends StatelessWidget {
  const StudentRoomDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Room 101 • Single Room', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Color(0xFF2563EB)),
                              SizedBox(width: 4),
                              Text('Kilimanjaro Hostel', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                        child: const Text('Available', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildRoomDetails(),
                  const SizedBox(height: 32),
                  const Text('Room Highlights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('Comfort, privacy, and convenience.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  _buildHighlightsGrid(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(context),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: const Center(child: Icon(Icons.bed, size: 80, color: Colors.grey)),
        ),
        Positioned(
          top: 50,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(backgroundColor: Colors.white, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context))),
              Row(
                children: [
                  CircleAvatar(backgroundColor: Colors.white, child: IconButton(icon: const Icon(Icons.favorite_border, color: Colors.black), onPressed: () {})),
                  const SizedBox(width: 12),
                  CircleAvatar(backgroundColor: Colors.white, child: IconButton(icon: const Icon(Icons.share_outlined, color: Colors.black), onPressed: () {})),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Text('Available', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Room Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('Key information about this room before booking.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
          _detailRow(Icons.bathroom_outlined, 'Self-contained', 'Private bathroom included', 'Yes'),
          const SizedBox(height: 16),
          _detailRow(Icons.directions_walk, 'Bathroom Distance', 'From room entrance', 'Inside room'),
          const SizedBox(height: 16),
          _detailRow(Icons.balcony_outlined, 'Near Balcony', 'Natural light and airflow', 'Yes'),
          const SizedBox(height: 16),
          _detailRow(Icons.window_outlined, 'Window View', 'Facing the courtyard', 'Open view'),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String subtitle, String value) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF2563EB), size: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildHighlightsGrid() {
    return Row(
      children: [
        _highlightCard(Icons.wifi, 'Wi-Fi Ready', 'Stable connection for study and streaming.'),
        const SizedBox(width: 16),
        _highlightCard(Icons.laptop_chromebook, 'Study Space', 'Desk-friendly layout with good lighting.'),
      ],
    );
  }

  Widget _highlightCard(IconData icon, String title, String body) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 24),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentBookingDetailsScreen())),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: const Text('Book Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
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
