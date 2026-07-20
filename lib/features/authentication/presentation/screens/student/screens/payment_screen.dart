import 'package:flutter/material.dart';
import 'booking_status_screen.dart';
import 'package:makhub/models/booking_model.dart';
import 'package:makhub/services/booking_service.dart';


class StudentPaymentScreen extends StatefulWidget {
  final String hostelName;
  final String roomNumber;
  final String bookingFee;
  final String mobileMoneyCharges;

  const StudentPaymentScreen({
    super.key,
    required this.hostelName,
    required this.roomNumber,
    this.bookingFee = "GHS 500",
    this.mobileMoneyCharges = "GHS 15",
  });

  @override
  State<StudentPaymentScreen> createState() => _StudentPaymentScreenState();
}

class _StudentPaymentScreenState extends State<StudentPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileNumberController = TextEditingController();
  final BookingService _bookingService = BookingService();k[]

  double get _bookingFeeValue =>
      double.tryParse(widget.bookingFee.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  double get _chargesValue =>
      double.tryParse(widget.mobileMoneyCharges.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  double get _totalValue => _bookingFeeValue + _chargesValue;

  @override
  void dispose() {
    _mobileNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.hostelName} • Room ${widget.roomNumber}",
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
                      _summaryRow("Booking Fee", widget.bookingFee),
                      const SizedBox(height: 10),
                      _summaryRow("Mobile Money Charges", widget.mobileMoneyCharges),
                      const Divider(height: 24),
                      _summaryRow(
                        "Total Amount",
                        "GHS ${_totalValue.toStringAsFixed(2)}",
                        bold: true,
                      ),
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
                    hintText: "e.g. 024 000 0000",
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
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Payment Successful!"),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Pay Now",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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