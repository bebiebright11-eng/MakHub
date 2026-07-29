import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'active_booking_screen.dart';
import 'booking_information_screen.dart';

/// Routes the Booking tab to the correct screen based on the student's
/// current booking status:
///
///   - No booking → "You have not booked any room yet" empty state
///   - bookingStatus == 'pending' OR 'payment_received' → Active Booking screen
///   - bookingStatus == 'confirmed' OR 'checked_in' (or later) → Booking Details screen
///
/// Uses a Firestore stream so the tab automatically switches from Active Booking
/// to Booking Details the moment personnel confirms the payment.
class BookingTabRouter extends StatelessWidget {
  const BookingTabRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          "You're not logged in.",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('studentId', isEqualTo: user.uid)
          .orderBy('bookingDate', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        // ── Loading ──────────────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ── Error ────────────────────────────────────────────────────────
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Failed to load booking: ${snapshot.error}",
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
          );
        }

        // ── No booking ───────────────────────────────────────────────────
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "You have not booked any room yet.",
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        // ── Booking exists → route based on status ───────────────────────
        final bookingDoc = snapshot.data!.docs.first;
        final data = bookingDoc.data() as Map<String, dynamic>;

        final bookingId     = bookingDoc.id;
        final hostelId      = data['hostelId'] ?? '';
        final roomId        = data['roomId'] ?? '';
        final floorId       = data['floorId'] ?? '';
        final bookingStatus = (data['bookingStatus'] ?? 'pending').toString().toLowerCase();

        // Render Active Booking screen for in-progress stages
        if (bookingStatus == 'pending' || bookingStatus == 'payment_received') {
          return FutureBuilder<String>(
            future: _fetchHostelName(hostelId),
            builder: (context, hostelSnap) {
              final hostelName = hostelSnap.data ?? 'Unknown Hostel';
              // Map Firestore status to display label for the progress UI
              final displayStatus = _mapStatusToDisplayLabel(bookingStatus);

              return StudentActiveBookingScreen(
                bookingId:     bookingId,
                hostelName:    hostelName,
                roomNumber:    roomId,
                bookingStatus: displayStatus,
                hostelId:      hostelId,
                roomId:        roomId,
                floorId:       floorId,
              );
            },
          );
        }

        // Render Booking Details screen for confirmed/later stages
        return StudentBookingInformationScreen(
          bookingId: bookingId,
          hostelId:  hostelId,
          roomId:    roomId,
          floorId:   floorId,
        );
      },
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Future<String> _fetchHostelName(String hostelId) async {
    if (hostelId.isEmpty) return 'Unknown Hostel';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('hostels')
          .doc(hostelId)
          .get();
      return doc.data()?['hostelName'] ?? 'Unknown Hostel';
    } catch (_) {
      return 'Unknown Hostel';
    }
  }

  /// Maps Firestore bookingStatus values to the display labels used by
  /// StudentActiveBookingScreen's progress stepper.
  String _mapStatusToDisplayLabel(String firestoreStatus) {
    switch (firestoreStatus) {
      case 'pending':
        return 'Pending';
      case 'payment_received':
        return 'Payment Received';
      case 'confirmed':
        return 'Room Reserved';
      case 'checked_in':
        return 'Room Reserved'; // Checked-in is past reservation
      default:
        return 'Pending';
    }
  }
}
