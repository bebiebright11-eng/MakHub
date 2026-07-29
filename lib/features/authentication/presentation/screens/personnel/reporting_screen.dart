import 'dart:async';
import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../state/app_state.dart';
import 'reservation_details_screen.dart';

/// Shows students who have successfully reserved a room (bookingStatus ==
/// 'confirmed') for the hostel this personnel manages.
///
/// Behaviour changes from the old Reporting screen:
///   • Only bookings with bookingStatus == 'confirmed' are shown.
///   • Only bookings for AppState().hostelId are shown.
///   • Verify button removed; the whole card is tappable → ReservationDetailsScreen.
///   • Displayed fields: Student Name, Room Number, Reporting Date.
class ReportingStudentsScreen extends StatefulWidget {
  const ReportingStudentsScreen({super.key});

  @override
  State<ReportingStudentsScreen> createState() =>
      _ReportingStudentsScreenState();
}

class _ReportingStudentsScreenState extends State<ReportingStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } else if (timestamp is String && timestamp.isNotEmpty) {
      return timestamp;
    }
    return 'Not set';
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value.trim().toLowerCase());
    });
  }

  /// Resolves a confirmed booking document into display-ready data by
  /// fetching the student name, room number and reporting date.
  Future<Map<String, String>> _resolveBooking(
    String bookingId,
    Map<String, dynamic> booking,
  ) async {
    final studentId = booking['studentId'] as String?;
    final hostelId  = booking['hostelId']  as String?;
    final floorId   = booking['floorId']   as String?;
    final roomId    = booking['roomId']    as String?;

    String name         = 'Unknown Student';
    String roomNumber   = 'N/A';
    String reportingDate = 'Not set';

    // Student name
    if (studentId != null && studentId.isNotEmpty) {
      final userDoc =
          await _firestore.collection('users').doc(studentId).get();
      if (userDoc.exists) {
        name = (userDoc.data()?['fullName'] ?? name).toString();
      }
    }

    // Room number
    if (hostelId != null &&
        floorId  != null &&
        roomId   != null &&
        hostelId.isNotEmpty &&
        floorId.isNotEmpty &&
        roomId.isNotEmpty) {
      final roomDoc = await _firestore
          .collection('hostels')
          .doc(hostelId)
          .collection('floors')
          .doc(floorId)
          .collection('rooms')
          .doc(roomId)
          .get();
      if (roomDoc.exists) {
        roomNumber =
            (roomDoc.data()?['roomNumber'] ?? roomNumber).toString();
      }
    }

    // Reporting date — stored on the hostel document
    if (hostelId != null && hostelId.isNotEmpty) {
      final hostelDoc =
          await _firestore.collection('hostels').doc(hostelId).get();
      if (hostelDoc.exists) {
        final ts = hostelDoc.data()?['reportingDate'] as Timestamp?;
        if (ts != null) {
          reportingDate = _formatDate(ts);
        }
      }
    }

    return {
      'docId':         bookingId,
      'name':          name,
      'room':          roomNumber.startsWith('Room')
                           ? roomNumber
                           : 'Room $roomNumber',
      'reportingDate': reportingDate,
    };
  }

  @override
  Widget build(BuildContext context) {
    final hostelId = AppState().hostelId;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reserved Students',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Search bar (kept; not yet functional per spec) ───────────
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search Student, Room or ID',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // ── Reservations list ────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Only confirmed bookings for this hostel
              stream: hostelId.isNotEmpty
                  ? _firestore
                      .collection('bookings')
                      .where('hostelId', isEqualTo: hostelId)
                      .where('bookingStatus', isEqualTo: 'confirmed')
                      .snapshots()
                  : const Stream.empty(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading reservations: ${snapshot.error}',
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No reserved students yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return FutureBuilder<List<Map<String, String>>>(
                  future: Future.wait(
                    docs.map(
                      (doc) => _resolveBooking(
                        doc.id,
                        doc.data() as Map<String, dynamic>,
                      ),
                    ),
                  ),
                  builder: (context, resolvedSnapshot) {
                    if (!resolvedSnapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    var resolved = resolvedSnapshot.data!;

                    // Client-side search filter (future-ready)
                    if (_searchQuery.isNotEmpty) {
                      resolved = resolved.where((r) {
                        return r['name']!
                                .toLowerCase()
                                .contains(_searchQuery) ||
                            r['room']!
                                .toLowerCase()
                                .contains(_searchQuery) ||
                            r['docId']!
                                .toLowerCase()
                                .contains(_searchQuery);
                      }).toList();
                    }

                    if (resolved.isEmpty) {
                      return const Center(
                        child: Text(
                          'No matching reservations found.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: resolved.length,
                      itemBuilder: (context, index) {
                        final r = resolved[index];
                        return _reservationCard(
                          context,
                          docId:         r['docId']!,
                          name:          r['name']!,
                          room:          r['room']!,
                          reportingDate: r['reportingDate']!,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Card widget ──────────────────────────────────────────────────────────

  Widget _reservationCard(
    BuildContext context, {
    required String docId,
    required String name,
    required String room,
    required String reportingDate,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReservationDetailsScreen(bookingId: docId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    room,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Reporting: $reportingDate',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Chevron signals tappability (no Verify button)
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
