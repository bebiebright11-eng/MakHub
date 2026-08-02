import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makhub/core/constants/payment_constants.dart';
import 'student_receipt_screen.dart';

class StudentBookingInformationScreen extends StatefulWidget {
  final String bookingId;
  final String hostelId;
  final String roomId;
  final String floorId;

  const StudentBookingInformationScreen({
    super.key,
    required this.bookingId,
    required this.hostelId,
    required this.roomId,
    required this.floorId,
  });

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
    if (status == "confirmed" || status == "Confirmed") return Colors.green;
    if (status == "pending" || status == "Pending") return Colors.orange;
    return Colors.red;
  }

  // ── Display-label mappers ─────────────────────────────────────────────
  // Maps raw Firestore bookingStatus values to human-readable labels.

  /// Payment status label shown to the student.
  String get _paymentLabel {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'payment_received':
        return 'Received';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  /// Booking status label shown to the student.
  String get _bookingLabel {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Reserved';
      case 'payment_received':
        return 'Payment Received';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'checked_in':
        return 'Checked In';
      default:
        return 'Pending';
    }
  }

  /// Room status label shown to the student.
  String get _roomLabel {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'checked_in':
        return 'Reserved';
      case 'payment_received':
      case 'pending':
        return 'Pending';
      case 'cancelled':
      case 'rejected':
        return 'Released';
      default:
        return 'Pending';
    }
  }

  /// Colour used for a given label pill.
  Color _labelColor(String label) {
    switch (label) {
      case 'Received':
      case 'Reserved':
      case 'Checked In':
        return Colors.green;
      case 'Payment Received':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      case 'Cancelled':
      case 'Rejected':
      case 'Released':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String remainingBalance = "";
  bool isLoading = true;
  String amountPaid = "";
  String hostelName = "";
  String roomNumber = "";
  String floor = "";
  String reportingDate = "Not set";
  String bookingDate = "N/A";
  String status = "Pending";
  String paymentMethod = "Mobile Money";
  // Human-readable Booking ID stored in the booking doc after payment.
  // Falls back to the Firestore doc ID for backward compatibility.
  String _humanBookingId = "";

Future<void> _loadRemainingBalance() async {
  try {
    final bookingDoc = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .get();

    final bookingData = bookingDoc.data();

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

    final reportingTimestamp = hostelDoc.data()?['reportingDate'] as Timestamp?;

    final bookingTimestamp = bookingData?['bookingDate'] as Timestamp?;

    // Payment method from the payments record for this booking
    final paymentSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('bookingId', isEqualTo: widget.bookingId)
        .limit(1)
        .get();

    setState(() {
      remainingBalance = "UGX $balance";
      amountPaid = "UGX ${PaymentConstants.bookingFee}";
      hostelName = hostelDoc['hostelName'] ?? 'Unknown Hostel';
      roomNumber = roomData?['roomNumber']?.toString() ?? 'N/A';
      floor = floorDoc['floorName']?.toString() ?? 'N/A';
      reportingDate = reportingTimestamp != null
          ? "${reportingTimestamp.toDate().day}/${reportingTimestamp.toDate().month}/${reportingTimestamp.toDate().year}"
          : "Not set";
      bookingDate = bookingTimestamp != null
          ? "${bookingTimestamp.toDate().day}/${bookingTimestamp.toDate().month}/${bookingTimestamp.toDate().year}"
          : "N/A";
      status = (bookingData?['bookingStatus'] ?? 'Pending').toString();
      if (paymentSnapshot.docs.isNotEmpty) {
        paymentMethod = (paymentSnapshot.docs.first.data()['paymentMethod'] ??
                'Mobile Money')
            .toString();
      }
      // Use the human-readable bookingId field; fall back to doc ID for
      // bookings created before this feature was introduced.
      _humanBookingId =
          (bookingData?['bookingId'] ?? '').toString().isNotEmpty
              ? bookingData!['bookingId'].toString()
              : widget.bookingId;
      isLoading = false;
    });
  } catch (e) {
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: _statusColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "Booking ${isLoading ? 'Loading...' : _bookingLabel}",
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
                 _infoRow("Booking ID", isLoading ? "Loading..." : _humanBookingId),
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
                  _infoRow("Booking Date", isLoading ? "Loading..." : bookingDate),
                  const SizedBox(height: 10),
                  _infoRow("Reporting Date", isLoading ? "Loading..." : reportingDate),
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
                  _infoRow("Payment Method", isLoading ? "Loading..." : paymentMethod),
                  const SizedBox(height: 10),
                  _infoRow(
                    "Payment",
                    isLoading ? "Loading..." : _paymentLabel,
                    valueColor: isLoading ? null : _labelColor(_paymentLabel),
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    "Booking",
                    isLoading ? "Loading..." : _bookingLabel,
                    valueColor: isLoading ? null : _labelColor(_bookingLabel),
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    "Room",
                    isLoading ? "Loading..." : _roomLabel,
                    valueColor: isLoading ? null : _labelColor(_roomLabel),
                  ),
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
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "View Receipt",
          style: TextStyle(
            color: AppColors.primary,
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
          backgroundColor: AppColors.primary,
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
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ),
      ],
    );
  }
}