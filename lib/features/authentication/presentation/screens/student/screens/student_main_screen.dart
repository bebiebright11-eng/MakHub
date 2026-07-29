import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:flutter/rendering.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'booking_information_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentMainScreen extends StatefulWidget {
  const StudentMainScreen({super.key});

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  int currentIndex = 0;
  bool _showBottomBar = true;
  late Future<QuerySnapshot> _bookingFuture;

  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(5, (_) => GlobalKey<NavigatorState>());

  @override
  void initState() {
    super.initState();
    _bookingFuture = _fetchBooking();
  }

  Future<QuerySnapshot> _fetchBooking() {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('studentId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .limit(1)
        .get();
  }

  Widget _bookingTab() {
    return FutureBuilder<QuerySnapshot>(
      future: _bookingFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load booking.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'You have not booked any room yet.',
              style: TextStyle(fontSize: 18),
            ),
          );
        }
        final booking = snapshot.data!.docs.first;
        final data = booking.data() as Map<String, dynamic>;
        return StudentBookingInformationScreen(
          bookingId: booking.id,
          hostelId: data['hostelId'],
          roomId: data['roomId'],
          floorId: data['floorId'],
        );
      },
    );
  }

  List<Widget> get _rootScreens => [
        const StudentHomeScreen(),
        const StudentSearchScreen(),
        _bookingTab(),
        const StudentNotificationsScreen(),
        const StudentMenuScreen(),
      ];

  Widget _buildTab(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) =>
          MaterialPageRoute(builder: (_) => _rootScreens[index]),
    );
  }

  void _onTap(int index) {
    if (index == currentIndex) {
      // Tapping the already-active tab pops it back to its root screen.
      _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final isFirstRouteInTab =
            !(await _navigatorKeys[currentIndex].currentState!.maybePop());
        if (isFirstRouteInTab && currentIndex != 0) {
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
            }
            if (notification.direction == ScrollDirection.forward) {
              if (!_showBottomBar) setState(() => _showBottomBar = true);
            }
            return true;
          },
          child: IndexedStack(
            index: currentIndex,
            children: List.generate(5, (i) => _buildTab(i)),
          ),
        ),
        bottomNavigationBar: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: _showBottomBar ? 70 : 0,
          child: Wrap(
            children: [
              BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: _onTap,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: AppColors.primary,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                  BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
                  BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Booking"),
                  BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notifications"),
                  BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}