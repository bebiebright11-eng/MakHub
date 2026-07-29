import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/constants/app_colors.dart';
import '/algorithms/occupancy_algorithm.dart';
import '/algorithms/revenue_algorithm.dart';
import 'admin_hostels_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_notification_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_add_hostel_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // ── Live data futures ──────────────────────────────────────────────────
  late Future<_DashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<_DashboardStats> _loadStats() async {
    // Run all queries in parallel
    final results = await Future.wait([
      FirebaseFirestore.instance.collection('hostels').get(),
      OccupancyAlgorithm.computeAll(),
      RevenueAlgorithm.daily(),
      FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('bookingDate', descending: true)
          .limit(5)
          .get(),
    ]);

    final hostelCount =
        (results[0] as QuerySnapshot).docs.length;
    final occupancy = results[1] as OccupancyResult;
    final revenue = results[2] as RevenueResult;
    final recentBookings =
        (results[3] as QuerySnapshot).docs;

    return _DashboardStats(
      hostelCount: hostelCount,
      occupancy: occupancy,
      revenue: revenue,
      recentBookings: recentBookings,
    );
  }

  void _refresh() => setState(() => _statsFuture = _loadStats());

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'MakHub Admin',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<_DashboardStats>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final stats = snapshot.data!;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────
                  const Text(
                    'Welcome, Admin',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Here's what's happening today at MakHub.",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // ── Summary cards ──────────────────────────────────
                  _sectionLabel("TODAY'S SUMMARY"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _summaryCard(
                        stats.hostelCount.toString(),
                        'Total Hostels',
                        Icons.apartment,
                        AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      _summaryCard(
                        stats.occupancy.available.toString(),
                        'Available',
                        Icons.meeting_room,
                        Colors.green,
                      ),
                      const SizedBox(width: 10),
                      _summaryCard(
                        stats.occupancy.occupied.toString(),
                        'Occupied',
                        Icons.people,
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Occupancy + revenue row ────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          title: 'Occupancy',
                          value:
                              '${stats.occupancy.percentage}%',
                          subtitle:
                              '${stats.occupancy.occupied} / ${stats.occupancy.total} rooms',
                          icon: Icons.donut_large,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _metricCard(
                          title: 'Revenue Today',
                          value: stats.revenue.formattedTotal,
                          subtitle:
                              '${stats.revenue.paymentCount} payment${stats.revenue.paymentCount == 1 ? '' : 's'}',
                          icon: Icons.payments_outlined,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Quick actions ──────────────────────────────────
                  _sectionLabel('QUICK ACTIONS'),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.1,
                    children: [
                      _ActionButton('Add Hostel', Icons.add_business, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminAddHostelScreen(),
                          ),
                        );
                      }),
                      _ActionButton('Bookings', Icons.list_alt, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminBookingsScreen(),
                          ),
                        );
                      }),
                      _ActionButton('Payments', Icons.payment, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminPaymentsScreen(),
                          ),
                        );
                      }),
                      _ActionButton('Hostels', Icons.apartment, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminHostelsScreen(),
                          ),
                        );
                      }),
                      _ActionButton('Notifications', Icons.notifications, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminNotificationsScreen(),
                          ),
                        );
                      }),
                      _ActionButton('Profile', Icons.person, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminProfileScreen(),
                          ),
                        );
                      }),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Recent bookings ────────────────────────────────
                  _sectionLabel('RECENT BOOKINGS'),
                  const SizedBox(height: 12),
                  if (stats.recentBookings.isEmpty)
                    const Text('No recent bookings.',
                        style: TextStyle(color: Colors.grey))
                  else
                    ...stats.recentBookings.map((doc) {
                      final b = doc.data() as Map<String, dynamic>;
                      final status =
                          (b['bookingStatus'] ?? 'pending').toString();
                      final studentId =
                          (b['studentId'] ?? '').toString();
                      final ts =
                          b['bookingDate'] as Timestamp?;
                      final timeAgo = ts != null
                          ? _timeAgo(ts.toDate())
                          : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.calendar_today,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Booking ${doc.id.substring(0, 8)}…',
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                  Text(
                                    'Student: $studentId',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color:
                                            Colors.grey.shade600,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                _statusChip(status),
                                const SizedBox(height: 4),
                                Text(
                                  timeAgo,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 20),

                  // ── System health ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield, color: Colors.green),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'System Health Normal\nAll servers operational.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 1:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminHostelsScreen()));
              break;
            case 2:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminBookingsScreen()));
              break;
            case 3:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()));
              break;
            case 4:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminProfileScreen()));
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.apartment), label: 'Hostels'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
            color: Colors.grey, letterSpacing: 0.8),
      );

  Widget _summaryCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'confirmed':
        color = Colors.green;
        break;
      case 'payment_received':
        color = AppColors.primary;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Data holder ──────────────────────────────────────────────────────────────

class _DashboardStats {
  final int hostelCount;
  final OccupancyResult occupancy;
  final RevenueResult revenue;
  final List<QueryDocumentSnapshot> recentBookings;

  const _DashboardStats({
    required this.hostelCount,
    required this.occupancy,
    required this.revenue,
    required this.recentBookings,
  });
}

// ── Action button widget ─────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton(this.title, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
