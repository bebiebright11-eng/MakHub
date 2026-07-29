import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'admin_room_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

class AdminRoomListScreen extends StatefulWidget {
  final String hostelId;
  final String floorId;
  final String hostelName;
  final String floorName;

  const AdminRoomListScreen({
    super.key,
    required this.hostelId,
    required this.floorId,
    required this.hostelName,
    required this.floorName,
  });

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
            Text(
              "${widget.hostelName} • ${widget.floorName}",
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
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
  child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("hostels")
        .doc(widget.hostelId)
        .collection("floors")
        .doc(widget.floorId)
        .collection("rooms")
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(
          child: Text("No rooms found"),
        );
      }

      final rooms = snapshot.data!.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['status'] == _selectedFilter;
      }).toList();
      
      // Sort rooms in memory to ensure they appear in ascending order
      rooms.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        
        int aNum = aData['baseNumber'] ?? 0;
        int bNum = bData['baseNumber'] ?? 0;

        // Fallback: parse number from roomNumber string if baseNumber is 0
        if (aNum == 0 && aData['roomNumber'] != null) {
          aNum = int.tryParse(RegExp(r'\d+').firstMatch(aData['roomNumber'])?.group(0) ?? '0') ?? 0;
        }
        if (bNum == 0 && bData['roomNumber'] != null) {
          bNum = int.tryParse(RegExp(r'\d+').firstMatch(bData['roomNumber'])?.group(0) ?? '0') ?? 0;
        }

        return aNum.compareTo(bNum);
      });

      return GridView.builder(
        itemCount: rooms.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemBuilder: (context, index) {
          final room = rooms[index];

final roomId = room.id;
final roomNumber = room["roomNumber"];
final roomType = room["roomType"];
final status = room["status"];
final occupied = room["occupied"];
final capacity = room["capacity"];

return _tappableRoomCard(
  context,
  roomId,
  roomNumber,
  status,
  roomType,
  "$occupied/$capacity",
);
        },
      );
    },
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
              color: selected ? AppColors.primary : Colors.grey.shade100,
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
  String roomId,
  String number,
  String status,
  String type,
  String occupancy,
)
  
   {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
           builder: (context) => AdminRoomDetailsScreen(
  hostelId: widget.hostelId,
  floorId: widget.floorId,
  roomId: roomId,
  roomNumber: number,
),
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
                  color: statusColor.withValues(alpha: 0.1),
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