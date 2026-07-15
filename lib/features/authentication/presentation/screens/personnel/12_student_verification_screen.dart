import 'package:flutter/material.dart';

class StudentVerificationScreen extends StatelessWidget {
  const StudentVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Verification', style: TextStyle(fontWeight: FontWeight.bold)),
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
            const Text('John Doe', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: Column(
                children: [
                  _infoRow('Booking ID', 'BK-2048'),
                  _infoRow('Hostel', 'Elite Residency'),
                  _infoRow('Room', '312'),
                  _infoRow('Admission Letter', 'Verified ✓'),
                  _infoRow('Friend (Double)', 'N/A'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
              child: const Center(child: Text('Admission Letter Preview')),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student checked in successfully!')));
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 16), foregroundColor: Colors.white),
                    child: const Text('Check In Student'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
