import 'dart:async';
import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_verification_screen.dart';

class ReportingStudentsScreen extends StatefulWidget {
  const ReportingStudentsScreen({super.key});

  @override
  State<ReportingStudentsScreen> createState() => _ReportingStudentsScreenState();
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
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } else if (timestamp is String && timestamp.isNotEmpty) {
      return timestamp;
    }
    return 'Pending Check-in';
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value.trim().toLowerCase());
    });
  }

  /// Resolves a raw booking document into display-ready data by looking up
  /// the referenced student, hostel, and room documents.
  Future<Map<String, String>> _resolveBooking(
    String bookingId,
    Map<String, dynamic> booking,
  ) async {
    final studentId = booking['studentId'] as String?;
    final hostelId = booking['hostelId'] as String?;
    final floorId = booking['floorId'] as String?;
    final roomId = booking['roomId'] as String?;

    String name = 'Unknown Student';
    String hostelName = 'Unknown Hostel';
    String roomNumber = 'N/A';

    if (studentId != null) {
      final userDoc = await _firestore.collection('users').doc(studentId).get();
      if (userDoc.exists) {
        name = (userDoc.data()?['fullName'] ?? name).toString();
      }
    }

    if (hostelId != null) {
      final hostelDoc = await _firestore.collection('hostels').doc(hostelId).get();
      if (hostelDoc.exists) {
        hostelName = (hostelDoc.data()?['hostelName'] ?? hostelName).toString();
      }
    }

    if (hostelId != null && floorId != null && roomId != null) {
      final roomDoc = await _firestore
          .collection('hostels')
          .doc(hostelId)
          .collection('floors')
          .doc(floorId)
          .collection('rooms')
          .doc(roomId)
          .get();
      if (roomDoc.exists) {
        roomNumber = (roomDoc.data()?['roomNumber'] ?? roomNumber).toString();
      }
    }

    final rawDate = booking['bookingDate'] ?? booking['reportingDate'] ?? booking['createdAt'];

    return {
      'docId': bookingId,
      'name': name,
      'hostel': hostelName,
      'room': roomNumber.startsWith('Room') ? roomNumber : 'Room $roomNumber',
      'date': _formatDate(rawDate),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporting Students', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search Student, Hostel or ID',
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('bookings').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading reporting students: ${snapshot.error}'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No reporting students found.'));
                }

                return FutureBuilder<List<Map<String, String>>>(
                  future: Future.wait(
                    docs.map((doc) => _resolveBooking(
                          doc.id,
                          doc.data() as Map<String, dynamic>,
                        )),
                  ),
                  builder: (context, resolvedSnapshot) {
                    if (!resolvedSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var resolved = resolvedSnapshot.data!;

                    if (_searchQuery.isNotEmpty) {
                      resolved = resolved.where((r) {
                        return r['name']!.toLowerCase().contains(_searchQuery) ||
                            r['hostel']!.toLowerCase().contains(_searchQuery) ||
                            r['room']!.toLowerCase().contains(_searchQuery) ||
                            r['docId']!.toLowerCase().contains(_searchQuery);
                      }).toList();
                    }

                    if (resolved.isEmpty) {
                      return const Center(child: Text('No reporting students found.'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: resolved.length,
                      itemBuilder: (context, index) {
                        final r = resolved[index];
                        return _reportingCard(
                          context,
                          docId: r['docId']!,
                          name: r['name']!,
                          hostel: r['hostel']!,
                          room: r['room']!,
                          date: r['date']!,
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

  Widget _reportingCard(
    BuildContext context, {
    required String docId,
    required String name,
    required String hostel,
    required String room,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
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
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('$hostel • $room', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                Text('Reporting Date: $date', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentVerificationScreen(studentId: docId),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}