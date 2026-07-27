import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "MakHub Admin",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const Text(
              "Hostel Administrator",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              "admin@makhub.com",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // Profile overview card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withOpacity(0.08),
                    child: const Icon(Icons.person, size: 32, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "MakHub Admin",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Hostel Administrator",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        "admin@makhub.com",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _infoTile(Icons.phone, "Phone Number", "+233 24 123 4567"),
            const SizedBox(height: 10),
            _infoTile(Icons.badge, "National ID", "GHA-1234-5678"),
            const SizedBox(height: 10),
            _infoTile(Icons.admin_panel_settings, "Position", "System Administrator"),

            const SizedBox(height: 28),

            const Text(
              "Account Menu",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const Text(
              "Manage your profile and app preferences",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            _menuRow(Icons.edit, "Edit Profile"),
            _menuRow(Icons.lock, "Change Password"),
            _menuRow(Icons.group, "Manage Personnel"),
            _menuRow(Icons.settings, "App Settings"),

            const SizedBox(height: 24),

            Center(
              child: TextButton.icon(
                onPressed: () {
                  // Log out logic goes here later
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  "Log Out",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 4) return; // already on Profile
          Navigator.pop(context);
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

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuRow(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}


