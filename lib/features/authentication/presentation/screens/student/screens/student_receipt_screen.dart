import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makhub/core/constants/payment_constants.dart';

class StudentReceiptScreen extends StatefulWidget {
  final String bookingId;

  const StudentReceiptScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<StudentReceiptScreen> createState() =>
      _StudentReceiptScreenState();
}

class _StudentReceiptScreenState
    extends State<StudentReceiptScreen> {

  bool isLoading = true;

  String bookingId = "";
  String studentName = "";
  String hostelName = "";
  String roomNumber = "";
  String bookingStatus = "";
  String receiptNumber = "";
  String transactionId = "";
  String date = "";
  String time = "";

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

Future<void> _loadReceipt() async {
  try {
    // BOOKING
    final bookingSnapshot = await FirebaseFirestore.instance
        .collection("bookings")
        .doc(widget.bookingId)
        .get();

    if (!bookingSnapshot.exists) {
      throw Exception("Booking not found");
    }

    final booking = bookingSnapshot.data()!;

    debugPrint("========== BOOKING ==========");
    debugPrint("Booking ID : ${widget.bookingId}");
    debugPrint("Student ID : ${booking['studentId']}");
    debugPrint("Hostel ID  : ${booking['hostelId']}");
    debugPrint("Floor ID   : ${booking['floorId']}");
    debugPrint("Room ID    : ${booking['roomId']}");

    bookingId = widget.bookingId;

    final studentId = booking["studentId"];
    final hostelId = booking["hostelId"];
    final floorId = booking["floorId"];
    final roomId = booking["roomId"];

    // ---------------- STUDENT ----------------

    final studentSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(studentId)
        .get();

    debugPrint("Student Exists : ${studentSnapshot.exists}");

    if (studentSnapshot.exists) {
      final student = studentSnapshot.data()!;
      studentName = student["fullName"]?.toString() ?? "";
    }

    // ---------------- HOSTEL ----------------

    final hostelSnapshot = await FirebaseFirestore.instance
        .collection("hostels")
        .doc(hostelId)
        .get();

    debugPrint("Hostel Exists : ${hostelSnapshot.exists}");

    if (hostelSnapshot.exists) {
      final hostel = hostelSnapshot.data()!;
      hostelName = hostel["hostelName"]?.toString() ?? "";
    }

    // ---------------- ROOM ----------------

    final roomSnapshot = await FirebaseFirestore.instance
        .collection("hostels")
        .doc(hostelId)
        .collection("floors")
        .doc(floorId)
        .collection("rooms")
        .doc(roomId)
        .get();

    debugPrint("Room Exists : ${roomSnapshot.exists}");

    if (roomSnapshot.exists) {
      final room = roomSnapshot.data()!;
      roomNumber = "Room ${room["roomNumber"]}";
    }

    // ---------------- DATE ----------------

    if (booking["bookingDate"] != null) {
      final bookingDate =
          (booking["bookingDate"] as Timestamp).toDate();

      date =
          "${bookingDate.day}/${bookingDate.month}/${bookingDate.year}";

      time =
          "${bookingDate.hour}:${bookingDate.minute.toString().padLeft(2, '0')}";
    }

    bookingStatus = booking["bookingStatus"] ?? "";

    transactionId = "TXN-100001";

    receiptNumber =
        "RCPT-${widget.bookingId.substring(widget.bookingId.length - 5)}";

    debugPrint("Student Name : $studentName");
    debugPrint("Hostel Name  : $hostelName");
    debugPrint("Room Number  : $roomNumber");

    setState(() {
      isLoading = false;
    });
  } catch (e, stackTrace) {
    debugPrint("RECEIPT ERROR: $e");
    debugPrint(stackTrace.toString());

    setState(() {
      isLoading = false;
    });
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey.shade100,

    appBar: AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Receipt",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Payment confirmation",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    ),

    body: isLoading

          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [

                  /// Receipt Card

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.06),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),

                    child: Column(
                      children: [

                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(
                            Icons.verified_outlined,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),

                        const SizedBox(height: 30),

                        _infoRow(
                          "Receipt Number",
                          receiptNumber,
                        ),

                        Divider(
  color: Colors.grey.shade300,
  thickness: 1,
),

                        _infoRow(
                          "Booking ID",
                          bookingId,
                        ),

                        Divider(
  color: Colors.grey.shade300,
  thickness: 1,
),

                        _infoRow(
                          "Student Name",
                          studentName,
                        ),

                        Divider(
  color: Colors.grey.shade300,
  thickness: 1,
),

                        _infoRow(
                          "Hostel Name",
                          hostelName,
                        ),

                        Divider(
  color: Colors.grey.shade300,
  thickness: 1,
),

                        _infoRow(
                          "Room Number",
                          roomNumber,
                        ),

                        const SizedBox(height: 25),

                        const Divider(
                          thickness: 1.5,
                        ),

                        const SizedBox(height: 20),


                        Align(
  alignment: Alignment.centerLeft,
  child: Text(
    "Payment Breakdown",
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade800,
    ),
  ),
),

const SizedBox(height: 15),

                        _infoRow(
                          "Booking Fee",
                          "UGX ${PaymentConstants.bookingFee}",
                        ),

                        Divider(
  color: Colors.grey.shade300,
  thickness: 1,
),

                        _infoRow(
                          "Service Fee",
                          "UGX ${PaymentConstants.serviceFee}",
                        ),

                        Divider(
  color: Colors.grey.shade300,
  thickness: 1,
),

                        _infoRow(
                          "Mobile Money Fee",
                          "UGX ${PaymentConstants.mobileMoneyCharge}",
                        ),

                        Divider(
  color: Colors.grey.shade300,
  thickness: 1,
),

                        Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  ),
  decoration: BoxDecoration(
    color: Colors.blue.shade50,
    borderRadius: BorderRadius.circular(10),
  ),
  child: _infoRow(
    "Total Paid",
    "UGX ${PaymentConstants.totalAmount}",
    bold: true,
    valueColor: Colors.blue,
  ),
),

                        const SizedBox(height: 25),

                        const Divider(
                          thickness: 1.5,
                        ),

                        const SizedBox(height: 20),



                        Align(
  alignment: Alignment.centerLeft,
  child: Text(
    "Transaction Details",
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade800,
    ),
  ),
),

const SizedBox(height: 15),

                        _infoRow(
                          "Date",
                          date,
                        ),

                        Divider(
  color: Colors.grey.shade300,
  thickness: 1,
),

                        _infoRow(
                          "Time",
                          time,
                        ),

                        Divider(
  color: Colors.grey.shade300,
  thickness: 1,
),

                        _infoRow(
                          "Transaction ID",
                          transactionId,
                        ),

                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
  width: double.infinity,
  height: 58,
  child: ElevatedButton.icon(
    onPressed: () {

    },
    icon: const Icon(
      Icons.download_rounded,
      size: 22,
    ),
    label: const Text(
      "Download Receipt",
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    ),
  ),
),
                ],
              ),
            ),
    );
  }

 Widget _infoRow(
  String label,
  String value, {
  bool bold = false,
  Color valueColor = Colors.black,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        Expanded(
          flex: 5,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        Expanded(
          flex: 4,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: bold ? 16 : 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    ),
  );
}

}