import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(onPressed: () {}, child: const Text('Mark all as read')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _notificationItem('New Booking Confirmed', 'Booking ID BK-2048 for Room 312 was created successfully.', '2m ago', Icons.calendar_today, const Color(0xFFDBEAFE), const Color(0xFF2563EB)),
          _notificationItem('Payment Awaiting Confirmation', 'John Doe has uploaded a payment receipt for BK-2048.', '15m ago', Icons.receipt_long, const Color(0xFFFED7AA), const Color(0xFFF97316)),
          _notificationItem('Student Reporting Today', '3 students are expected to report for check-in today.', '1h ago', Icons.group, const Color(0xFFCFFAFE), const Color(0xFF06B6D4)),
          _notificationItem('Room Status Updated', 'Room 104 changed from Reserved to Occupied.', '3h ago', Icons.bed, const Color(0xFFD1FAE5), const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _notificationItem(String title, String subtitle, String time, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, size: 20, color: iconColor)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(time, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
