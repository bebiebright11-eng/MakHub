import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_status_screen.dart';
import 'active_booking_screen.dart';
import 'package:makhub/core/constants/payment_constants.dart';
import '/algorithms/notification_algorithm.dart';
import '/algorithms/booking_id_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentPaymentScreen extends StatefulWidget {
  final String bookingId;

  const StudentPaymentScreen({super.key, required this.bookingId});

  @override
  State<StudentPaymentScreen> createState() => _StudentPaymentScreenState();
}

class _StudentPaymentScreenState extends State<StudentPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileNumberController = TextEditingController();

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
      hostelName = hostelDoc.data()?['hostelName'] ?? "Unknown Hostel";
      floorNumber =
          floorDoc.data()?['floorNumber']?.toString() ?? "Unknown Floor";
      roomNumber = roomDoc.data()?['roomNumber'] ?? "Unknown Room";
      isLoadingDetails = false;
    });
  }

  late final Stream<DocumentSnapshot> _bookingStream = FirebaseFirestore
      .instance
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
      // ── Step 1: write payment record as 'confirmed' immediately ──────────
      //    Payment is accepted the moment the student submits — no manual
      //    approval step from hostel personnel.
      await FirebaseFirestore.instance.collection('payments').add({
        'bookingId': widget.bookingId,
        'studentId': FirebaseAuth.instance.currentUser?.uid ?? '',
        'amount': PaymentConstants.totalAmount,
        'mobileNumber': _mobileNumberController.text.trim(),
        'paymentStatus': 'confirmed',
        'paymentMethod': 'Mobile Money',
        'paymentTime': FieldValue.serverTimestamp(),
        'confirmedAt': FieldValue.serverTimestamp(),
      });

      // ── Step 2: mark booking as 'confirmed' (Room Reserved) ──────────────
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({'bookingStatus': 'confirmed'});

      // ── Step 3: update room occupancy ─────────────────────────────────────
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
              : int.tryParse(rd['capacity']?.toString() ?? '') ?? 1;

          final int currentOccupied = rd['occupied'] is int
              ? rd['occupied'] as int
              : int.tryParse(rd['occupied']?.toString() ?? '') ?? 0;

          final int newOccupied = (currentOccupied + 1).clamp(0, capacity);

          await roomRef.update({
            'occupied': newOccupied,
            'status': newOccupied >= capacity ? 'Occupied' : 'Available',
          });
        }
      }

      // ── Step 4: send in-app notifications to the student ─────────────────
      //    4a. Payment received / room reserved confirmation.
      //    4b. Reporting-date reminder (fetches date from the hostel doc).
      //        Both are non-fatal — a failure must never block the booking.
      final studentId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (studentId.isNotEmpty) {
        await NotificationAlgorithm.roomReserved(
          studentId: studentId,
          bookingId: widget.bookingId,
        );

        // 4b — reporting date reminder sent immediately after confirmation.
        try {
          await NotificationAlgorithm.reportingDateReminder(
            studentId: studentId,
            bookingId: widget.bookingId,
            hostelId: hostelId,
          );
        } catch (_) {
          // Non-fatal: reminder failure must never roll back the reservation.
        }
      }

      // ── Step 5: generate and store the human-readable Booking ID ──────────
      //    Runs only after payment, room reservation, and student notification
      //    have all succeeded — no ID is wasted on failed bookings.
      String assignedBookingId = widget.bookingId; // safe fallback
      try {
        assignedBookingId = await BookingIdService.assignBookingId(
          bookingDocId: widget.bookingId,
          hostelId: hostelId,
        );
      } catch (_) {
        // ID generation failure must not block the student — they already
        // have a confirmed reservation.  The ID can be backfilled later.
      }

      // ── Step 6: notify hostel personnel ───────────────────────────────────
      //    Look up all personnel whose hostelId matches, then write one
      //    notification per matching personnel account.
      try {
        // Resolve the student's display name for the notification message.
        String studentName = 'A student';
        if (studentId.isNotEmpty) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(studentId)
              .get();
          if (userDoc.exists) {
            studentName =
                (userDoc.data()?['fullName'] ?? studentName).toString();
          }
        }

        final personnelSnap = await FirebaseFirestore.instance
            .collection('personnel')
            .where('hostelId', isEqualTo: hostelId)
            .get();

        for (final pDoc in personnelSnap.docs) {
          final pData = pDoc.data();
          // Personnel notifications use their Firebase Auth UID stored in
          // the 'firebaseUid' field (written on first login), falling back
          // to the Firestore document ID for accounts not yet logged in.
          final pUid = (pData['firebaseUid'] ?? pDoc.id).toString();
          if (pUid.isEmpty) continue;

          await NotificationAlgorithm.newReservationForPersonnel(
            personnelId: pUid,
            roomNumber: roomNumber,
            studentName: studentName,
            bookingId: assignedBookingId,
            bookingDate: DateTime.now(),
          );
        }
      } catch (_) {
        // Personnel notification failure must never block the student flow.
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment confirmed. Your room is reserved!'),
          backgroundColor: Colors.green,
        ),
      );

      // ── Step 7: navigate to Active Booking with all stages completed ──────
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentActiveBookingScreen(
            bookingId: widget.bookingId,
            humanBookingId: assignedBookingId,
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
      appBar: AppBar(title: const Text("Payment"), centerTitle: true),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _bookingStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(child: Text("Booking not found"));
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Booking summary ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _summaryRow("Booking ID", widget.bookingId),
                          const SizedBox(height: 12),
                          _summaryRow("Hostel", hostelName),
                          const SizedBox(height: 12),
                          _summaryRow("Floor", floorNumber),
                          const SizedBox(height: 12),
                          _summaryRow("Room", roomNumber),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Fee breakdown ────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
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

                    const SizedBox(height: 20),

                    // ── Non-refundable warning ───────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFC107),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFF59E0B),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: Color(0xFF78350F),
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Booking fee is non-refundable. ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text:
                                        'Once payment is completed, the booking fee cannot be refunded.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ── Mobile money number ──────────────────────────────
                    const Text(
                      "Mobile Money Number",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _mobileNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: "e.g. 0700000000",
                        prefixIcon: const Icon(Icons.phone),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter your phone number";
                        }
                        if (value.length < 10) {
                          return "Invalid phone number";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 30),

                    // ── Pay Now button ───────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _payNow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Reserve Room & Pay Now",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Pay Later button ─────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentBookingStatusScreen(
                                bookingId: widget.bookingId,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Reserve Room & Pay Later",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: bold ? AppColors.primary : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: bold ? 18 : 15,
          ),
        ),
      ],
    );
  }
}
