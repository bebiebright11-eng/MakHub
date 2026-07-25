import 'package:flutter/material.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makhub/core/constants/payment_constants.dart';
import 'student_receipt_screen.dart';

class StudentBookingInformationScreen extends StatefulWidget {
  final String bookingId;
  final String hostelId;
  final String roomId;
  final String floorId;
  final String bookingDate;
  final String reportingDate;
  final String remainingBalance;
  final String amountPaid;
  final String paymentMethod;
  final String status;

  const StudentBookingInformationScreen({
    super.key,
    required this.bookingId,
    required this.hostelId,
    required this.roomId,
    required this.floorId,
    this.bookingDate = "12 Jul 2026",
    this.reportingDate = "12 Sep 2026",
    this.remainingBalance = "GHS 1,000",
    this.amountPaid = "GHS 515",
    this.paymentMethod = "Mobile Money",
    this.status = "Confirmed",
  });
  // ...

  @override
  State<StudentBookingInformationScreen> createState() =>
      _StudentBookingInformationScreenState();
}

class _StudentBookingInformationScreenState
    extends State<StudentBookingInformationScreen> {
  final Set<String> _checkedItems = {};

  final List<String> _checklist = [
    "Bring your Booking ID",
    "Carry the remaining hostel balance",
    "Bring a valid form of ID",
    "Report before the reporting date",
  ];

  Color get _statusColor {
    if (widget.status == "Confirmed") return Colors.green;
    if (widget.status == "Pending") return Colors.orange;
    return Colors.red;
  }

String remainingBalance = "";
  bool isLoading = true;
  String amountPaid = "";
  String hostelName = "";
  String roomNumber = "";
  String floor = "";

Future<void> _loadRemainingBalance() async {
  try {
    final hostelDoc = await FirebaseFirestore.instance
        .collection('hostels')
        .doc(widget.hostelId)
        .get();

    final floorDoc = await FirebaseFirestore.instance
        .collection('hostels')
        .doc(widget.hostelId)
        .collection('floors')
        .doc(widget.floorId)
        .get();

    final roomDoc = await FirebaseFirestore.instance
        .collection('hostels')
        .doc(widget.hostelId)
        .collection('floors')
        .doc(widget.floorId)
        .collection('rooms')
        .doc(widget.roomId)
        .get();

    final roomData = roomDoc.data();
    final roomType = roomData?['roomType'];

    int roomPrice = 0;

    if (roomType == "Single") {
      roomPrice = int.parse(hostelDoc['singlePrice']);
    } else {
      roomPrice = int.parse(hostelDoc['doublePrice']);
    }

    final balance = roomPrice - PaymentConstants.bookingFee;

    setState(() {
      remainingBalance = "UGX $balance";
      amountPaid = "UGX ${PaymentConstants.bookingFee}";
      hostelName = hostelDoc['hostelName'] ?? 'Unknown Hostel';
      roomNumber = roomData?['roomNumber']?.toString() ?? 'N/A';
      floor = floorDoc['floorName']?.toString() ?? 'N/A';
      isLoading = false;
    });
  } catch (e) {
    print("ERROR in _loadRemainingBalance: $e");
    setState(() {
      isLoading = false;
    });
  }
}

@override
void initState() {
  super.initState();
  _loadRemainingBalance();
}

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: _statusColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "Booking ${widget.status}",
                    style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Booking card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 _infoRow("Booking ID", widget.bookingId),
                  const SizedBox(height: 10),
                  _infoRow("Hostel", isLoading ? "Loading..." : hostelName),
                  const SizedBox(height: 10),
                  _infoRow("Room", isLoading ? "Loading..." : roomNumber),
                  const SizedBox(height: 10),
                  _infoRow("Floor", isLoading ? "Loading..." : floor),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Stay details
            const Text("Stay Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _infoRow("Booking Date", widget.bookingDate),
                  const SizedBox(height: 10),
                  _infoRow("Reporting Date", widget.reportingDate),
                  const SizedBox(height: 10),
                  _infoRow(
                    "Remaining Balance",
                    isLoading ? "Loading..." : remainingBalance,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Payment summary
            const Text("Payment Summary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _infoRow(
                    "Amount Paid",
                    "UGX ${PaymentConstants.bookingFee}",
                    valueColor: Colors.green,
                  ),
                  const SizedBox(height: 10),
                  _infoRow("Payment Method", widget.paymentMethod),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Checklist
            const Text("Before You Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...(_checklist.map((item) {
              final checked = _checkedItems.contains(item);
              return CheckboxListTile(
                value: checked,
                onChanged: (isChecked) {
                  setState(() {
                    if (isChecked == true) {
                      _checkedItems.add(item);
                    } else {
                      _checkedItems.remove(item);
                    }
                  });
                },
                title: Text(
                  item,
                  style: TextStyle(
                    decoration: checked ? TextDecoration.lineThrough : null,
                    color: checked ? Colors.grey : Colors.black,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            })),

            const SizedBox(height: 28),

Row(
  children: [
    // View Receipt Button
    Expanded(
      child: OutlinedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentReceiptScreen(
          bookingId: widget.bookingId,
        ),
      ),
    );
  },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.blue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "View Receipt",
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),

    const SizedBox(width: 12),

    // Contact Hostel Button
    Expanded(
      child: ElevatedButton(
        onPressed: () {
          // Contact hostel logic
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
          "Contact Hostel",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ),
  ],
),

const SizedBox(height: 20),

          ],
        ),
      );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
        ),
      ],
    );
  }
}