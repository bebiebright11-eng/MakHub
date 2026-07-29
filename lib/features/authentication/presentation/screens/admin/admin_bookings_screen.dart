import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_bookings_details_screen.dart';
import 'admin_notification_screen.dart';
import 'admin_profile_screen.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  String _selectedFilter = "Pending";
  String _searchQuery = "";

  // Cache resolved booking details so the stream doesn't re-fetch on rebuild
  final Map<String, Map<String, String>> _detailsCache = {};

  // Resolve student, hostel, floor and room info for one booking document
  Future<Map<String, String>> _resolveBooking(
      QueryDocumentSnapshot doc) async {
    if (_detailsCache.containsKey(doc.id)) return _detailsCache[doc.id]!;

    final data = doc.data() as Map<String, dynamic>;
    final firestore = FirebaseFirestore.instance;

    String studentName = 'Unknown Student';
    String hostelName = 'Unknown Hostel';
    String floorName = 'N/A';
    String roomNumber = 'N/A';
    String roomType = 'N/A';

    try {
      final studentId = (data['studentId'] ?? '').toString();
      if (studentId.isNotEmpty) {
        final studentDoc =
            await firestore.collection('users').doc(studentId).get();
        studentName =
            (studentDoc.data()?['fullName'] ?? 'Unknown Student').toString();
      }

      final hostelId = (data['hostelId'] ?? '').toString();
      final floorId = (data['floorId'] ?? '').toString();
      final roomId = (data['roomId'] ?? '').toString();

      if (hostelId.isNotEmpty) {
        final hostelDoc =
            await firestore.collection('hostels').doc(hostelId).get();
        hostelName =
            (hostelDoc.data()?['hostelName'] ?? 'Unknown Hostel').toString();

        if (floorId.isNotEmpty) {
          final floorDoc = await firestore
              .collection('hostels')
              .doc(hostelId)
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
                .doc(hostelId)
                .collection('floors')
                .doc(floorId)
                .collection('rooms')
                .doc(roomId)
                .get();
            roomNumber =
                (roomDoc.data()?['roomNumber'] ?? 'N/A').toString();
            roomType = (roomDoc.data()?['roomType'] ?? 'N/A').toString();
          }
        }
      }
    } catch (_) {
      // Keep fallbacks if any lookup fails
    }

    final resolved = {
      'studentName': studentName,
      'hostelName': hostelName,
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
    return "${d.day}/${d.month}/${d.year}";
  }

  String _statusLabel(String raw) {
    if (raw.isEmpty) return 'Pending';
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bookings"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "All hostels • Booking management",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value.trim().toLowerCase());
              },
              decoration: InputDecoration(
                hintText: "Search bookings...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _filterTab("Pending"),
                const SizedBox(width: 10),
                _filterTab("Confirmed"),
                const SizedBox(width: 10),
                _filterTab("Cancelled"),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .orderBy('bookingDate', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                        child:
                            Text('Error loading bookings: ${snapshot.error}'));
                  }

                  final docs = (snapshot.data?.docs ?? []).where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status =
                        (data['bookingStatus'] ?? 'pending').toString();
                    return status.toLowerCase() ==
                        _selectedFilter.toLowerCase();
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No ${_selectedFilter.toLowerCase()} bookings",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final status = _statusLabel(
                          (data['bookingStatus'] ?? 'pending').toString());
                      final date =
                          _formatDate(data['bookingDate'] as Timestamp?);

                      return FutureBuilder<Map<String, String>>(
                        future: _resolveBooking(doc),
                        builder: (context, detailsSnapshot) {
                          final details = detailsSnapshot.data;

                          if (details == null) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: Colors.grey.shade200),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              ),
                            );
                          }

                          // Apply search on resolved student/hostel names
                          if (_searchQuery.isNotEmpty &&
                              !details['studentName']!
                                  .toLowerCase()
                                  .contains(_searchQuery) &&
                              !details['hostelName']!
                                  .toLowerCase()
                                  .contains(_searchQuery)) {
                            return const SizedBox.shrink();
                          }

                          return _bookingCard(
                            name: details['studentName']!,
                            status: status,
                            hostelRoom:
                                "${details['hostelName']} • Room ${details['roomNumber']}",
                            date: date,
                            reference: doc.id.length > 6
                                ? doc.id.substring(doc.id.length - 6)
                                : doc.id,
                            hostel: details['hostelName']!,
                            floor: details['floorName']!,
                            roomNumber: details['roomNumber']!,
                            roomType: details['roomType']!,
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 2) return;
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminNotificationsScreen(),
              ),
            );
            return;
          }
          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminProfileScreen(),
              ),
            );
            return;
          }
          Navigator.pop(context);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Dashboard"),
          BottomNavigationBarItem(
              icon: Icon(Icons.apartment), label: "Hostels"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Bookings"),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: "Notifications"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _filterTab(String label) {
    final selected = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bookingCard({
    required String name,
    required String status,
    required String hostelRoom,
    required String date,
    required String reference,
    required String hostel,
    required String floor,
    required String roomNumber,
    required String roomType,
  }) {
    Color statusColor;
    if (status == "Confirmed") {
      statusColor = Colors.green;
    } else if (status == "Pending") {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hostelRoom,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Booking Date: $date", style: const TextStyle(fontSize: 12)),
              Text("Ref: $reference", style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminBookingDetailsScreen(
                      studentName: name,
                      hostel: hostel,
                      floor: floor,
                      roomNumber: roomNumber,
                      roomType: roomType,
                      bookingStatus: status,
                    ),
                  ),
                );
              },
              child: const Text("View"),
            ),
          ),
        ],
      ),
    );
  }
}
