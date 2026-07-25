import 'package:flutter/material.dart';
import 'booking_information_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class StudentActiveBookingScreen extends StatefulWidget {
  final String bookingId;

  const StudentActiveBookingScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<StudentActiveBookingScreen> createState() => _StudentActiveBookingScreenState();
}

class _StudentActiveBookingScreenState extends State<StudentActiveBookingScreen> {

  late final Stream<DocumentSnapshot> _bookingStream =
      FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .snapshots();

String hostelName = '';
String roomNumber = '';
String hostelId = '';
String floorId = '';
String roomId = '';
bool isLoadingDetails = true;

Future<void> _loadBookingDetails() async {
  final bookingDoc = await FirebaseFirestore.instance
      .collection('bookings')
      .doc(widget.bookingId)
      .get();

  if (!bookingDoc.exists) return;

  final booking = bookingDoc.data()!;

  final fetchedHostelId = booking['hostelId'];
  final fetchedFloorId = booking['floorId'];
  final fetchedRoomId = booking['roomId'];

  final hostelDoc = await FirebaseFirestore.instance
      .collection('hostels')
      .doc(fetchedHostelId)
      .get();

  final roomDoc = await FirebaseFirestore.instance
      .collection('hostels')
      .doc(fetchedHostelId)
      .collection('floors')
      .doc(fetchedFloorId)
      .collection('rooms')
      .doc(fetchedRoomId)
      .get();

  final roomData = roomDoc.data();

  setState(() {
    hostelName = hostelDoc.data()?['hostelName'] ?? 'Unknown Hostel';
    roomNumber = roomData?['roomNumber']?.toString() ?? 'Unknown Room';
    hostelId = fetchedHostelId;
    floorId = fetchedFloorId;
    roomId = fetchedRoomId;
    isLoadingDetails = false;
  });
}


@override
void initState() {
  super.initState();
  _loadBookingDetails();
}

  @override
  Widget build(BuildContext context) {
return StreamBuilder<DocumentSnapshot>(
  stream: _bookingStream,
  builder: (context, snapshot) {
    if (!snapshot.hasData || isLoadingDetails) {
  return const Scaffold(
    body: Center(
      child: CircularProgressIndicator(),
    ),
  );
}

    final booking =
        snapshot.data!.data() as Map<String, dynamic>;

    final bookingStatus =
        booking['bookingStatus'] ?? 'Pending';

    

    final steps = [
      "Pending",
      "Payment Received",
      "Room Reserved"
    ];

    final currentStep = steps.indexOf(bookingStatus);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Active Booking"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  _infoRow("Hostel",hostelName),
                  const SizedBox(height: 10),
                  _infoRow("Room",roomNumber),
                ],
              ),
            ),
            const SizedBox(height: 32),

           
           Container(
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Column(
    children: [

      _progressTile(
        icon: Icons.access_time,
        iconColor: Colors.orange,
        title: "Pending",
        description: "Your booking is awaiting payment confirmation.",
        status: currentStep == 0
            ? "Current"
            : "Completed",
        statusColor: currentStep == 0
            ? Colors.orange
            : Colors.green,
        showLine: true,
      ),

      _progressTile(
        icon: Icons.check_circle,
        iconColor: currentStep >= 1
            ? Colors.green
            : Colors.grey,
        title: "Payment Received",
        description:
            "Will activate after payment is completed.",
        status: currentStep == 1
            ? "Current"
            : currentStep > 1
                ? "Completed"
                : "Upcoming",
        statusColor: currentStep == 1
            ? Colors.orange
            : currentStep > 1
                ? Colors.green
                : Colors.grey,
        showLine: true,
      ),

      _progressTile(
        icon: Icons.key,
        iconColor: currentStep == 2
            ? Colors.green
            : Colors.grey,
        title: "Room Reserved",
        description:
            "Your room will be locked for you after confirmation.",
        status: currentStep == 2
            ? "Current"
            : "Upcoming",
        statusColor: currentStep == 2
            ? Colors.orange
            : Colors.grey,
        showLine: false,
      ),
    ],
  ),
),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentBookingInformationScreen(
                        bookingId: widget.bookingId,
                        hostelId: hostelId,
                        roomId: roomId,
                        floorId: floorId,
                      ),
                    ),
                  );
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
                  "View Booking Details",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
  );
  }

    Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  Widget _progressTile({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String description,
  required String status,
  required Color statusColor,
  required bool showLine,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: iconColor.withOpacity(0.15),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          if (showLine)
            Container(
              width: 2,
              height: 55,
              color: Colors.grey.shade300,
            ),
        ],
      ),

      const SizedBox(width: 15),

      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                      fontSize: 15,
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
}