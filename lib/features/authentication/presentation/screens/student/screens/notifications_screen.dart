import 'package:flutter/material.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      "icon": Icons.event_available,
      "color": Colors.blue,
      "title": "Booking Created",
      "subtitle": "Your booking for Sunrise Residence, Room 204 was created.",
      "time": "2h ago",
      "read": false,
    },
    {
      "icon": Icons.payment,
      "color": Colors.green,
      "title": "Payment Received",
      "subtitle": "GHS 515 was received for your booking.",
      "time": "2h ago",
      "read": false,
    },
    {
      "icon": Icons.meeting_room,
      "color": Colors.purple,
      "title": "Room Reserved",
      "subtitle": "Room 204 has been reserved for you.",
      "time": "1h ago",
      "read": false,
    },
    {
      "icon": Icons.calendar_today,
      "color": Colors.orange,
      "title": "Reporting Reminder",
      "subtitle": "Remember to report to the hostel before 12 Sep 2026.",
      "time": "Yesterday",
      "read": true,
    },
    {
      "icon": Icons.warning_amber_rounded,
      "color": Colors.red,
      "title": "Booking Expiry Warning",
      "subtitle": "Your pending booking will expire in 2 hours.",
      "time": "2 days ago",
      "read": true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var n in _notifications) {
                  n["read"] = true;
                }
              });
            },
            child: const Text("Mark All Read"),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final n = _notifications[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: n["read"] ? Colors.white : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: (n["color"] as Color).withOpacity(0.1),
                  child: Icon(n["icon"], color: n["color"], size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n["title"],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        n["subtitle"],
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n["time"],
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                if (!n["read"])
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}