import 'package:flutter/material.dart';
import 'admin_bookings_details_screen.dart';
import 'admin_notification_screen.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  String _selectedFilter = "Pending";

  final List<Map<String, String>> _bookings = [
    {
      "name": "Ama K.",
      "status": "Confirmed",
      "hostelRoom": "Sunrise Residence • Room 204",
      "date": "12 Aug 2026",
      "reference": "Hostel A - 204",
    },
    {
      "name": "Kwesi M.",
      "status": "Pending",
      "hostelRoom": "Sunrise Residence • Room 101",
      "date": "14 Aug 2026",
      "reference": "Hostel B - 101",
    },
    {
      "name": "Esi A.",
      "status": "Cancelled",
      "hostelRoom": "Sunrise Residence • Room 306",
      "date": "10 Aug 2026",
      "reference": "Hostel C - 306",
    },
    {
      "name": "Nana O.",
      "status": "Confirmed",
      "hostelRoom": "Sunrise Residence • Room 112",
      "date": "08 Aug 2026",
      "reference": "Hostel A - 112",
    },
  ];

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
              "Sunrise Residence • Hostel management",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            TextField(
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
              child: ListView.builder(
                itemCount: _bookings.length,
                itemBuilder: (context, index) {
                  final booking = _bookings[index];
                  return _bookingCard(
                    name: booking["name"]!,
                    status: booking["status"]!,
                    hostelRoom: booking["hostelRoom"]!,
                    date: booking["date"]!,
                    reference: booking["reference"]!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.blue,
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
          Navigator.pop(context);
          // Other tabs (Dashboard, Hostels, Notifications, Profile)
          // can be wired the same way once those screens are ready.
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.apartment), label: "Hostels"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Bookings"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notifications"),
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
            color: selected ? Colors.blue : Colors.grey.shade100,
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminBookingDetailsScreen(
                          studentName: name,
                          hostel: 'Sunrise Residence',
                          floor: 'first Floor',
                          roomNumber: reference,
                          roomType:'Double Room',
                          bookingStatus: status,
                        ),
                      ),
                    );
                  },
                  child: const Text("View"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Manage"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}