import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'preference_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  late final Stream<DocumentSnapshot> studentStream =
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .snapshots();

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      // rootNavigator: true ensures we escape any nested tab Navigator
      // and navigate at the MaterialApp level, clearing the full stack.
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        '/role-selection',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: ${e.toString()}')),
      );
    }
  }
          
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
  stream: studentStream,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!snapshot.hasData || !snapshot.data!.exists) {
      return const Center(
        child: Text("Student data not found"),
      );
    }

    final data = snapshot.data!.data() as Map<String, dynamic>;

    final studentName = data['fullName'] ?? '';
    final admissionNumber = data['admissionNumber'] ?? '';
    final university = data['university'] ?? '';
    final course = data['course'] ?? '';
    final phoneNumber = data['phoneNumber'] ?? '';
    final email = data['email'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  child: const Icon(
                    Icons.person,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  studentName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  admissionNumber,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          _infoTile(Icons.school, "University", university),
          const SizedBox(height: 10),

          _infoTile(Icons.book, "Course", course),
          const SizedBox(height: 10),

          _infoTile(Icons.phone, "Phone Number", phoneNumber),
          const SizedBox(height: 10),

          _infoTile(Icons.email, "Email", email),

          const SizedBox(height: 28),

          _menuRow(Icons.edit, "Edit Profile", () {}),

          _menuRow(
            Icons.tune,
              'Hostel Preferences',
            (){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) =>const StudentPreferenceScreen(),),
              );
            },
          ),

          _menuRow(Icons.lock, "Change Password", () {}),

          const SizedBox(height: 8),

          _menuRow(
            Icons.logout,
            "Logout",
            _handleLogout,
            isDestructive: true,
          ),
        ],
      ),
    );
  },
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

  Widget _menuRow(IconData icon, String label, VoidCallback onTap,
      {bool isDestructive = false}) {
    final color = isDestructive ? Colors.red : AppColors.primary;
    final textColor = isDestructive ? Colors.red : Colors.black;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                color: isDestructive ? Colors.red.shade200 : Colors.grey),
          ],
        ),
      ),
    );
  }
}