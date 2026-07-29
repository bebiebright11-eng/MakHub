import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/constants/app_colors.dart';

/// Displayed when hostel personnel taps a reservation card in the
/// Students tab.  Loads all required fields from Firestore using the
/// booking document ID.
class ReservationDetailsScreen extends StatelessWidget {
  final String bookingId;

  const ReservationDetailsScreen({super.key, required this.bookingId});

  // ── Data loader ──────────────────────────────────────────────────────────

  Future<Map<String, String>> _load() async {
    final fs = FirebaseFirestore.instance;

    final bookingDoc = await fs.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) throw Exception('Booking not found.');

    final b = bookingDoc.data()!;
    final studentId = (b['studentId'] ?? '').toString();
    final hostelId  = (b['hostelId']  ?? '').toString();
    final floorId   = (b['floorId']   ?? '').toString();
    final roomId    = (b['roomId']    ?? '').toString();

    // ── Student details ──────────────────────────────────────────────────
    String studentName  = 'Unknown';
    String studentEmail = 'N/A';
    String studentPhone = 'N/A';

    if (studentId.isNotEmpty) {
      final uDoc = await fs.collection('users').doc(studentId).get();
      if (uDoc.exists) {
        final u = uDoc.data()!;
        studentName  = (u['fullName']    ?? studentName ).toString();
        studentEmail = (u['email']       ?? studentEmail).toString();
        studentPhone = (u['phoneNumber'] ?? studentPhone).toString();
      }
    }

    // ── Hostel details ───────────────────────────────────────────────────
    String hostelName = 'Unknown Hostel';
    if (hostelId.isNotEmpty) {
      final hDoc = await fs.collection('hostels').doc(hostelId).get();
      if (hDoc.exists) {
        hostelName = (hDoc.data()?['hostelName'] ?? hostelName).toString();
      }
    }

    // ── Floor details ────────────────────────────────────────────────────
    String floorNumber = 'N/A';
    if (hostelId.isNotEmpty && floorId.isNotEmpty) {
      final fDoc = await fs
          .collection('hostels')
          .doc(hostelId)
          .collection('floors')
          .doc(floorId)
          .get();
      if (fDoc.exists) {
        floorNumber = (fDoc.data()?['floorName'] ??
                       fDoc.data()?['floorNumber'] ??
                       floorNumber)
            .toString();
      }
    }

    // ── Room details ─────────────────────────────────────────────────────
    String roomNumber = 'N/A';
    String roomType   = 'N/A';
    if (hostelId.isNotEmpty && floorId.isNotEmpty && roomId.isNotEmpty) {
      final rDoc = await fs
          .collection('hostels')
          .doc(hostelId)
          .collection('floors')
          .doc(floorId)
          .collection('rooms')
          .doc(roomId)
          .get();
      if (rDoc.exists) {
        roomNumber = (rDoc.data()?['roomNumber'] ?? roomNumber).toString();
        roomType   = (rDoc.data()?['roomType']   ?? roomType  ).toString();
      }
    }

    // ── Hostel reporting date ────────────────────────────────────────────
    String reportingDate = 'Not set';
    if (hostelId.isNotEmpty) {
      final hDoc = await fs.collection('hostels').doc(hostelId).get();
      if (hDoc.exists) {
        final ts = hDoc.data()?['reportingDate'] as Timestamp?;
        if (ts != null) {
          final d = ts.toDate();
          reportingDate =
              '${d.day.toString().padLeft(2, '0')}/'
              '${d.month.toString().padLeft(2, '0')}/'
              '${d.year}';
        }
      }
    }

    // ── Booking date ─────────────────────────────────────────────────────
    String bookingDate = 'N/A';
    final bts = b['bookingDate'] as Timestamp?;
    if (bts != null) {
      final d = bts.toDate();
      bookingDate =
          '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    }

    return {
      'bookingId':     bookingId,
      'studentName':   studentName,
      'studentEmail':  studentEmail,
      'studentPhone':  studentPhone,
      'hostelName':    hostelName,
      'floorNumber':   floorNumber,
      'roomNumber':    roomNumber,
      'roomType':      roomType,
      'bookingDate':   bookingDate,
      'reportingDate': reportingDate,
      // All three statuses are 'Reserved' once bookingStatus == 'confirmed'
      'paymentStatus': 'Reserved',
      'roomStatus':    'Reserved',
      'bookingStatus': 'Reserved',
    };
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reservation Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load reservation details.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          final d = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Student avatar + name ──────────────────────────────
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFFDBEAFE),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        d['studentName']!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Booking information ────────────────────────────────
                _sectionTitle('Booking Information'),
                _card([
                  _row('Booking ID',     d['bookingId']!),
                  _row('Booking Date',   d['bookingDate']!),
                  _row('Reporting Date', d['reportingDate']!),
                ]),

                const SizedBox(height: 20),

                // ── Student information ────────────────────────────────
                _sectionTitle('Student Information'),
                _card([
                  _row('Full Name',    d['studentName']!),
                  _row('Email',        d['studentEmail']!),
                  _row('Phone Number', d['studentPhone']!),
                ]),

                const SizedBox(height: 20),

                // ── Room information ───────────────────────────────────
                _sectionTitle('Room Information'),
                _card([
                  _row('Hostel',       d['hostelName']!),
                  _row('Floor',        d['floorNumber']!),
                  _row('Room Number',  d['roomNumber']!),
                  _row('Room Type',    d['roomType']!),
                ]),

                const SizedBox(height: 20),

                // ── Status ────────────────────────────────────────────
                _sectionTitle('Status'),
                _card([
                  _statusRow('Payment Status', d['paymentStatus']!),
                  _statusRow('Room Status',    d['roomStatus']!),
                  _statusRow('Booking Status', d['bookingStatus']!),
                ]),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );

  Widget _card(List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: children,
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      );

  Widget _statusRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
}
