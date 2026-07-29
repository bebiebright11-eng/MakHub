import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'room_list_screen.dart';

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
        title: Text('$hostelName - Floors',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("hostels")
            .doc(hostelId)
            .collection("floors")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No floors found."));
          }

          final floorDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: floorDocs.length,
            itemBuilder: (context, index) {
              final floor = floorDocs[index];
              final data = floor.data() as Map<String, dynamic>;

              return _floorCard(
                context,
                floor.id,
                data['floorName'] ?? 'Unnamed Floor',
                data['availableRooms'] ?? 0,
              );
            },
          );
        },
      ),
    );
  }

  Widget _floorCard(
      BuildContext context, String floorId, String title, int availableRooms) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Available Rooms: $availableRooms',
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoomListScreen(
                    hostelId: hostelId,
                    floorId: floorId,
                    floorName: title,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                const Text('Manage Rooms', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
