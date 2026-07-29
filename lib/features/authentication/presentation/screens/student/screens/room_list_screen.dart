import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'room_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentRoomListScreen extends StatefulWidget {
  final String hostelId;
  final String floorId;

  const StudentRoomListScreen({
    super.key,
    required this.hostelId,
    required this.floorId,
  });

  @override
  State<StudentRoomListScreen> createState() => _StudentRoomListScreenState();
}

class _StudentRoomListScreenState extends State<StudentRoomListScreen> {
  // Mirror the admin filter tabs — student sees same status groupings
  String _selectedFilter = "Available";

  late final Stream<QuerySnapshot> _roomsStream = FirebaseFirestore.instance
      .collection("hostels")
      .doc(widget.hostelId)
      .collection("floors")
      .doc(widget.floorId)
      .collection("rooms")
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Rooms',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.floorId,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Filter tabs — same three as admin ─────────────────────────
            Row(
              children: [
                _filterTab("Available"),
                const SizedBox(width: 10),
                _filterTab("Occupied"),
                const SizedBox(width: 10),
                _filterTab("Maintenance"),
              ],
            ),
            const SizedBox(height: 16),

            // ── Grid ──────────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _roomsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No rooms available'));
                  }

                  // Filter by selected status
                  final rooms = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['status'] == _selectedFilter;
                  }).toList();

                  if (rooms.isEmpty) {
                    return Center(
                      child: Text(
                        'No $_selectedFilter rooms',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  // Same ascending sort as admin: baseNumber, fallback to
                  // parsing the numeric part of roomNumber string.
                  rooms.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;

                    int aNum = aData['baseNumber'] ?? 0;
                    int bNum = bData['baseNumber'] ?? 0;

                    if (aNum == 0 && aData['roomNumber'] != null) {
                      aNum = int.tryParse(
                              RegExp(r'\d+')
                                      .firstMatch(aData['roomNumber'].toString())
                                      ?.group(0) ??
                                  '0') ??
                          0;
                    }
                    if (bNum == 0 && bData['roomNumber'] != null) {
                      bNum = int.tryParse(
                              RegExp(r'\d+')
                                      .firstMatch(bData['roomNumber'].toString())
                                      ?.group(0) ??
                                  '0') ??
                          0;
                    }

                    return aNum.compareTo(bNum);
                  });

                  // 2-column grid — same delegate as admin
                  return GridView.builder(
                    itemCount: rooms.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                    itemBuilder: (context, index) {
                      final doc = rooms[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return _tappableRoomCard(
                        context,
                        roomId: doc.id,
                        number: (data['roomNumber'] ?? '').toString(),
                        status: (data['status'] ?? 'Unavailable').toString(),
                        type: (data['roomType'] ?? '').toString(),
                        occupancy:
                            "${data['occupied'] ?? 0}/${data['capacity'] ?? 0}",
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

  // ── Filter tab — identical style to admin ────────────────────────────────
  Widget _filterTab(String label) {
    final selected = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = label),
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

  // ── Tappable card — navigates to StudentRoomDetailsScreen ────────────────
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
          builder: (_) => StudentRoomDetailsScreen(
            hostelId: widget.hostelId,
            floorId: widget.floorId,
            roomId: roomId,
          ),
        ),
      ),
      child: _roomCard(
        number: number,
        status: status,
        type: type,
        occupancy: occupancy,
      ),
    );
  }

  // ── Card widget — exact same style as admin _roomCard ────────────────────
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
              Expanded(
                child: Text(
                  "Room $number",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            "Type",
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          Text(
            type,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            "Occupancy",
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          Text(
            occupancy,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
