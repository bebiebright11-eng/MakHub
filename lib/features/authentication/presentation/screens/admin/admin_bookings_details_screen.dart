import 'package:flutter/material.dart';

class AdminBookingDetailsScreen extends StatelessWidget {
  final String studentName;
  final String hostel;
  final String floor;
  final String roomNumber;
  final String roomType;
  final String bookingStatus;

  const AdminBookingDetailsScreen({
    super.key,
    required this.studentName,
    required this.hostel,
    required this.floor,
    required this.roomNumber,
    required this.roomType,
    required this.bookingStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      app_bar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFFDBEAFE),
                child: Icon(Icons.person, size: 50, color: Color(0xFF2563EB)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                studentName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),
            _infoSection('Hostel Information', [
              _infoRow('Hostel', hostel),
              _infoRow('Floor', floor),
              _infoRow('Room Number', roomNumber),
              _infoRow('Room Type', roomType),
            ]),
            const SizedBox(height: 24),
            _infoSection('Booking Status', [
              _infoRow('Status', bookingStatus, isStatus: true),
            ]),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Bookings', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool isStatus = false}) {
    Color valueColor = Colors.black;
    if (isStatus) {
      if (value == 'Confirmed') valueColor = Colors.green;
      if (value == 'Pending') valueColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
