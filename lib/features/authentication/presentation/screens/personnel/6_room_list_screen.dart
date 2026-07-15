import 'package:flutter/material.dart';
import '7_room_details_screen.dart';

class RoomListScreen extends StatelessWidget {
  final String floorName;
  const RoomListScreen({super.key, required this.floorName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(floorName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Room Number',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _filterChip('All', true),
                _filterChip('Available', false),
                _filterChip('Occupied', false),
                _filterChip('Reserved', false),
                _filterChip('Single', false),
                _filterChip('Double', false),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _roomCard(context, '101', 'Available', 'Single', '0/1'),
                _roomCard(context, '102', 'Occupied', 'Single', '1/1'),
                _roomCard(context, '103', 'Available', 'Double', '1/2'),
                _roomCard(context, '104', 'Reserved', 'Double', '0/2'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label),
        backgroundColor: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade100,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _roomCard(BuildContext context, String number, String status, String type, String occupancy) {
    Color statusColor;
    switch (status) {
      case 'Available': statusColor = Colors.green; break;
      case 'Occupied': statusColor = Colors.red; break;
      case 'Reserved': statusColor = Colors.orange; break;
      default: statusColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RoomDetailsScreen(roomNumber: number))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Room $number', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('$type • $occupancy', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
