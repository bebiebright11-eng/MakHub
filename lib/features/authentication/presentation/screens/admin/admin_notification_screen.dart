import 'package:flutter/material.dart';
import 'admin_profile_screen.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "Stay updated on recent activity",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            _sectionLabel("TODAY"),
            _notificationTile(
              icon: Icons.book,
              iconColor: Colors.blue,
              title: "New booking request",
              subtitle: "Ama K. requested a room at Sunrise Residence.",
              time: "10m ago",
            ),
            _notificationTile(
              icon: Icons.payment,
              iconColor: Colors.green,
              title: "Payment received",
              subtitle: "GHS 2,500 was confirmed for Room 204.",
              time: "18m ago",
            ),
            _notificationTile(
              icon: Icons.star,
              iconColor: Colors.orange,
              title: "New student review",
              subtitle: "Kwesi M. left a 5-star review for the hostel.",
              time: "8:02 PM",
            ),
            _notificationTile(
              icon: Icons.person_add,
              iconColor: Colors.purple,
              title: "Personnel assigned",
              subtitle: "A new hostel attendant was assigned to First Floor.",
              time: "6h ago",
            ),

            const SizedBox(height: 20),
            _sectionLabel("YESTERDAY"),
            _notificationTile(
              icon: Icons.check_circle,
              iconColor: Colors.green,
              title: "Booking approved",
              subtitle: "Room 101 booking was approved and moved to confirmed.",
              time: "Mon, 4:22 PM",
            ),

            const SizedBox(height: 20),
            _sectionLabel("EARLIER"),
            _notificationTile(
              icon: Icons.build,
              iconColor: Colors.red,
              title: "Maintenance reminder",
              subtitle: "Room 106 reported a bathroom issue that needs attention.",
              time: "Sun, 9:05 PM",
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 3) return;
          if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminProfileScreen(),
        ),
      );
      return;
    } // already on Notifications
          Navigator.pop(context);
          // Other tabs can be wired the same way once ready.
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.apartment), label: "Hostels"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Bookings"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notifications"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _notificationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}