import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/constants/app_colors.dart';
import 'floor_selection_screen.dart';
import '../services/wishlist_service.dart';
import 'hostel_map_screen.dart';

class HostelDetailsScreen extends StatefulWidget {
  final String hostelId;
  const HostelDetailsScreen({super.key, required this.hostelId});

  @override
  State<HostelDetailsScreen> createState() => _HostelDetailsScreenState();
}

class _HostelDetailsScreenState extends State<HostelDetailsScreen> {
  late final Stream<DocumentSnapshot> _hostelStream;

  @override
  void initState() {
    super.initState();
    _hostelStream = FirebaseFirestore.instance
        .collection('hostels')
        .doc(widget.hostelId)
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
          final data = snapshot.data!.data() as Map<String, dynamic>;
          return _buildBottomButtons(context, data);
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
    final String rawType = (data['type'] ?? '').toString().toLowerCase();

    // Map raw type to display label, icon and colour
    final Map<String, dynamic> typeStyle = () {
      switch (rawType) {
        case 'girls':
          return {
            'label': 'Girls Only',
            'icon': Icons.female,
            'bg': const Color(0xFFFCE7F3),
            'color': const Color(0xFFDB2777),
          };
        case 'boys':
          return {
            'label': 'Boys Only',
            'icon': Icons.male,
            'bg': const Color(0xFFEFF6FF),
            'color': AppColors.primary,
          };
        case 'mixed':
          return {
            'label': 'Mixed',
            'icon': Icons.people,
            'bg': const Color(0xFFF0FDF4),
            'color': const Color(0xFF16A34A),
          };
        default:
          return {
            'label': rawType.isNotEmpty ? rawType : 'Unknown',
            'icon': Icons.apartment,
            'bg': Colors.grey.shade100,
            'color': Colors.grey.shade700,
          };
      }
    }();

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        // Gender / type tag — always shown prominently
        _buildTag(
          typeStyle['label'] as String,
          typeStyle['bg'] as Color,
          typeStyle['color'] as Color,
          typeStyle['icon'] as IconData,
        ),
        if ((data['distance'] ?? '').toString().isNotEmpty)
          _buildTag(
            '${data['distance']} from campus',
            const Color(0xFFEFF6FF),
            AppColors.primary,
            Icons.location_on,
          ),
        if ((data['walkingTime'] ?? '').toString().isNotEmpty)
          _buildTag(
            '${data['walkingTime']}',
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
        _infoRow(Icons.home, "Hostel Type", () {
          switch ((data['type'] ?? '').toString().toLowerCase()) {
            case 'boys':   return 'Boys Only';
            case 'girls':  return 'Girls Only';
            case 'mixed':  return 'Mixed (Boys & Girls)';
            default:       return data['type'] ?? '';
          }
        }()),
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
    final double avgRating =
        (data['averageRating'] as num?)?.toDouble() ?? 0.0;
    final int reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
    final String hostelName = (data['hostelName'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ─────────────────────────────────────────────
        const Text('Student Reviews',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // ── Rating summary card ────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Large star row
                  ...List.generate(
                    5,
                    (i) => Icon(
                      Icons.star,
                      size: 22,
                      color: i < avgRating.round()
                          ? Colors.amber
                          : Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Based on $reviewCount review${reviewCount == 1 ? '' : 's'}',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Review list (5 most recent) ────────────────────────────────
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('hostelId', isEqualTo: widget.hostelId)
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.rate_review_outlined,
                        size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    const Text(
                      'No reviews yet.',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Be the first verified resident to review this hostel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                ...docs.map((doc) => _DetailsReviewCard(
                      doc: doc,
                      hostelId: widget.hostelId,
                    )),

                // ── View All Reviews button ──────────────────────────
                if (reviewCount > 5) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _AllReviewsScreen(
                            hostelId: widget.hostelId,
                            hostelName: hostelName,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.chevron_right, size: 18),
                      label: const Text('View All Reviews'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  // Relative-date helper used by review cards on this screen
  static String _relativeDate(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) {
      final w = diff.inDays ~/ 7;
      return '$w week${w == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 365) {
      final m = diff.inDays ~/ 30;
      return '$m month${m == 1 ? '' : 's'} ago';
    }
    return '${d.day}/${d.month}/${d.year}';
  }

  Widget _buildBottomButtons(BuildContext context, Map<String, dynamic> data) {
    final double? lat = (data['latitude'] as num?)?.toDouble();
    final double? lng = (data['longitude'] as num?)?.toDouble();
    final bool hasLocation = lat != null && lng != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasLocation) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HostelMapScreen(
                      hostelName: data['hostelName'] ?? '',
                      latitude: lat,
                      longitude: lng,
                      address: data['address'] ?? data['location'] ?? '',
                      hostelData: data,
                    ),
                  ),
                ),
                icon: const Icon(Icons.map_outlined,
                    color: AppColors.primary, size: 18),
                label: const Text('View on Map',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentFloorSelectionScreen(
                          hostelId: widget.hostelId),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFDBEAFE)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.layers_outlined, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('View Floors',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold)),
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
                      builder: (context) => StudentFloorSelectionScreen(
                          hostelId: widget.hostelId),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: Colors.white),
                      SizedBox(width: 8),
                      Text('Book Now',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Review card used on the Hostel Details screen
// ─────────────────────────────────────────────────────────────────────────────

class _DetailsReviewCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final String hostelId;

  const _DetailsReviewCard({required this.doc, required this.hostelId});

  @override
  State<_DetailsReviewCard> createState() => _DetailsReviewCardState();
}

class _DetailsReviewCardState extends State<_DetailsReviewCard> {
  bool? _isVerified;
  String _reviewerName = 'Anonymous Student';

  @override
  void initState() {
    super.initState();
    _checkVerified();
    _resolveReviewerName();
  }

  /// Resolve the reviewer's real full name.
  ///
  /// Priority order:
  ///   1. `studentName` stored directly in the review document
  ///      (written by the new review flow).
  ///   2. Live lookup of `users/{userId}` in Firestore.
  ///   3. Fallback: "Anonymous Student".
  Future<void> _resolveReviewerName() async {
    final data = widget.doc.data() as Map<String, dynamic>;

    // 1 — check fields already stored on the document
    final stored =
        (data['studentName'] ?? data['userName'] ?? '').toString().trim();
    if (stored.isNotEmpty) {
      if (mounted) setState(() => _reviewerName = stored);
      return;
    }

    // 2 — live lookup via userId
    final userId = (data['userId'] ?? '').toString().trim();
    if (userId.isEmpty) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final name =
          (userDoc.data()?['fullName'] ?? userDoc.data()?['name'] ?? '')
              .toString()
              .trim();
      if (mounted && name.isNotEmpty) {
        setState(() => _reviewerName = name);
      }
    } catch (_) {
      // keep 'Anonymous Student'
    }
  }

  Future<void> _checkVerified() async {
    final data = widget.doc.data() as Map<String, dynamic>;
    final userId = (data['userId'] ?? '').toString();
    if (userId.isEmpty) {
      if (mounted) setState(() => _isVerified = false);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('studentId', isEqualTo: userId)
          .where('hostelId', isEqualTo: widget.hostelId)
          .where('bookingStatus', isEqualTo: 'confirmed')
          .limit(1)
          .get();
      if (mounted) setState(() => _isVerified = snap.docs.isNotEmpty);
    } catch (_) {
      if (mounted) setState(() => _isVerified = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final int rating = (data['rating'] as num?)?.toInt() ?? 0;
    final String comment =
        (data['review'] ?? data['comment'] ?? '').toString();
    final String timeAgo = _HostelDetailsScreenState._relativeDate(
        data['createdAt'] as Timestamp?);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + verified badge + date
          Row(
            children: [
              Text(
                _reviewerName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87),
              ),
              if (_isVerified == true) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified,
                          size: 10, color: Colors.green.shade600),
                      const SizedBox(width: 2),
                      Text(
                        'Verified Resident',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Text(
                timeAgo,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Stars
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                Icons.star,
                size: 14,
                color: i < rating ? Colors.amber : Colors.grey.shade300,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Comment
          Text(
            comment,
            style: const TextStyle(
                fontSize: 13, color: Colors.black87, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "View All Reviews" screen — streams every review for one hostel
// ─────────────────────────────────────────────────────────────────────────────

class _AllReviewsScreen extends StatelessWidget {
  final String hostelId;
  final String hostelName;

  const _AllReviewsScreen(
      {required this.hostelId, required this.hostelName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hostelName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black)),
            const Text('All Reviews',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('hostelId', isEqualTo: hostelId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
                child: Text('No reviews yet.',
                    style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) => _DetailsReviewCard(
              doc: docs[index],
              hostelId: hostelId,
            ),
          );
        },
      ),
    );
  }
}
