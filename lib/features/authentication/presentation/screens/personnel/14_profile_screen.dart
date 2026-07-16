import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Account', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundColor: Color(0xFFDBEAFE), child: Icon(Icons.person, size: 50, color: Color(0xFF2563EB))),
            const SizedBox(height: 16),
            const Text('Alex Johnson', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text('Hostel Personnel • Elite Residency', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 32),
            _profileItem(Icons.email_outlined, 'Email', 'alex.j@makhub.com'),
            _profileItem(Icons.phone_outlined, 'Phone Number', '+256 701 234 567'),
            const SizedBox(height: 32),
            _actionTile(context, Icons.lock_outline, 'Change Password', () {}),
            _actionTile(context, Icons.logout, 'Logout', () {
               Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            }, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _profileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          )
        ],
      ),
    );
  }

  Widget _actionTile(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : Colors.black, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right),
      contentPadding: EdgeInsets.zero,
    );
  }
}
