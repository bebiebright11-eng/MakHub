import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/constants/app_colors.dart';

/// Displayed when hostel personnel taps a reservation card in the
/// Students tab.  Loads all required fields from Firestore using the
/// booking document ID.
///
/// Uses a Firestore stream so booking status updates automatically.
class ReservationDetailsScreen extends StatefulWidget {
  /// The Firestore document ID — used only for internal lookups.
  final String bookingId;

  const ReservationDetailsScreen({super.key, required this.bookingId});

  @override
  State<ReservationDetailsScreen> createState() =>
      _ReservationDetailsScreenState();
}

class _ReservationDetailsScreenState
    extends State<ReservationDetailsScreen> {
  // ── Cached side-data (student, hostel, room) loaded once ─────────────────
  bool _sideDataLoaded = false;
  String _studentName = 'Unknown';
  String _studentEmail = 'N/A';
  String _studentPhone = 'N/A';
  String _hostelName = 'Unknown Hostel';
  String _floorNumber = 'N/A';
  String _roomNumber = 'N/A';
  String _roomType = 'N/A';
  String _reportingDate = 'Not set';
  String _bookingDate = 'N/A';

  @override
  void initState() {
    super.initState();
    _loadSideData();
  }

  /// Loads student / hostel / room data once — these fields never change
  /// after a booking is created.  Only bookingStatus needs live updates,
  /// which is handled by the StreamBuilder below.
  Future<void> _loadSideData() async {
    final fs = FirebaseFirestore.instance;

    final bookingDoc =
        await fs.collection('bookings').doc(widget.bookingId).get();
    if (!bookingDoc.exists) return;

    final b = bookingDoc.data()!;
    final studentId = (b['studentId'] ?? '').toString();
    final hostelId = (b['hostelId'] ?? '').toString();
    final floorId = (b['floorId'] ?? '').toString();
    final roomId = (b['roomId'] ?? '').toString();

    // Booking date
    final bts = b['bookingDate'] as Timestamp?;
    if (bts != null) {
      final d = bts.toDate();
      _bookingDate =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }

    // Student
    if (studentId.isNotEmpty) {
      final uDoc = await fs.collection('users').doc(studentId).get();
      if (uDoc.exists) {
        final u = uDoc.data()!;
        _studentName = (u['fullName'] ?? _studentName).toString();
        _studentEmail = (u['email'] ?? _studentEmail).toString();
        _studentPhone = (u['phoneNumber'] ?? _studentPhone).toString();
      }
    }

    // Hostel + reporting date
    if (hostelId.isNotEmpty) {
      final hDoc = await fs.collection('hostels').doc(hostelId).get();
      if (hDoc.exists) {
        _hostelName =
            (hDoc.data()?['hostelName'] ?? _hostelName).toString();
        final ts = hDoc.data()?['reportingDate'] as Timestamp?;
        if (ts != null) {
          final d = ts.toDate();
          _reportingDate =
              '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
        }
      }
    }

    // Floor
    if (hostelId.isNotEmpty && floorId.isNotEmpty) {
      final fDoc = await fs
          .collection('hostels')
          .doc(hostelId)
          .collection('floors')
          .doc(floorId)
          .get();
      if (fDoc.exists) {
        _floorNumber = (fDoc.data()?['floorName'] ??
                fDoc.data()?['floorNumber'] ??
                _floorNumber)
            .toString();
      }
    }

    // Room
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
        _roomNumber =
            (rDoc.data()?['roomNumber'] ?? _roomNumber).toString();
        _roomType = (rDoc.data()?['roomType'] ?? _roomType).toString();
      }
    }

    if (mounted) setState(() => _sideDataLoaded = true);
  }

  // ── Status helpers ────────────────────────────────────────────────────────

  /// Converts the raw Firestore bookingStatus to a display label.
  String _statusLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'confirmed':
        return 'Room Reserved';
      case 'payment_received':
        return 'Payment Received';
      case 'pending':
        return 'Pending Payment';
      case 'cancelled':
        return 'Cancelled';
      case 'checked_in':
        return 'Checked In';
      default:
        return raw.isNotEmpty ? raw : 'Unknown';
    }
  }

  Color _statusColor(String raw) {
    switch (raw.toLowerCase()) {
      case 'confirmed':
      case 'checked_in':
        return Colors.green;
      case 'payment_received':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
      // Stream the booking document so status updates in real time.
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !_sideDataLoaded) {
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

          // Extract live fields from the booking document.
          final liveData = snapshot.data?.data() as Map<String, dynamic>?;
          final rawStatus =
              (liveData?['bookingStatus'] ?? 'pending').toString();

          // Human-readable Booking ID — prefer stored field, fall back to doc ID.
          final humanBookingId =
              (liveData?['bookingId'] ?? '').toString().isNotEmpty
                  ? liveData!['bookingId'].toString()
                  : widget.bookingId;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Student avatar + name ────────────────────────────
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
                        _sideDataLoaded ? _studentName : '...',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Booking information ──────────────────────────────
                _sectionTitle('Booking Information'),
                _card([
                  _row('Booking ID', humanBookingId),
                  _row('Booking Date',
                      _sideDataLoaded ? _bookingDate : '...'),
                  _row('Reporting Date',
                      _sideDataLoaded ? _reportingDate : '...'),
                ]),

                const SizedBox(height: 20),

                // ── Student information ──────────────────────────────
                _sectionTitle('Student Information'),
                _card([
                  _row('Full Name',
                      _sideDataLoaded ? _studentName : '...'),
                  _row('Email',
                      _sideDataLoaded ? _studentEmail : '...'),
                  _row('Phone Number',
                      _sideDataLoaded ? _studentPhone : '...'),
                ]),

                const SizedBox(height: 20),

                // ── Room information ─────────────────────────────────
                _sectionTitle('Room Information'),
                _card([
                  _row('Hostel',
                      _sideDataLoaded ? _hostelName : '...'),
                  _row('Floor',
                      _sideDataLoaded ? _floorNumber : '...'),
                  _row('Room Number',
                      _sideDataLoaded ? _roomNumber : '...'),
                  _row('Room Type',
                      _sideDataLoaded ? _roomType : '...'),
                ]),

                const SizedBox(height: 20),

                // ── Status (live from Firestore stream) ───────────────
                _sectionTitle('Status'),
                _card([
                  _statusRow('Booking Status', rawStatus),
                ]),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        child: Column(children: children),
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
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      );

  Widget _statusRow(String label, String rawStatus) {
    final displayLabel = _statusLabel(rawStatus);
    final color = _statusColor(rawStatus);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              displayLabel,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
