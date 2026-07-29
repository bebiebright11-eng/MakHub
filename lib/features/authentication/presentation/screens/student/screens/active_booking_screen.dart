import 'package:flutter/material.dart';
import 'booking_information_screen.dart';

class StudentActiveBookingScreen extends StatelessWidget {
  final String bookingId;
  final String hostelName;
  final String roomNumber;
  final String bookingStatus;
  final String hostelId;
  final String roomId;
  final String floorId;

  const StudentActiveBookingScreen({
    super.key,
    required this.bookingId,
    required this.hostelName,
    required this.roomNumber,
    this.bookingStatus = "Pending",
    required this.hostelId,
    required this.roomId,
    required this.floorId,
  });

  static const List<Map<String, String>> _steps = [
    {
      "title": "Pending",
      "description": "Your booking is awaiting payment confirmation",
      "icon": "clock",
    },
    {
      "title": "Payment Received",
      "description": "Will activate after payment is completed",
      "icon": "check",
    },
    {
      "title": "Room Reserved",
      "description": "Your room will be locked for you after confirmation",
      "icon": "key",
    },
  ];

  Color get _statusColor {
    switch (bookingStatus) {
      case "Pending":
        return Colors.orange;
      case "Payment Received":
        return Colors.blue;
      case "Room Reserved":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _iconFor(String key) {
    switch (key) {
      case "clock":
        return Icons.access_time;
      case "check":
        return Icons.check;
      case "key":
        return Icons.vpn_key;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex =
        _steps.indexWhere((s) => s["title"] == bookingStatus);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Active Booking",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              "Track your current booking progress",
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Booking ID",
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                          Text(bookingId,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ],
                      ),
                      _statusPill(bookingStatus, _statusColor, filled: true),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _infoRow("Hostel Name", hostelName),
                  const SizedBox(height: 10),
                  _infoRow("Room Number", roomNumber),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Progress card
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: List.generate(_steps.length, (index) {
                  final step = _steps[index];
                  final isDone = index < currentIndex;
                  final isCurrent = index == currentIndex;
                  final isLast = index == _steps.length - 1;

                  final Color circleColor = isDone
                      ? Colors.blue
                      : isCurrent
                          ? Colors.orange
                          : Colors.grey.shade300;

                  final Color textColor =
                      isDone || isCurrent ? Colors.black : Colors.grey;

                  String badgeLabel;
                  Color badgeColor;
                  if (isDone) {
                    badgeLabel = "Done";
                    badgeColor = Colors.green;
                  } else if (isCurrent) {
                    badgeLabel = "Current";
                    badgeColor = Colors.orange;
                  } else {
                    badgeLabel = "Upcoming";
                    badgeColor = Colors.grey;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: circleColor.withValues(
                                    alpha: isDone || isCurrent ? 1.0 : 0.2),
                              ),
                              child: Icon(
                                isDone
                                    ? Icons.check
                                    : _iconFor(step["icon"]!),
                                size: 16,
                                color: isDone || isCurrent
                                    ? Colors.white
                                    : Colors.grey.shade500,
                              ),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 36,
                                color: isDone
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step["title"]!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isCurrent
                                        ? Colors.orange.shade800
                                        : textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  step["description"]!,
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                      height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _statusPill(badgeLabel, badgeColor),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 28),

            // View Booking Details button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentBookingInformationScreen(
                        bookingId: bookingId,
                        hostelId: hostelId,
                        roomId: roomId,
                        floorId: floorId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  "View Booking Details",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black)),
      ],
    );
  }

  Widget _statusPill(String label, Color color, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
