import 'package:flutter/material.dart';

class StudentHelpCenterScreen extends StatelessWidget {
  const StudentHelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help Center"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Frequently Asked Questions",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _faqTile("How do I book a room?", "Search for a hostel, select a room, and follow the booking steps to complete payment."),
          _faqTile("How long do I have to pay?", "You have 12 hours to complete payment before the room becomes available again."),
          _faqTile("Are booking fees refundable?", "No, booking fees are non-refundable once payment is confirmed."),
          _faqTile("How do I contact my hostel?", "Go to your Booking Details screen and tap Contact Hostel."),

          const SizedBox(height: 28),

          const Text(
            "Need More Help?",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _actionRow(Icons.support_agent, "Contact Admin", () {
            // Contact Admin logic goes here later
          }),
          _actionRow(Icons.apartment, "Contact Hostel", () {
            // Contact Hostel logic goes here later
          }),
          _actionRow(Icons.chat, "WhatsApp Support", () {
            // WhatsApp deep link goes here later
          }),
          _actionRow(Icons.report_problem, "Report a Problem", () {
            // Report a Problem form goes here later
          }),
        ],
      ),
    );
  }

  Widget _faqTile(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 14),
          child: Text(
            answer,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _actionRow(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
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