import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MakHub Admin"),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              child: Icon(Icons.person),
            ),
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Welcome, Bright!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Here's what's happening today at MakHub.",
            ),

            const SizedBox(height: 30),

            const Text(
              "TODAY'S SUMMARY",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                _summaryCard(
  "12",
  "Total Hostels",
  Icons.apartment,
  Colors.blue,
),

const SizedBox(width: 10),

_summaryCard(
  "45",
  "Available",
  Icons.meeting_room,
  Colors.green,
),

const SizedBox(width: 10),

_summaryCard(
  "158",
  "Occupied",
  Icons.people,
  Colors.orange,
),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "QUICK ACTIONS",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: const [
                _ActionButton("Add Hostel", Icons.add),
                _ActionButton("Add Staff", Icons.group),
                _ActionButton("Bookings", Icons.list),
                _ActionButton("Reports", Icons.bar_chart),
                _ActionButton("Payments", Icons.payment),
                _ActionButton("View All", Icons.arrow_forward),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "RECENT ACTIVITIES",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            const ListTile(
              leading: Icon(Icons.book),
              title: Text("New Booking"),
              subtitle: Text("Sarah Jones - Dream World Room 4"),
              trailing: Text("2 mins ago"),
            ),

            const Divider(),

            const ListTile(
              leading: Icon(Icons.payment),
              title: Text("Payment Received"),
              subtitle: Text("UGX 450,000 - Victoria Hostel"),
              trailing: Text("15 mins ago"),
            ),

const Divider(),

const ListTile(
  leading: Icon(Icons.apartment),
  title: Text("Hostel Updated"),
  subtitle: Text("Nexus Hostel facility list changed"),
  trailing: Text("1 hour ago"),
),

const Divider(),

const ListTile(
  leading: Icon(Icons.person_add),
  title: Text("Staff Added"),
  subtitle: Text("Paul M. assigned to Bataka"),
  trailing: Text("3 hours ago"),
),

            const Divider(),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.shield,
                    color: Colors.green,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "System Health Normal\nAll servers operational.",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
  currentIndex: 0,
  selectedItemColor: Colors.blue,
  unselectedItemColor: Colors.grey,
  type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment),
            label: "Hostels",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Bookings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: "Payments",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  static Widget _summaryCard(
  String value,
  String label,
  IconData icon,
  Color iconColor,
) {
  return Expanded(
    child: Container(
      height: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.15),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    ),
  );
}
}

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ActionButton(
    this.title,
    this.icon,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}