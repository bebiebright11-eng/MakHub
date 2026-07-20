import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_screen.dart';

class StudentBookingStatusScreen extends StatefulWidget {
  final String bookingId;

  const StudentBookingStatusScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<StudentBookingStatusScreen> createState() => _StudentBookingStatusScreenState();
}

class _StudentBookingStatusScreenState extends State<StudentBookingStatusScreen> {
  Duration _remaining = Duration.zero;
  Timer? _timer;
  bool _initializedCountdown = false;

  late final Stream<DocumentSnapshot> _bookingStream = FirebaseFirestore.instance
      .collection('bookings')
      .doc(widget.bookingId)
      .snapshots();

  void _startCountdown(DateTime expiresAt) {
    if (_initializedCountdown) return;
    _initializedCountdown = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      setState(() {
        _remaining = expiresAt.isAfter(now) ? expiresAt.difference(now) : Duration.zero;
        if (_remaining == Duration.zero) {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final hours = _remaining.inHours.toString().padLeft(2, '0');
    final minutes = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Status"),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _bookingStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text('Booking not found'));
          }

          final booking = snapshot.data!.data() as Map<String, dynamic>;
          final bookingStatus = booking['bookingStatus'] ?? 'pending';
          final expiresAtTimestamp = booking['expiresAt'] as Timestamp?;

          if (expiresAtTimestamp != null) {
            _startCountdown(expiresAtTimestamp.toDate());
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      bookingStatus,
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    "Booking ID: ${widget.bookingId}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    "Time Remaining",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    expiresAtTimestamp != null ? _formattedTime : "N/A",
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "You must complete payment before the timer expires, otherwise the room will automatically become available again.",
                            style: TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentPaymentScreen(bookingId: widget.bookingId),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        "Proceed to Payment",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}