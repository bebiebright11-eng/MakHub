import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/constants/app_colors.dart';
import 'admin_hostel_bookings_screen.dart';
import 'admin_notification_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_hostels_screen.dart';
import 'admin_dashboard_screen.dart';

/// Screen 1 — Bookings entry point.
///
/// Shows a list of every hostel registered in MakHub.
/// Each card displays the hostel name and a live count of confirmed
/// bookings for that hostel, highlighted in orange.
/// Tapping a card opens [AdminHostelBookingsScreen] filtered to that hostel.
class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  // Holds the current search text (lower-cased for comparison).
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Bookings',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Stream all hostels — updates automatically when new hostels are added.
        stream: FirebaseFirestore.instance
            .collection('hostels')
            .orderBy('hostelName')
            .snapshots(),
        builder: (context, hostelSnapshot) {
          if (hostelSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hostelSnapshot.hasError) {
            return Center(
              child: Text(
                'Error loading hostels: ${hostelSnapshot.error}',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }

          // All hostel docs from Firestore
          final allDocs = hostelSnapshot.data?.docs ?? [];

          // Filter in memory — no extra Firestore call on every keystroke
          final filteredDocs = _searchQuery.isEmpty
              ? allDocs
              : allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name =
                      (data['hostelName'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

          return Column(
            children: [
              // ── Search bar ──────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search hostel...',
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

              // ── Hostel list ─────────────────────────────────────────
              Expanded(
                child: allDocs.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.apartment_outlined,
                                size: 56, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'No hostels registered yet.',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : filteredDocs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off,
                                    size: 56,
                                    color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text(
                                  'No hostels match your search.',
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                16, 8, 16, 16),
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final hostelDoc = filteredDocs[index];
                              final hostelData = hostelDoc.data()
                                  as Map<String, dynamic>;
                              final hostelId = hostelDoc.id;
                              final hostelName =
                                  (hostelData['hostelName'] ??
                                          'Unknown Hostel')
                                      .toString();

                              return _HostelBookingCard(
                                hostelId: hostelId,
                                hostelName: hostelName,
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 2) return;
          switch (index) {
            case 0:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminDashboardScreen()),
                (route) => false,
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminHostelsScreen()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminNotificationsScreen()),
              );
              break;
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminProfileScreen()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.apartment), label: 'Hostels'),
          BottomNavigationBarItem(
              icon: Icon(Icons.book), label: 'Bookings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

/// A single hostel card that streams its own confirmed booking count
/// so each card updates independently and in real time.
class _HostelBookingCard extends StatelessWidget {
  final String hostelId;
  final String hostelName;

  const _HostelBookingCard({
    required this.hostelId,
    required this.hostelName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Count all confirmed bookings for this specific hostel.
      // The new workflow confirms bookings automatically on payment,
      // so 'confirmed' is the only status that matters here.
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('hostelId', isEqualTo: hostelId)
          .where('bookingStatus', isEqualTo: 'confirmed')
          .snapshots(),
      builder: (context, bookingSnapshot) {
        // Show a spinner badge while the count loads
        final bookingCount = bookingSnapshot.data?.docs.length ?? 0;
        final isLoading =
            bookingSnapshot.connectionState == ConnectionState.waiting;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminHostelBookingsScreen(
                  hostelId: hostelId,
                  hostelName: hostelName,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGrey),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Hostel icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.apartment,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Hostel name
                Expanded(
                  child: Text(
                    hostelName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // Booking count badge (orange)
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '$bookingCount Booking${bookingCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),

                const SizedBox(width: 8),
                const Icon(Icons.chevron_right,
                    color: Colors.grey, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
