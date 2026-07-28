import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import '/algorithms/availability_prediction_algorithm.dart';
import 'room_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentRoomListScreen extends StatefulWidget {
  final String hostelId;
  final String floorId;
  const StudentRoomListScreen({super.key, required this.hostelId, required this.floorId});

  @override
  State<StudentRoomListScreen> createState() => _StudentRoomListScreenState();
}
class _StudentRoomListScreenState extends State<StudentRoomListScreen> {

  late final Stream<QuerySnapshot> _roomsStream =
    FirebaseFirestore.instance
        .collection("hostels")
        .doc(widget.hostelId)
        .collection("floors")
        .doc(widget.floorId)
        .collection("rooms")
        .snapshots();

  @override
  Widget build(BuildContext context) {
    final hostelId = widget.hostelId;
    final floorId = widget.floorId;
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
            Text('Available Rooms', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.floorId, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _roomsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No rooms available'));
          }

          final roomDocs = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: roomDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'Unavailable';
              final prediction = AvailabilityPredictionAlgorithm.predict(data);
              return _buildRoomCard(
                context,
                'Room ${data['roomNumber'] ?? ''}',
                data['roomType'] ?? '',
                data['roomType'] ?? '',
                status,
                "${data['occupied'] ?? 0}/${data['capacity'] ?? 0}",
                status == "Available"
                    ? Colors.green
                    : status == "Reserved"
                        ? Colors.orange
                        : Colors.red,
                doc.id,
                prediction,
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, String roomNumber, String roomType, String bedType, String status, String occupancy, Color statusColor, String roomId, AvailabilityPrediction prediction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.bed_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(roomNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(roomType, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(occupancy, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Availability prediction badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _urgencyColor(prediction.urgency).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      prediction.urgency == RoomUrgency.fullyBooked
                          ? Icons.block
                          : prediction.urgency == RoomUrgency.highDemand
                              ? Icons.local_fire_department
                              : prediction.urgency == RoomUrgency.fillingUp
                                  ? Icons.timelapse
                                  : Icons.check_circle_outline,
                      size: 13,
                      color: _urgencyColor(prediction.urgency),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      prediction.sublabel,
                      style: TextStyle(
                        color: _urgencyColor(prediction.urgency),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSmallTag(bedType, Colors.grey.shade100, Colors.grey.shade700),
              const SizedBox(width: 8),
              _buildSmallTag(status, const Color(0xFFFFF7ED), AppColors.accent),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StudentRoomDetailsScreen(
    hostelId: widget.hostelId,
    floorId: widget.floorId,
    roomId: roomId,
))),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallTag(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Color _urgencyColor(RoomUrgency urgency) {
    switch (urgency) {
      case RoomUrgency.available:
        return Colors.green.shade600;
      case RoomUrgency.fillingUp:
        return Colors.orange.shade600;
      case RoomUrgency.highDemand:
        return Colors.red.shade600;
      case RoomUrgency.fullyBooked:
        return Colors.grey.shade600;
    }
  }

}


