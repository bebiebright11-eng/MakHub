import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_status_screen.dart';
import 'active_booking_screen.dart';
import 'package:makhub/core/constants/payment_constants.dart';

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

  final hostelId = booking['hostelId'];
final floorId = booking['floorId'];
final roomId = booking['roomId'];

print("BOOKING DATA:");
print(booking);

print("hostelId = ${booking['hostelId']}");
print("floorId = ${booking['floorId']}");
print("roomId = ${booking['roomId']}");

  final hostelDoc = await FirebaseFirestore.instance
      .collection('hostels')
      .doc(hostelId)
      .get();

      print(hostelDoc.exists);
      print(hostelDoc.data());

  final floorDoc = await FirebaseFirestore.instance
      .collection('hostels')
      .doc(hostelId)
      .collection('floors')
      .doc(floorId)
      .get();

      print(floorDoc.exists);
      print(floorDoc.data());

  final roomDoc = await FirebaseFirestore.instance
      .collection('hostels')
      .doc(hostelId)
      .collection('floors')
      .doc(floorId)
      .collection('rooms')
      .doc(roomId)
      .get();

      print(roomDoc.exists);
      print(roomDoc.data());

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

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection("payments")
          .add({
        "bookingId": widget.bookingId,
        "amount": PaymentConstants.totalAmount,
        "mobileNumber":
            _mobileNumberController.text.trim(),
        "paymentStatus": "pending",
        "paymentTime":
            FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection("bookings")
          .doc(widget.bookingId)
          .update({
        "bookingStatus": "payment_received",
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment submitted successfully"),
        ),
      );

      Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => StudentActiveBookingScreen(
      bookingId: widget.bookingId,
    ),
  ),
);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment Failed: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
                              Colors.blue,
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
                            color: Colors.blue,
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
                            color: Colors.blue,
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
                ? Colors.blue
                : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: bold ? 18 : 15,
          ),
        ),
      ],
    );
  }
}