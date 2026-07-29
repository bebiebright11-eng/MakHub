import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'booking_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentRoomDetailsScreen extends StatefulWidget {
  final String hostelId;
  final String floorId;
  final String roomId;

  const StudentRoomDetailsScreen({
    super.key,
    required this.hostelId,
    required this.floorId,
    required this.roomId,
  });

  @override
  State<StudentRoomDetailsScreen> createState() => _StudentRoomDetailsScreenState();
}

class _StudentRoomDetailsScreenState extends State<StudentRoomDetailsScreen> {
late final Stream<DocumentSnapshot> _roomStream =
    FirebaseFirestore.instance
        .collection("hostels")
        .doc(widget.hostelId)
        .collection("floors")
        .doc(widget.floorId)
        .collection("rooms")
        .doc(widget.roomId)
        .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _roomStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Room not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final availability = data['status'] ?? 'Unavailable';

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, data),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Room ${data['roomNumber'] ?? ''} • ${data['roomType'] ?? ''}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(widget.hostelId, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                            child: Text(availability, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildRoomDetails(data),
                      const SizedBox(height: 32),
                      const Text('Room Highlights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('Comfort, privacy, and convenience.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 16),
                      _buildHighlightsGrid(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomSheet: _buildBottomAction(context),
    );

  }

  

  Widget _buildHeader(BuildContext context, Map<String, dynamic> data) {
    final roomPhoto = data['imageUrl']?.toString() ?? '';
    return Stack(
      children: [
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            image: roomPhoto.isNotEmpty
                ? DecorationImage(image: NetworkImage(roomPhoto), fit: BoxFit.cover)
                : null,
          ),
          child: roomPhoto.isEmpty
              ? const Center(child: Icon(Icons.bed, size: 80, color: Colors.grey))
              : null,
        ),
        Positioned(
          top: 50,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(backgroundColor: Colors.white, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context))),
              Row(
                children: [
                  CircleAvatar(backgroundColor: Colors.white, child: IconButton(icon: const Icon(Icons.favorite_border, color: Colors.black), onPressed: () {})),
                  const SizedBox(width: 12),
                  CircleAvatar(backgroundColor: Colors.white, child: IconButton(icon: const Icon(Icons.share_outlined, color: Colors.black), onPressed: () {})),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Text('Available', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomDetails(Map<String, dynamic> data) {

  Map<String, dynamic> features = {};

if (data['features'] is Map<String, dynamic>) {
  features = data['features'] as Map<String, dynamic>;
}

  final selfContained =
      features['Self-contained'] == true ? 'Yes' : 'No';

  final nearBalcony =
      features['Near Balcony'] == true ? 'Yes' : 'No';

  final bathroomDistance =
      features['Bathroom Distance']?.toString() ?? 'N/A';

  final windowView =
      features['Window View'] == true ? 'Yes' : 'No';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Room Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('Key information about this room before booking.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
          _detailRow(Icons.bathroom_outlined, 'Self-contained', 'Private bathroom included', selfContained),
          const SizedBox(height: 16),
          _detailRow(Icons.directions_walk, 'Bathroom Distance', 'From room entrance', bathroomDistance),
          const SizedBox(height: 16),
          _detailRow(Icons.balcony_outlined, 'Near Balcony', 'Natural light and airflow', nearBalcony),
          const SizedBox(height: 16),
          _detailRow(Icons.window_outlined, 'Window View', 'Facing the courtyard', windowView),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String subtitle, String value) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColors.primary, size: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildHighlightsGrid() {
    return Row(
      children: [
        _highlightCard(Icons.wifi, 'Wi-Fi Ready', 'Stable connection for study and streaming.'),
        const SizedBox(width: 16),
        _highlightCard(Icons.laptop_chromebook, 'Study Space', 'Desk-friendly layout with good lighting.'),
      ],
    );
  }

  Widget _highlightCard(IconData icon, String title, String body) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StudentBookingDetailsScreen(
    hostelId: widget.hostelId,
    floorId: widget.floorId,
    roomId: widget.roomId,
))),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: const Text('Book Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

}
