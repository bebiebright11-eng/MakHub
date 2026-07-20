import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_status_screen.dart';

class StudentPaymentScreen extends StatefulWidget {
  final String bookingId;
  const StudentPaymentScreen({super.key, required this.bookingId});

  @override
  State<StudentPaymentScreen> createState() => _StudentPaymentScreenState();
}

class _StudentPaymentScreenState extends State<StudentPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileNumberController = TextEditingController();
  bool _isSaving = false;

  late final Stream<DocumentSnapshot> _bookingStream =
      FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).snapshots();

  static const int _bookingFee = 50000;
  static const int _mobileMoneyCharge = 2000;
  int get _total => _bookingFee + _mobileMoneyCharge;

  @override
  void dispose() {
    _mobileNumberController.dispose();
    super.dispose();
  }

  Future<void> _payNow(String bookingId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final paymentRef = await FirebaseFirestore.instance.collection('payments').add({
        'bookingId': bookingId,
        'amount': _total,
        'mobileNumber': _mobileNumberController.text.trim(),
        'paymentStatus': 'pending',
        'paymentTime': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'bookingStatus': 'payment_received',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment submitted!")),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudentBookingStatusScreen(bookingId: bookingId),
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
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text('Booking not found'));
          }

          final booking = snapshot.data!.data() as Map<String, dynamic>;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Booking ID: ${widget.bookingId}",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _summaryRow("Booking Fee", "UGX $_bookingFee"),
                          const SizedBox(height: 10),
                          _summaryRow("Mobile Money Charges", "UGX $_mobileMoneyCharge"),
                          const Divider(height: 24),
                          _summaryRow("Total Amount", "UGX $_total", bold: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      "Mobile Money Number",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _mobileNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: "e.g. 0700 000 000",
                        prefixIcon: const Icon(Icons.phone_android),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your mobile money number";
                        }
                        if (value.length < 10) {
                          return "Please enter a valid phone number";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : () => _payNow(widget.bookingId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                "Pay Now",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: bold ? 15 : 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            fontSize: bold ? 17 : 14,
            color: bold ? Colors.blue : Colors.black,
          ),
        ),
      ],
    );
  }
}