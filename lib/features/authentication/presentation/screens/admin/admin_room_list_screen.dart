import 'package:flutter/material.dart';
import 'admin_edit_room_screen.dart'; 

class AdminRoomListScreen extends StatefulWidget {
  const AdminRoomListScreen({super.key});

  @override
  State<AdminRoomListScreen> createState() => _AdminRoomListScreenState();
}

class _AdminRoomListScreenState extends State<AdminRoomListScreen> {
  String _selectedFilter = "Available";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rooms"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sunrise Residence • First Floor",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            TextField(
              decoration: InputDecoration(
                hintText: "Search rooms...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _filterTab("Available"),
                const SizedBox(width: 10),
                _filterTab("Occupied"),
                const SizedBox(width: 10),
                _filterTab("Maintenance"),
              ],
            ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                     _tappableRoomCard(context, "101", "Available", "Single", "1/1"),
                  _tappableRoomCard(context, "102", "Occupied", "Double", "2/2"),
                  _tappableRoomCard(context, "103", "Available", "Double", "1/2"),
                  _tappableRoomCard(context, "104", "Available", "Single", "1/1"),
                  _tappableRoomCard(context, "105", "Occupied", "Double", "2/2"),
                  _tappableRoomCard(context, "106", "Reserved", "Double", "1/2"),
                    ],
                  ),
                ),
              ],
            ),
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
    Widget _tappableRoomCard(
    BuildContext context,
    String number,
    String status,
    String type,
    String occupancy,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminEditRoomScreen(roomNumber: number),
          ),
        );
      },
      child: _roomCard(
        number: number,
        status: status,
        type: type,
        occupancy: occupancy,
      ),
    );
  }
    Widget _roomCard({
    required String number,
    required String status,
    required String type,
    required String occupancy,
  }) {
    Color statusColor;
    if (status == "Available") {
      statusColor = Colors.green;
    } else if (status == "Occupied") {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(12),
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
                "Room $number",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text("Type", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          Text(type, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          Text("Occupancy", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          Text(occupancy, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

}