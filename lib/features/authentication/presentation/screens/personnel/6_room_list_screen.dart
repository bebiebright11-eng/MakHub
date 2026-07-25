import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '7_room_details_screen.dart';

class RoomListScreen extends StatefulWidget {
  final String hostelId;
  final String floorId;
  final String floorName;

  const RoomListScreen({
    super.key,
    required this.hostelId,
    required this.floorId,
    required this.floorName,
  });

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.floorName, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                _filterChip('All'),
                _filterChip('Available'),
                _filterChip('Occupied'),
                _filterChip('Reserved'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('hostels')
                  .doc(widget.hostelId)
                  .collection('floors')
                  .doc(widget.floorId)
                  .collection('rooms')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No rooms found on this floor.'));
                }

                var roomDocs = snapshot.data!.docs;

                // Sort rooms in memory to ensure they appear in ascending order
                roomDocs.sort((a, b) {
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

                // Apply the selected filter chip
                if (_selectedFilter != 'All') {
                  roomDocs = roomDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['status'] == _selectedFilter;
                  }).toList();
                }

                if (roomDocs.isEmpty) {
                  return Center(child: Text('No $_selectedFilter rooms on this floor.'));
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: roomDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _roomCard(
                      context,
                      roomId: doc.id,
                      number: data['roomNumber'] ?? '',
                      status: data['status'] ?? 'Unknown',
                      type: data['roomType'] ?? '',
                      capacity: data['capacity'] ?? 0,
                      occupied: data['occupied'] ?? 0,
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = label),
        child: Chip(
          label: Text(label),
          backgroundColor: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade100,
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  Widget _roomCard(
    BuildContext context, {
    required String roomId,
    required String number,
    required String status,
    required String type,
    required int capacity,
    required int occupied,
  }) {
    Color statusColor;
    switch (status) {
      case 'Available': statusColor = Colors.green; break;
      case 'Occupied': statusColor = Colors.red; break;
      case 'Reserved': statusColor = Colors.orange; break;
      default: statusColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoomDetailsScreen(
            hostelId: widget.hostelId,
            floorId: widget.floorId,
            roomId: roomId,
          ),
        ),
      ),
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
                Text('$type • $occupied/$capacity', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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