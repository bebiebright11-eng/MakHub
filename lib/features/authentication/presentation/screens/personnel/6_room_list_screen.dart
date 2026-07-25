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
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.floorName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
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
            const SizedBox(height: 16),
            Row(
              children: [
                _filterTab('All'),
                const SizedBox(width: 8),
                _filterTab('Available'),
                const SizedBox(width: 8),
                _filterTab('Occupied'),
                const SizedBox(width: 8),
                _filterTab('Reserved'),
              ],
            ),
            const SizedBox(height: 16),
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
                      aNum = int.tryParse(RegExp(r'\d+').firstMatch(aData['roomNumber'].toString())?.group(0) ?? '0') ?? 0;
                    }
                    if (bNum == 0 && bData['roomNumber'] != null) {
                      bNum = int.tryParse(RegExp(r'\d+').firstMatch(bData['roomNumber'].toString())?.group(0) ?? '0') ?? 0;
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

                  if (_searchQuery.isNotEmpty) {
                    roomDocs = roomDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final number = (data['roomNumber'] ?? '').toString().toLowerCase();
                      return number.contains(_searchQuery.toLowerCase());
                    }).toList();
                  }

                  if (roomDocs.isEmpty) {
                    return const Center(child: Text('No rooms match this search/filter.'));
                  }

                  return GridView.builder(
                    itemCount: roomDocs.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                    itemBuilder: (context, index) {
                      final doc = roomDocs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return _tappableRoomCard(
                        context,
                        roomId: doc.id,
                        number: (data['roomNumber'] ?? '').toString(),
                        status: data['status'] ?? 'Unknown',
                        type: data['roomType'] ?? '',
                        occupancy: '${data['occupied'] ?? 0}/${data['capacity'] ?? 0}',
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
        onTap: () => setState(() => _selectedFilter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2563EB) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tappableRoomCard(
    BuildContext context, {
    required String roomId,
    required String number,
    required String status,
    required String type,
    required String occupancy,
  }) {
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
      child: _roomCard(number: number, status: status, type: type, occupancy: occupancy),
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
              Text("Room $number", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
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
