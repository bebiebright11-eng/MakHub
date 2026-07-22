import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '12_student_verification_screen.dart';

class ReportingStudentsScreen extends StatefulWidget {
  const ReportingStudentsScreen({super.key});

  @override
  State<ReportingStudentsScreen> createState() => _ReportingStudentsScreenState();
}

class _ReportingStudentsScreenState extends State<ReportingStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
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
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search Student, Hostel or ID',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
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
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .snapshots(),
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

                // Filter docs based on search query
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['studentName'] ?? data['userName'] ?? data['name'] ?? '').toString().toLowerCase();
                  final hostel = (data['hostelName'] ?? data['hostel'] ?? '').toString().toLowerCase();
                  final room = (data['roomNumber'] ?? data['room'] ?? '').toString().toLowerCase();
                  final bookingId = (data['bookingId'] ?? doc.id).toString().toLowerCase();

                  if (_searchQuery.isEmpty) return true;

                  return name.contains(_searchQuery) ||
                      hostel.contains(_searchQuery) ||
                      room.contains(_searchQuery) ||
                      bookingId.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text('No reporting students found.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final docId = doc.id;
                    final name = (data['studentName'] ?? data['userName'] ?? data['name'] ?? 'Student').toString();
                    final hostel = (data['hostelName'] ?? data['hostel'] ?? 'Hostel').toString();
                    final room = (data['roomNumber'] ?? data['room'] ?? 'N/A').toString();
                    
                    final rawDate = data['reportingDate'] ?? data['createdAt'] ?? data['checkInDate'] ?? data['bookingDate'];
                    final dateStr = _formatDate(rawDate);

                    return _reportingCard(
                      context,
                      docId: docId,
                      name: name,
                      hostel: hostel,
                      room: room.startsWith('Room') ? room : 'Room $room',
                      date: dateStr,
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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
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
            child: const Icon(Icons.person, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$hostel • $room',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                Text(
                  'Reporting Date: $date',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
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
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}