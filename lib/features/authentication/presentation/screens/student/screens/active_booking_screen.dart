import 'package:flutter/material.dart';
import 'booking_information_screen.dart';


class StudentActiveBookingScreen extends StatelessWidget {
  final String bookingId;
  final String hostelName;
  final String roomNumber;
  final String bookingStatus;

  const StudentActiveBookingScreen({
    super.key,
    required this.bookingId,
    required this.hostelName,
    required this.roomNumber,
    this.bookingStatus = "Payment Received",
  });

  @override
  Widget build(BuildContext context) {
    final steps = ["Pending", "Payment Received", "Room Reserved"];
    final currentStep = steps.indexOf(bookingStatus);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Active Booking"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow("Booking ID", bookingId),
                  const SizedBox(height: 10),
                  _infoRow("Hostel", hostelName),
                  const SizedBox(height: 10),
                  _infoRow("Room", roomNumber),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              "Booking Progress",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Column(
              children: List.generate(steps.length, (index) {
                final isDone = index <= currentStep;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone ? Colors.blue : Colors.grey.shade300,
                          ),
                          child: isDone
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                        if (index != steps.length - 1)
                          Container(
                            width: 2,
                            height: 40,
                            color: isDone ? Colors.blue : Colors.grey.shade300,
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        steps[index],
                        style: TextStyle(
                          fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                          color: isDone ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentBookingInformationScreen(
                        bookingId: bookingId,
                        hostelName: hostelName,
                        roomNumber: roomNumber,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "View Booking Details",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}