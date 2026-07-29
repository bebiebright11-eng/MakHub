import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/constants/app_colors.dart';
import 'floor_selection_screen.dart';
import '../services/wishlist_service.dart';
import 'reviews_screen.dart';

class HostelDetailsScreen extends StatefulWidget {
  final String hostelId;
  const HostelDetailsScreen({super.key, required this.hostelId});

  @override
  State<HostelDetailsScreen> createState() => _HostelDetailsScreenState();
}

class _HostelDetailsScreenState extends State<HostelDetailsScreen> {
  late final Stream<DocumentSnapshot> _hostelStream;
  late final Stream<QuerySnapshot> _reviewsStream;

  @override
  void initState() {
    super.initState();
    _hostelStream = FirebaseFirestore.instance
        .collection('hostels')
        .doc(widget.hostelId)
        .snapshots();
    _reviewsStream = FirebaseFirestore.instance
        .collection('reviews')
        .where('hostelId', isEqualTo: widget.hostelId)
        .snapshots();

    // Listen for the first valid hostel snapshot and record the view once.
    // We store the subscription so it can be cancelled after recording.
    _hostelStream
        .firstWhere((s) => s.exists)
        .then((snapshot) {
          if (!mounted) return;
          final data = snapshot.data() as Map<String, dynamic>?;
          if (data != null) {
            WishlistService.instance
                .addRecentlyViewed(widget.hostelId, data);
          }
        })
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _hostelStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Hostel not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, data),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(data),
                      const SizedBox(height: 16),
                      _buildTags(data),
                      const SizedBox(height: 24),
                      _buildPricingCards(data),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Description'),
const SizedBox(height: 8),
Text(
  data['description'] ?? '',
  style: const TextStyle(
    color: Colors.grey,
    height: 1.5,
    fontSize: 14,
  ),
),

const SizedBox(height: 28),

_buildSectionTitle('Hostel Information'),

const SizedBox(height: 16),

_buildHostelInformation(data),

const SizedBox(height: 28),

_buildSectionTitle('Facilities'),
                      const SizedBox(height: 16),
                      _buildFacilitiesGrid(data),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Hostel Rules'),
                      const SizedBox(height: 16),
                      _buildRules(data),
                      const SizedBox(height: 24),
                      _buildReviewsSection(data: data),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomSheet: StreamBuilder<DocumentSnapshot>(
        stream: _hostelStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
          return _buildBottomButtons(context);
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> data) {
    final photos = List<String>.from(data['photos'] ?? []);
    final imageUrl = photos.isNotEmpty ? photos[0] : 'https://via.placeholder.com/600x400';

    return Stack(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow, color: AppColors.primary, size: 32),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(icon: const Icon(Icons.favorite_border, color: Colors.black), onPressed: () {}),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(icon: const Icon(Icons.share_outlined, color: Colors.black), onPressed: () {}),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(photos.isNotEmpty ? photos.length : 1, (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index == 0 ? Colors.white : Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            )),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
            child: const Row(
              children: [
                Icon(Icons.videocam_outlined, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('Tour', style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection(Map<String, dynamic> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['hostelName'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(data['location'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.star, color: AppColors.primary, size: 14),
              const SizedBox(width: 4),
              Text('${data['securityRating'] ?? '-'}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTags(Map<String, dynamic> data) {
  return Row(
    children: [
      _buildTag(
        '${data['distance'] ?? ''} from campus',
        const Color(0xFFEFF6FF),
        AppColors.primary,
        Icons.location_on,
      ),
      const SizedBox(width: 12),
      _buildTag(
        '${data['walkingTime'] ?? ''}',
        const Color(0xFFF1F5F9),
        Colors.black,
        Icons.directions_walk,
      ),
    ],
  );
}

  Widget _buildTag(String label, Color bgColor, Color textColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

Widget _buildPricingCards(Map<String, dynamic> data) {
  return Row(
    children: [
      _buildPriceCard(
        'Single Room',
        data['singlePrice']?.toString() ?? '0',
      ),
      const SizedBox(width: 16),
      _buildPriceCard(
        'Double Room',
        data['doublePrice']?.toString() ?? '0',
      ),
    ],
  );
}

  Widget _buildPriceCard(String type, String price) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.king_bed_outlined, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text(type, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text('UGX $price', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('per semester', style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }


  Widget _buildHostelInformation(Map<String, dynamic> data) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        _infoRow(Icons.home, "Hostel Type", data['type'] ?? ""),
        _infoRow(Icons.location_on, "Distance", data['distance'] ?? ""),
        _infoRow(Icons.king_bed, "Single Room Size", data['singleRoomSize'] ?? ""),
        _infoRow(Icons.bed, "Double Room Size", data['doubleRoomSize'] ?? ""),
        _infoRow(Icons.directions_walk, "Walking Time", data['walkingTime'] ?? ""),
        _infoRow(Icons.atm, "ATM", data['atm'] ?? ""),
        _infoRow(Icons.local_hospital, "Hospital", data['hospital'] ?? ""),
        _infoRow(Icons.store, "Nearby Shops", data['shops'] ?? ""),
      ],
    ),
  );
}


Widget _infoRow(
  IconData icon,
  String title,
  String value,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildFacilitiesGrid(Map<String, dynamic> data) {
    final facilities = List<String>.from(data['facilities'] ?? []);
    final iconMap = {
  'WiFi': Icons.wifi,
  'DSTV': Icons.tv,
  'Reading Room': Icons.menu_book,
  'Shuttle': Icons.airport_shuttle,
  'Security': Icons.security,
  'Kitchen': Icons.restaurant,
  'Laundry': Icons.local_laundry_service,
  'Swimming Pool': Icons.pool,
  'Pool Table': Icons.sports_esports,
};

    if (facilities.isEmpty) {
      return const Text('No facilities listed', style: TextStyle(color: Colors.grey));
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: facilities.map((f) => _facilityItem(f, iconMap[f] ?? Icons.check_circle_outline)).toList(),
    );
  }

  Widget _facilityItem(String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRules(Map<String, dynamic> data) {
    final rules = [
  "No smoking inside the hostel.",
  "Visitors are allowed from 8:00 AM to 8:00 PM.",
  "Keep noise to a minimum after 10:00 PM.",
  "Maintain cleanliness in shared areas.",
  "Report damaged property to hostel management.",
];
    if (rules.isEmpty) {
      return const Text('No rules listed', style: TextStyle(color: Colors.grey));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: rules.asMap().entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(bottom: entry.key == rules.length - 1 ? 0 : 12),
            child: _ruleRow(Icons.info_outline, entry.value, AppColors.primary),
          );
        }).toList(),
      ),
    );
  }

  Widget _ruleRow(IconData icon, String rule, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 12),
        Expanded(child: Text(rule, style: TextStyle(color: Colors.grey.shade800, fontSize: 14))),
      ],
    );
  }

  Widget _buildReviewsSection({required Map<String, dynamic> data}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Student Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentReviewsScreen(
                    hostelId: widget.hostelId,
                    hostelName: data['hostelName'] ?? '',
                  ),
                ),
              ),
              child: const Text('See all', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _reviewsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('No reviews yet', style: TextStyle(color: Colors.grey));
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final review = doc.data() as Map<String, dynamic>;
                final rating = (review['rating'] ?? 0).toInt();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(backgroundColor: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                children: List.generate(5, (i) => Icon(
                                  Icons.star,
                                  color: i < rating ? Colors.orange : Colors.grey.shade300,
                                  size: 14,
                                )),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          review['review'] ?? '',
                          style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentFloorSelectionScreen(hostelId: widget.hostelId),
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFDBEAFE)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.layers_outlined, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('View Floors', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentFloorSelectionScreen(hostelId: widget.hostelId),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Book Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


}