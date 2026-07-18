import 'package:flutter/material.dart';
 import 'active_booking_screen.dart';
 import 'notifications_screen.dart';
 import 'help_center_screen.dart';
 import 'profile_screen.dart';

class StudentMenuScreen extends StatelessWidget {
  const StudentMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _menuRow(Icons.person, "My Profile", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentProfileScreen(),
              ),
            );
          }),
          _menuRow(Icons.book_online, "My Booking", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentActiveBookingScreen(
                  bookingId: "BK-2048",
                  hostelName: "Sunrise Hostel",
                  roomNumber: "101A",
                ),
              ),
            );
          }),
          _menuRow(Icons.notifications, "Notifications", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentNotificationsScreen(),
              ),
            );
          }),
          _menuRow(Icons.help_outline, "Help Center", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentHelpCenterScreen(),
              ),
            );
          }),
          _menuRow(Icons.privacy_tip_outlined, "Privacy Policy", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentHelpCenterScreen(),
              ),
            );
          }),
          _menuRow(Icons.description_outlined, "Terms & Conditions", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentHelpCenterScreen(),
              ),
            );
          }),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Logout logic goes here later
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                "Log Out",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuRow(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}