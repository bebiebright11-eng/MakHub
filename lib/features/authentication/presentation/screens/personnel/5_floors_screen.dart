import 'package:flutter/material.dart';
import '6_room_list_screen.dart';

class FloorsScreen extends StatelessWidget {
  final String hostelId;
  final String hostelName;

  const FloorsScreen({
    super.key,
    required this.hostelId,
    required this.hostelName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Floors', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _floorCard(context, 'Ground Floor', 8),
          _floorCard(context, 'First Floor', 6),
          _floorCard(context, 'Second Floor', 3),
          _floorCard(context, 'Third Floor', 1),
        ],
      ),
    );
  }

  Widget _floorCard(BuildContext context, String title, int availableRooms) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Available Rooms: $availableRooms', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          ElevatedButton(
           onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => RoomListScreen(
        hostelId: hostelId,
        floorId: title,
        floorName: title,
      ),
    ),
  );
},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Manage Rooms', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
