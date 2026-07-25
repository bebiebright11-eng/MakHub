// ignore_for_file: file_names, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../state/app_state.dart';
import '5_floors_screen.dart';
import '9_payments_screen.dart';
import '11_reporting_screen.dart';
import '14_profile_screen.dart';
import '4_hostel_details_screen.dart';
import '13_notifications_screen.dart';

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
    return WillPopScope(
      onWillPop: () async {
        final isFirstRouteInTab =
            !(await _navigatorKeys[_currentIndex].currentState!.maybePop());
        if (isFirstRouteInTab && _currentIndex != 0) {
          _onTap(0);
          return false;
        }
        return isFirstRouteInTab;
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
                selectedItemColor: const Color(0xFF2563EB),
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
/// UNCHANGED from your original file — no edits needed here.
class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

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
                    _statCard('Total Rooms', state.totalRooms.toString(), Icons.apartment, const Color(0xFFDBEAFE), const Color(0xFF2563EB)),
                    _statCard('Available Rooms', state.availableRooms.toString(), Icons.check_circle, const Color(0xFFD1FAE5), const Color(0xFF10B981)),
                    _statCard('Occupied Rooms', state.occupiedRooms.toString(), Icons.meeting_room, const Color(0xFFDBEAFE), const Color(0xFF2563EB)),
                    _statCard('Pending Payment\nConfirmations', state.pendingPayments.toString(), Icons.receipt_long, const Color(0xFFFED7AA), const Color(0xFFF97316)),
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
                  const Color(0xFF2563EB),
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
                _quickAction('Payment\nConfirmations', Icons.credit_card, const Color(0xFFFED7AA), const Color(0xFFF97316), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PendingPaymentsScreen()))),
                _quickAction('Reporting\nStudents', Icons.person_add_alt, const Color(0xFFDBEAFE), const Color(0xFF2563EB), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportingStudentsScreen()))),
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
            _activityItem('Latest booking confirmed', '2m ago', 'Booking ID BK-2048 for Room 312 was created successfully.', Icons.calendar_today, const Color(0xFFDBEAFE), const Color(0xFF2563EB)),
            _activityItem('Latest payment confirmed', '18m ago', 'Payment for BK-2039 was verified and receipt generated.', Icons.attach_money, const Color(0xFFFED7AA), const Color(0xFFF97316)),
            _activityItem('Latest room update', '41m ago', 'Room 104 changed from Reserved to Occupied in real time.', Icons.bed, const Color(0xFFD1FAE5), const Color(0xFF10B981)),
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