import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class StudentMainScreen extends StatefulWidget {
  const StudentMainScreen({super.key});

  @override
  State<StudentMainScreen> createState() =>
      _StudentMainScreenState();
}

class _StudentMainScreenState
    extends State<StudentMainScreen> {

  int currentIndex = 0;
  bool _showBottomBar = true;




final List<Widget> pages = [
  const StudentHomeScreen(),

  const Center(
    child: Text(
      "Search Screen",
      style: TextStyle(fontSize: 22),
    ),
  ),

  const Center(
    child: Text(
      "Booking Screen",
      style: TextStyle(fontSize: 22),
    ),
  ),

  const StudentNotificationsScreen(),

  const StudentProfileScreen(),
];




  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: NotificationListener<UserScrollNotification>(
  onNotification: (notification) {

    if (notification.direction == ScrollDirection.reverse) {
      if (_showBottomBar) {
        setState(() {
          _showBottomBar = false;
        });
      }
    }

    if (notification.direction == ScrollDirection.forward) {
      if (!_showBottomBar) {
        setState(() {
          _showBottomBar = true;
        });
      }
    }

    return true;
  },

  child: pages[currentIndex],
),

      bottomNavigationBar: AnimatedContainer(
  duration: const Duration(milliseconds: 250),
  height: _showBottomBar ? 70 : 0,
  child: Wrap(
    children: [
      BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        type: BottomNavigationBarType.fixed,

        selectedItemColor: Colors.blue,

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Search",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Booking",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Notifications",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
            ],
      ),
    ],
  ),
),
    );
  }
}