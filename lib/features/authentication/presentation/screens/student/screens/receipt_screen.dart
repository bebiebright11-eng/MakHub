import 'package:flutter/material.dart';

class StudentReceiptScreen extends StatelessWidget {
  final String receiptNumber;
  final String bookingId;
  final String studentName;
  final String hostelName;
  final String roomNumber;
  final String amountPaid;
  final String date;
  final String time;
  final String transactionId;

  const StudentReceiptScreen({
    super.key,
    required this.receiptNumber,
    required this.bookingId,
    required this.studentName,
    required this.hostelName,
    required this.roomNumber,
    required this.amountPaid,
    this.date = "12 Jul 2026",
    this.time = "3:42 PM",
    this.transactionId = "TXN-2048-8891",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Receipt"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Payment Successful",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _infoRow("Receipt Number", receiptNumber),
                  const SizedBox(height: 10),
                  _infoRow("Booking ID", bookingId),
                  const SizedBox(height: 10),
                  _infoRow("Student Name", studentName),
                  const SizedBox(height: 10),
                  _infoRow("Hostel Name", hostelName),
                  const SizedBox(height: 10),
                  _infoRow("Room Number", roomNumber),
                  const Divider(height: 24),
                  _infoRow("Amount Paid", amountPaid, bold: true),
                  const SizedBox(height: 10),
                  _infoRow("Date", date),
                  const SizedBox(height: 10),
                  _infoRow("Time", time),
                  const SizedBox(height: 10),
                  _infoRow("Transaction ID", transactionId),
                ],
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // PDF download logic goes here later
                },
                icon: const Icon(Icons.download),
                label: const Text("Download Receipt"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: bold ? 16 : 14,
            color: bold ? Colors.blue : Colors.black,
          ),
        ),
      ],
    );
  }
}