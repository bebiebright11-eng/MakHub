import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/algorithms/booking_id_service.dart';

class AdminPaymentDetailsScreen extends StatelessWidget {
  final String studentName;
  final String hostelRoom;
  final String amount;
  final String status;
  final String balance;
  final String method;
  final String reference;
  final String paymentDocId;
  final String bookingId;

  const AdminPaymentDetailsScreen({
    super.key,
    required this.studentName,
    required this.hostelRoom,
    required this.amount,
    required this.status,
    required this.balance,
    required this.method,
    required this.reference,
    required this.paymentDocId,
    required this.bookingId,
  });

  // Confirm the payment in Firestore, update the linked booking,
  // and assign the human-readable Booking ID via BookingIdService.
  Future<void> _markAsPaid(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(paymentDocId)
          .update({'paymentStatus': 'confirmed'});

      String hostelId = '';

      if (bookingId.isNotEmpty) {
        final bookingRef =
            FirebaseFirestore.instance.collection('bookings').doc(bookingId);
        final bookingDoc = await bookingRef.get();
        if (bookingDoc.exists) {
          await bookingRef.update({'bookingStatus': 'confirmed'});
          hostelId =
              (bookingDoc.data()?['hostelId'] ?? '').toString();
        }
      }

      // Generate and persist the human-readable Booking ID.
      // Non-fatal: a failure here must not undo the confirmed payment.
      if (bookingId.isNotEmpty && hostelId.isNotEmpty) {
        try {
          await BookingIdService.assignBookingId(
            bookingDocId: bookingId,
            hostelId: hostelId,
          );
        } catch (_) {
          // Booking ID can be backfilled later without invalidating the booking.
        }
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment marked as confirmed.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update payment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isConfirmed = status.toLowerCase() == 'confirmed';

    return Scaffold(
      appBar: AppBar(
        title: Text(studentName),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Student & Booking Info", "Booking summary and assigned room"),
            _infoRow("Student Name", studentName),
            const SizedBox(height: 10),
            _infoRow("Hostel", hostelRoom),

            const SizedBox(height: 22),
            _sectionTitle("Payment Breakdown", "Fee status and remaining balance"),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Amount Paid", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(amount, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Status", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            status,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isConfirmed ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Balance", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(balance, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),
            _sectionTitle("Payment Method", "Transaction reference and date"),
            _infoRow("Method", method),
            const SizedBox(height: 10),
            _infoRow("Reference", reference),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isConfirmed ? null : () => _markAsPaid(context),
                icon: const Icon(Icons.check_circle),
                label: Text(isConfirmed ? "Already Paid" : "Mark as Paid"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
