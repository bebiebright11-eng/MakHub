import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_status_screen.dart';
import 'active_booking_screen.dart';
import 'package:makhub/core/constants/payment_constants.dart';
import '/algorithms/notification_algorithm.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentPaymentScreen extends StatefulWidget {
  final String bookingId;

  const StudentPaymentScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<StudentPaymentScreen> createState() =>
      _StudentPaymentScreenState();
}

class _StudentPaymentScreenState
    extends State<StudentPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileNumberController =
      TextEditingController();

  bool _isSaving = false;
  String hostelName = "";
  String floorNumber = "";
  String roomNumber = "";
  String hostelId = "";
  String floorId = "";
  String roomId = "";


bool isLoadingDetails = true;

@override
void initState() {
  super.initState();
  _loadBookingDetails();
}


Future<void> _loadBookingDetails() async {
  final bookingDoc = await FirebaseFirestore.instance
      .collection('bookings')
      .doc(widget.bookingId)
      .get();

  if (!bookingDoc.exists) return;

  final booking = bookingDoc.data()!;

  hostelId = booking['hostelId'] ?? '';
  floorId = booking['floorId'] ?? '';
  roomId = booking['roomId'] ?? '';

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
    hostelName =
        hostelDoc.data()?['hostelName'] ?? "Unknown Hostel";

    floorNumber =
        floorDoc.data()?['floorNumber']?.toString() ??
            "Unknown Floor";

    roomNumber =
        roomDoc.data()?['roomNumber'] ?? "Unknown Room";

    isLoadingDetails = false;
  });
}





  late final Stream<DocumentSnapshot> _bookingStream =
      FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .snapshots();

  @override
  void dispose() {
    _mobileNumberController.dispose();
    super.dispose();
  }

  Future<void> _payNow() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // ── Step 1: write payment record as 'confirmed' immediately
      //    (simulated payment — no real MNO call yet)
      await FirebaseFirestore.instance
          .collection('payments')
          .add({
        'bookingId': widget.bookingId,
        'amount': PaymentConstants.totalAmount,
        'mobileNumber': _mobileNumberController.text.trim(),
        'paymentStatus': 'confirmed',
        'paymentMethod': 'Mobile Money',
        'paymentTime': FieldValue.serverTimestamp(),
        'confirmedAt': FieldValue.serverTimestamp(),
      });

      // ── Step 2: mark booking as 'confirmed' (Room Reserved stage)
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({'bookingStatus': 'confirmed'});

      // ── Step 3: update room occupancy
      //    Read current occupied + capacity, increment, set status.
      //
      //    Single  capacity=1:  0→1  status='Occupied'
      //    Double  capacity=2:  0→1  status='Available'
      //                         1→2  status='Occupied'
      if (hostelId.isNotEmpty && floorId.isNotEmpty && roomId.isNotEmpty) {
        final roomRef = FirebaseFirestore.instance
            .collection('hostels')
            .doc(hostelId)
            .collection('floors')
            .doc(floorId)
            .collection('rooms')
            .doc(roomId);

        final roomSnap = await roomRef.get();
        if (roomSnap.exists) {
          final rd = roomSnap.data()!;

          final int capacity = rd['capacity'] is int
              ? rd['capacity'] as int
              : int.tryParse(rd['capacity'].toString()) ?? 1;

          final int currentOccupied = rd['occupied'] is int
              ? rd['occupied'] as int
              : int.tryParse(rd['occupied'].toString()) ?? 0;

          final int newOccupied = (currentOccupied + 1).clamp(0, capacity);

          await roomRef.update({
            'occupied': newOccupied,
            'status': newOccupied >= capacity ? 'Occupied' : 'Available',
          });
        }
      }

      // ── Step 4: send in-app notification to the student
      final studentId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (studentId.isNotEmpty) {
        await NotificationAlgorithm.roomReserved(
          studentId: studentId,
          bookingId: widget.bookingId,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment confirmed. Your room is reserved!'),
          backgroundColor: Colors.green,
        ),
      );

      // ── Step 5: navigate to Active Booking showing all three stages done
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentActiveBookingScreen(
            bookingId: widget.bookingId,
            hostelName: hostelName,
            roomNumber: roomNumber,
            hostelId: hostelId,
            roomId: roomId,
            floorId: floorId,
            bookingStatus: 'Room Reserved',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment"),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _bookingStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.data!.exists) {
            return const Center(
              child: Text("Booking not found"),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    
              Container(
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    children: [

      _summaryRow(
        "Booking ID",
        widget.bookingId,
      ),

      const SizedBox(height: 12),

      _summaryRow(
        "Hostel",
        hostelName,
      ),

      const SizedBox(height: 12),

      _summaryRow(
        "Floor",
        floorNumber,
      ),

      const SizedBox(height: 12),

      _summaryRow(
        "Room",
        roomNumber,
      ),
    ],
  ),
),

const SizedBox(height: 20),

                    Container(
                      padding:
                          const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _summaryRow(
  "Booking Fee",
  "UGX ${PaymentConstants.bookingFee}",
),

const SizedBox(height: 10),

_summaryRow(
  "Mobile Money Charges",
  "UGX ${PaymentConstants.mobileMoneyCharge}",
),

const SizedBox(height: 10),

_summaryRow(
  "Service Fee",
  "UGX ${PaymentConstants.serviceFee}",
),

const Divider(),

_summaryRow(
  "Total",
  "UGX ${PaymentConstants.totalAmount}",
  bold: true,
),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Mobile Money Number",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      controller:
                          _mobileNumberController,
                      keyboardType:
                          TextInputType.phone,
                      decoration: InputDecoration(
                        hintText:
                            "e.g. 0700000000",
                        prefixIcon:
                            const Icon(Icons.phone),
                        filled: true,
                        fillColor:
                            Colors.grey.shade100,
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  12),
                          borderSide:
                              BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return "Enter your phone number";
                        }

                        if (value.length < 10) {
                          return "Invalid phone number";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : _payNow,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.primary,
                          foregroundColor:
                              Colors.white,
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  color:
                                      Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Reserve Room & Pay Now",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StudentBookingStatusScreen(
                                bookingId:
                                    widget.bookingId,
                              ),
                            ),
                          );
                        },
                        style:
                            OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    12),
                          ),
                        ),
                        child: const Text(
                          "Reserve Room & Pay Later",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
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

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: bold
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: bold
                ? AppColors.primary
                : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: bold ? 18 : 15,
          ),
        ),
      ],
    );
  }
}