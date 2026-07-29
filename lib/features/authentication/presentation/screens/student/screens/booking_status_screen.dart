import 'dart:async';
import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_screen.dart';
import 'package:makhub/core/constants/payment_constants.dart';

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

String hostelName = "";
String floorNumber = "";
String roomNumber = "";

bool isLoadingDetails = true;

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


  Future<void> _loadBookingDetails() async {
  final bookingDoc = await FirebaseFirestore.instance
      .collection('bookings')
      .doc(widget.bookingId)
      .get();

  if (!bookingDoc.exists) return;

  final booking = bookingDoc.data()!;

  final hostelId = booking['hostelId'];
  final floorId = booking['floorId'];
  final roomId = booking['roomId'];

  final hostelDoc = await FirebaseFirestore.instance
      .collection('hostels')
      .doc(hostelId)
      .get();

  final floorDoc = await FirebaseFirestore.instance
      .collection('hostels')
      .doc(hostelId)
      .collection('floors')
      .doc(floorId)
      .get();

  final roomDoc = await FirebaseFirestore.instance
      .collection('hostels')
      .doc(hostelId)
      .collection('floors')
      .doc(floorId)
      .collection('rooms')
      .doc(roomId)
      .get();

  setState(() {
    hostelName = hostelDoc.data()?['hostelName'] ?? 'Unknown Hostel';
    floorNumber = floorDoc.data()?['floorNumber']?.toString() ?? 'Unknown Floor';
    roomNumber = roomDoc.data()?['roomNumber'] ?? 'Unknown Room';

    // Change this field name if your Firestore uses a different one


    isLoadingDetails = false;
  });
}

@override
void initState() {
  super.initState();
  _loadBookingDetails();
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
          final expiresAtTimestamp = booking['expiresAt'] as Timestamp?;

          if (expiresAtTimestamp != null) {
            _startCountdown(expiresAtTimestamp.toDate());
          }

          return Center(
            child: SingleChildScrollView(
              child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CircleAvatar(
  radius: 32,
  backgroundColor: Color(0xFFFFF3E0),
  child: Icon(
    Icons.access_time,
    size: 30,
    color: Colors.orange,
  ),
),

const SizedBox(height: 12),

Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 8,
  ),
  decoration: BoxDecoration(
    color: Colors.orange.shade50,
    borderRadius: BorderRadius.circular(25),
  ),
  child: Text(
    "Booking Status: Pending",
    style: const TextStyle(
      color: Colors.orange,
      fontWeight: FontWeight.bold,
    ),
  ),
),


const SizedBox(height: 10),

Text(
  expiresAtTimestamp != null ? _formattedTime : "N/A",
  style: const TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  ),
),

const SizedBox(height: 6),

const Text(
  "Time remaining to complete payment",
  style: TextStyle(
    color: Colors.grey,
  ),
),

const SizedBox(height: 18),


Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.red.shade50,
    borderRadius: BorderRadius.circular(12),
  ),
  child: const Row(
    children: [
      Icon(Icons.warning_amber_rounded,
          color: Colors.red),
      SizedBox(width: 10),
      Expanded(
        child: Text(
          "You must complete payment before the timer expires, otherwise the room will automatically become available again.",
          style: TextStyle(
            fontSize: 12,
            color: Colors.red,
          ),
        ),
      ),
    ],
  ),
),

Container(
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Column(
    children: [
      _infoRow("Hostel", hostelName),
      const SizedBox(height: 12),

      _infoRow("Floor", floorNumber),
      const SizedBox(height: 12),

      _infoRow("Room", roomNumber),
      const SizedBox(height: 12),

      _infoRow(
        "Amount",
        "UGX ${PaymentConstants.totalAmount}",
      ),
    ],
  ),
),

const SizedBox(height: 30),


Container(
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.grey.shade300,
    ),
  ),
  child: Column(
    children: [

      Row(
        children: [

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: AppColors.primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Payment Deadline",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  "Complete payment before expiry",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Pending",
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 22),

      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "Progress",
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
      ),

      const SizedBox(height: 10),

      LinearProgressIndicator(
        value: 0.0,
        minHeight: 8,
        borderRadius: BorderRadius.circular(20),
      ),

      const SizedBox(height: 8),

      const Align(
        alignment: Alignment.centerRight,
        child: Text(
          "0%",
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      ),
    ],
  ),
),

const SizedBox(height: 15),


                
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
                        backgroundColor: AppColors.primary,
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
          ),
        );
        },
      ),
    );
  }

  Widget _infoRow(String title, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}
}