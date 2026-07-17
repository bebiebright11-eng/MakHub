import 'package:flutter/material.dart';

class StudentProfileScreen extends StatelessWidget {
  final String studentName;
  final String admissionNumber;
  final String university;
  final String course;
  final String phoneNumber;
  final String email;

  const StudentProfileScreen({
    super.key,
    this.studentName = "Kwame Asante",
    this.admissionNumber = "GHA-2048-8912",
    this.university = "Makerere University",
    this.course = "Computer Science",
    this.phoneNumber = "+233 24 000 0000",
    this.email = "kwame.asante@student.mak.ac.ug",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(Icons.person, size: 44, color: Colors.blue),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    studentName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    admissionNumber,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
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

            _menuRow(Icons.edit, "Edit Profile", () {
              // Edit Profile screen goes here later
            }),
            _menuRow(Icons.lock, "Change Password", () {
              // Change Password screen goes here later
            }),
          ],
        ),
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
          Icon(icon, color: Colors.blue, size: 20),
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

  Widget _menuRow(IconData icon, String label, VoidCallback onTap) {
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