import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentReceiptScreen extends StatefulWidget {
  final String bookingId;
  const StudentReceiptScreen({super.key, required this.bookingId});

  @override
  State<StudentReceiptScreen> createState() => _StudentReceiptScreenState();
}

class _StudentReceiptScreenState extends State<StudentReceiptScreen> {
  late final Stream<DocumentSnapshot> _bookingStream =
      FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Receipt"),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _bookingStream,
        builder: (context, bookingSnap) {
          if (!bookingSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!bookingSnap.data!.exists) {
            return const Center(child: Text('Booking not found'));
          }

          final booking = bookingSnap.data!.data() as Map<String, dynamic>;
          final hostelId = booking['hostelId'] as String? ?? '';
          final roomId = booking['roomId'] as String? ?? '';

          return FutureBuilder<List<DocumentSnapshot>>(
            future: Future.wait([
              FirebaseFirestore.instance.collection('hostels').doc(hostelId).get(),
              FirebaseFirestore.instance.collection('rooms').doc(roomId).get(),
            ]),
            builder: (context, futureSnap) {
              if (!futureSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final hostelData = futureSnap.data![0].data() as Map<String, dynamic>? ?? {};
              final roomData = futureSnap.data![1].data() as Map<String, dynamic>? ?? {};
              final bookingDate = booking['bookingDate'] as Timestamp?;
              final dateStr = bookingDate != null
                  ? '${bookingDate.toDate().day}/${bookingDate.toDate().month}/${bookingDate.toDate().year}'
                  : 'N/A';
              final timeStr = bookingDate != null
                  ? '${bookingDate.toDate().hour}:${bookingDate.toDate().minute.toString().padLeft(2, '0')}'
                  : 'N/A';

              return Padding(
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
                          _infoRow("Booking ID", widget.bookingId),
                          const SizedBox(height: 10),
                          _infoRow("Hostel Name", hostelData['hostelName'] ?? ''),
                          const SizedBox(height: 10),
                          _infoRow("Room Number", 'Room ${roomData['roomNumber'] ?? ''}'),
                          const Divider(height: 24),
                          _infoRow("Booking Status", booking['bookingStatus'] ?? '', bold: true),
                          const SizedBox(height: 10),
                          _infoRow("Date", dateStr),
                          const SizedBox(height: 10),
                          _infoRow("Time", timeStr),
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
              );
            },
          );
        },
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