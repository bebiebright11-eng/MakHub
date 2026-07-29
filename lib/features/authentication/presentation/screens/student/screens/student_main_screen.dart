import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'booking_tab_router.dart';
import 'settings_screen.dart';
import 'wishlist_screen.dart';

class StudentMainScreen extends StatefulWidget {
  const StudentMainScreen({super.key});

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  int currentIndex = 0;
  bool _showBottomBar = true;

  // One Navigator per tab so a push inside any tab stays inside
  // that tab's own stack, instead of escaping the Scaffold below.
  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(5, (_) => GlobalKey<NavigatorState>());

  List<Widget> get _rootScreens => [
        const StudentHomeScreen(),
        const WishlistScreen(),
        const BookingTabRouter(),
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
    return WillPopScope(
      onWillPop: () async {
        final isFirstRouteInTab =
            !(await _navigatorKeys[currentIndex].currentState!.maybePop());
        if (isFirstRouteInTab && currentIndex != 0) {
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
                selectedItemColor: Colors.blue,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                  BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Wishlist"),
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