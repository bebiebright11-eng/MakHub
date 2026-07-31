import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/constants/app_colors.dart';
import 'admin_bookings_details_screen.dart';

/// Screen 2 — Hostel Bookings.
///
/// Displays all bookings that belong to a specific hostel.
/// Reached by tapping a hostel card on [AdminBookingsScreen].
/// Tapping a booking card navigates to [AdminBookingDetailsScreen].
class AdminHostelBookingsScreen extends StatefulWidget {
  final String hostelId;
  final String hostelName;

  const AdminHostelBookingsScreen({
    super.key,
    required this.hostelId,
    required this.hostelName,
  });

  @override
  State<AdminHostelBookingsScreen> createState() =>
      _AdminHostelBookingsScreenState();
}

class _AdminHostelBookingsScreenState
    extends State<AdminHostelBookingsScreen> {
  // ── Search ────────────────────────────────────────────────────────────
  // Lower-cased search query. Filtering is done in memory — Firestore is
  // never queried again after the initial stream delivers docs.
  String _searchQuery = '';

  // ── Details cache ─────────────────────────────────────────────────────
  // Resolved student / room details keyed by booking doc ID.
  // Once a booking is resolved it stays here so rebuilds are instant.
  final Map<String, Map<String, String>> _detailsCache = {};

  // ── Helpers ───────────────────────────────────────────────────────────

  Future<Map<String, String>> _resolveBooking(
      QueryDocumentSnapshot doc) async {
    if (_detailsCache.containsKey(doc.id)) return _detailsCache[doc.id]!;

    final data = doc.data() as Map<String, dynamic>;
    final firestore = FirebaseFirestore.instance;

    String studentName = 'Unknown Student';
    String floorName = 'N/A';
    String roomNumber = 'N/A';
    String roomType = 'N/A';

    try {
      // Resolve student name
      final studentId = (data['studentId'] ?? '').toString();
      if (studentId.isNotEmpty) {
        final studentDoc =
            await firestore.collection('users').doc(studentId).get();
        studentName =
            (studentDoc.data()?['fullName'] ?? 'Unknown Student').toString();
      }

      // Resolve floor and room — hostelId is already known from the filter
      final floorId = (data['floorId'] ?? '').toString();
      final roomId = (data['roomId'] ?? '').toString();

      if (floorId.isNotEmpty) {
        final floorDoc = await firestore
            .collection('hostels')
            .doc(widget.hostelId)
            .collection('floors')
            .doc(floorId)
            .get();
        floorName = (floorDoc.data()?['floorName'] ??
                floorDoc.data()?['floorNumber'] ??
                'N/A')
            .toString();

        if (roomId.isNotEmpty) {
          final roomDoc = await firestore
              .collection('hostels')
              .doc(widget.hostelId)
              .collection('floors')
              .doc(floorId)
              .collection('rooms')
              .doc(roomId)
              .get();
          roomNumber = (roomDoc.data()?['roomNumber'] ?? 'N/A').toString();
          roomType = (roomDoc.data()?['roomType'] ?? 'N/A').toString();
        }
      }
    } catch (_) {
      // Keep safe fallbacks if any lookup fails
    }

    final resolved = {
      'studentName': studentName,
      'floorName': floorName,
      'roomNumber': roomNumber,
      'roomType': roomType,
    };
    _detailsCache[doc.id] = resolved;
    return resolved;
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'N/A';
    final d = ts.toDate();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  // Short readable booking reference (last 8 chars of the Firestore ID)
  String _shortId(String id) => id.length > 8
      ? id.substring(id.length - 8).toUpperCase()
      : id.toUpperCase();

  /// Returns true when a resolved booking matches the current search query.
  /// Matches against student name OR the short booking ID (case-insensitive).
  bool _matchesSearch(String docId, Map<String, String> details) {
    if (_searchQuery.isEmpty) return true;
    final nameMatch =
        details['studentName']!.toLowerCase().contains(_searchQuery);
    final idMatch = _shortId(docId).toLowerCase().contains(_searchQuery);
    return nameMatch || idMatch;
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.hostelName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const Text(
              'Confirmed Bookings',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Stream all bookings for this hostel, newest first.
        // No status filter — the new workflow auto-confirms every booking.
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('hostelId', isEqualTo: widget.hostelId)
            .orderBy('bookingDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading bookings:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          return Column(
            children: [
              // ── Search bar ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search student or Booking ID...',
                    hintStyle: const TextStyle(
                        fontSize: 14, color: Colors.grey),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // ── Booking list ──────────────────────────────────────
              Expanded(
                child: docs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.book_outlined,
                                size: 56,
                                color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No bookings for ${widget.hostelName}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final bookingDate = _formatDate(
                              data['bookingDate'] as Timestamp?);
                          final bookingId = _shortId(doc.id);

                          return FutureBuilder<Map<String, String>>(
                            future: _resolveBooking(doc),
                            builder: (context, detailsSnap) {
                              // Loading placeholder while details resolve
                              if (!detailsSnap.hasData) {
                                return Container(
                                  margin: const EdgeInsets.only(
                                      bottom: 12),
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: Border.all(
                                        color: Colors.grey.shade200),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                              strokeWidth: 2),
                                    ),
                                  ),
                                );
                              }

                              final details = detailsSnap.data!;

                              // Apply in-memory search filter after
                              // details have been resolved. No Firestore
                              // call — pure local string comparison.
                              if (!_matchesSearch(doc.id, details)) {
                                return const SizedBox.shrink();
                              }

                              return _BookingCard(
                                studentName: details['studentName']!,
                                roomNumber: details['roomNumber']!,
                                bookingDate: bookingDate,
                                bookingId: bookingId,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AdminBookingDetailsScreen(
                                        studentName:
                                            details['studentName']!,
                                        hostel: widget.hostelName,
                                        floor: details['floorName']!,
                                        roomNumber:
                                            details['roomNumber']!,
                                        roomType: details['roomType']!,
                                        bookingStatus: 'Confirmed',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A single booking card for Screen 2.
///
/// Displays student name, room number, booking date, and booking ID.
/// No status chips — bookings at this point are always confirmed.
/// The entire card is tappable.
class _BookingCard extends StatelessWidget {
  final String studentName;
  final String roomNumber;
  final String bookingDate;
  final String bookingId;
  final VoidCallback onTap;

  const _BookingCard({
    required this.studentName,
    required this.roomNumber,
    required this.bookingDate,
    required this.bookingId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderGrey),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar / icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Main info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.meeting_room_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Room $roomNumber',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        bookingDate,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: $bookingId',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
