// ignore_for_file: file_names, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../state/app_state.dart';
import 'floors_screen.dart';
import 'payments_screen.dart';
import 'reporting_screen.dart';
import 'profile_screen.dart';
import 'hostel_details_screen.dart';
import 'notifications_screen.dart';
import '/core/constants/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _showBottomBar = true;

  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(5, (_) => GlobalKey<NavigatorState>());

  @override
  void initState() {
    super.initState();
    AppState().fetchStats();
  }

  Widget _buildTab(int index, Widget rootScreen) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) =>
          MaterialPageRoute(builder: (_) => rootScreen),
    );
  }

  void _onTap(int index) {
    if (index == _currentIndex) {
      _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final isFirstRouteInTab =
            !(await _navigatorKeys[_currentIndex].currentState!.maybePop());
        if (isFirstRouteInTab && _currentIndex != 0) {
          _onTap(0);
        } else if (isFirstRouteInTab) {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction == ScrollDirection.reverse) {
              if (_showBottomBar) setState(() => _showBottomBar = false);
            } else if (notification.direction == ScrollDirection.forward) {
              if (!_showBottomBar) setState(() => _showBottomBar = true);
            }
            return true;
          },
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildTab(0, const _DashboardContent()),
              _buildTab(
                1,
                FloorsScreen(
                  hostelId: AppState().hostelId,
                  hostelName: AppState().hostelName,
                ),
              ),
              _buildTab(2, const PendingPaymentsScreen()),
              _buildTab(3, const ReportingStudentsScreen()),
              _buildTab(4, const ProfileScreen()),
            ],
          ),
        ),
        bottomNavigationBar: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: _showBottomBar ? 70 : 0,
          child: Wrap(
            children: [
              BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _onTap,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: Colors.grey.shade500,
                selectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                showUnselectedLabels: true,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Dashboard'),
                  BottomNavigationBarItem(icon: Icon(Icons.apartment_outlined), label: 'Rooms'),
                  BottomNavigationBarItem(icon: Icon(Icons.credit_card_outlined), label: 'Payments'),
                  BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Students'),
                  BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The main content of the Dashboard tab.
class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  late Future<List<Map<String, dynamic>>> _activityFuture;

  @override
  void initState() {
    super.initState();
    _activityFuture = _loadRecentActivity();
  }

  // Format dynamic relative timestamps (e.g., '2m ago', '1h ago')
  String _relativeTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final difference = DateTime.now().difference(timestamp.toDate());
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    final d = timestamp.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  // Build the recent activity feed from this hostel's latest bookings and payments
  Future<List<Map<String, dynamic>>> _loadRecentActivity() async {
    final firestore = FirebaseFirestore.instance;
    final hostelId = AppState().hostelId;
    final List<Map<String, dynamic>> items = [];

    try {
      Query bookingsQuery = firestore.collection('bookings');
      if (hostelId.isNotEmpty) {
        bookingsQuery = bookingsQuery.where('hostelId', isEqualTo: hostelId);
      }
      final bookingsSnap = await bookingsQuery.limit(20).get();

      final bookingDocs = bookingsSnap.docs.toList()
        ..sort((a, b) {
          final ta = (a.data() as Map<String, dynamic>)['bookingDate'] as Timestamp?;
          final tb = (b.data() as Map<String, dynamic>)['bookingDate'] as Timestamp?;
          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;
          return tb.compareTo(ta);
        });

      for (final doc in bookingDocs.take(3)) {
        final data = doc.data() as Map<String, dynamic>;
        final status = (data['bookingStatus'] ?? 'pending').toString();
        final ref = doc.id.length > 6 ? doc.id.substring(doc.id.length - 6) : doc.id;
        items.add({
          'title': status == 'confirmed' ? 'Booking confirmed' : 'New booking',
          'subtitle': 'Booking $ref is currently $status.',
          'time': data['bookingDate'] as Timestamp?,
          'icon': Icons.calendar_today,
          'bgColor': const Color(0xFFDBEAFE),
          'iconColor': AppColors.primary,
        });
      }

      // Payments linked to those bookings (whereIn supports up to 10 ids)
      final bookingIds = bookingDocs.map((d) => d.id).take(10).toList();
      if (bookingIds.isNotEmpty) {
        final paymentsSnap = await firestore
            .collection('payments')
            .where('bookingId', whereIn: bookingIds)
            .get();
        for (final doc in paymentsSnap.docs) {
          final data = doc.data();
          final status = (data['paymentStatus'] ?? 'pending').toString();
          final bookingId = (data['bookingId'] ?? '').toString();
          final ref = bookingId.length > 6
              ? bookingId.substring(bookingId.length - 6)
              : bookingId;
          items.add({
            'title': status == 'confirmed' ? 'Payment confirmed' : 'Payment received',
            'subtitle': 'Payment for booking $ref is $status.',
            'time': data['paymentTime'] as Timestamp?,
            'icon': Icons.attach_money,
            'bgColor': const Color(0xFFFED7AA),
            'iconColor': AppColors.accent,
          });
        }
      }
    } catch (_) {
      // Show whatever activity resolved before the failure
    }

    items.sort((a, b) {
      final ta = a['time'] as Timestamp?;
      final tb = b['time'] as Timestamp?;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });
    return items.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good morning', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    const Text('Hostel Dashboard', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Manage rooms, payments, and student activity', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.black),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            ListenableBuilder(
              listenable: AppState(),
              builder: (context, child) {
                final state = AppState();
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.45,
                  children: [
                    _statCard('Total Rooms', state.totalRooms.toString(), Icons.apartment, const Color(0xFFDBEAFE), AppColors.primary),
                    _statCard('Available Rooms', state.availableRooms.toString(), Icons.check_circle, const Color(0xFFD1FAE5), const Color(0xFF10B981)),
                    _statCard('Occupied Rooms', state.occupiedRooms.toString(), Icons.meeting_room, const Color(0xFFDBEAFE), AppColors.primary),
                    _statCard('Pending Payment\nConfirmations', state.pendingPayments.toString(), Icons.receipt_long, const Color(0xFFFED7AA), AppColors.accent),
                    _statCard('Reserved Rooms', state.reservedRooms.toString(), Icons.bookmark, const Color(0xFFF3E8FF), const Color(0xFFA855F7)),
                    _statCard('Students Reporting\nToday', state.studentsReportingToday.toString(), Icons.group, const Color(0xFFCFFAFE), const Color(0xFF06B6D4)),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Tap to manage', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.15,
              children: [
                _quickAction(
                  'Manage Rooms',
                  Icons.apartment,
                  const Color(0xFFDBEAFE),
                  AppColors.primary,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FloorsScreen(
                        hostelId: AppState().hostelId,
                        hostelName: AppState().hostelName,
                      ),
                    ),
                  ),
                ),
                _quickAction('Payment\nConfirmations', Icons.credit_card, const Color(0xFFFED7AA), AppColors.accent, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PendingPaymentsScreen()))),
                _quickAction('Reporting\nStudents', Icons.person_add_alt, const Color(0xFFDBEAFE), AppColors.primary, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportingStudentsScreen()))),
                _quickAction('Hostel Details', Icons.info_outline, const Color(0xFFD1FAE5), const Color(0xFF10B981), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HostelDetailsScreen()))),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Latest updates', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _activityFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final activities = snapshot.data ?? [];
                if (activities.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No recent activity yet', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ),
                  );
                }

                return Column(
                  children: activities
                      .map((a) => _activityItem(
                            a['title'] as String,
                            _relativeTime(a['time'] as Timestamp?),
                            a['subtitle'] as String,
                            a['icon'] as IconData,
                            a['bgColor'] as Color,
                            a['iconColor'] as Color,
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String count, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.3))),
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 18)),
            ],
          ),
          Text(count, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _quickAction(String title, IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 22)),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _activityItem(String title, String time, String subtitle, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, size: 20, color: iconColor)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(time, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
