import 'package:flutter/material.dart';

class StudentBookingDetailsScreen extends StatelessWidget {
  final String bookingId;
  final String hostelName;
  final String roomNumber;
  final String bookingDate;
  final String reportingDate;
  final String remainingBalance;

  const StudentBookingDetailsScreen({
    super.key,
    required this.bookingId,
    required this.hostelName,
    required this.roomNumber,
    this.bookingDate = "12 Jul 2026",
    this.reportingDate = "12 Sep 2026",
    this.remainingBalance = "GHS 1,000",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Details"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
                  const SizedBox(height: 10),
                  _infoRow("Booking Date", bookingDate),
                  const SizedBox(height: 10),
                  _infoRow("Reporting Date", reportingDate),
                  const SizedBox(height: 10),
                  _infoRow("Remaining Balance", remainingBalance),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              "Instructions",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const _InstructionItem("Bring your Booking ID."),
            const _InstructionItem("Report before the reporting date."),
            const _InstructionItem("Carry the remaining hostel balance."),
            const _InstructionItem("Failure to report before the deadline may lead to cancellation."),
            const _InstructionItem("Booking fees are non-refundable."),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navigate to Receipt screen — wired next
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text("View Receipt"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Contact hostel logic goes here later
                },
                icon: const Icon(Icons.call),
                label: const Text("Contact Hostel"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _InstructionItem extends StatelessWidget {
  final String text;

  const _InstructionItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}