import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/algorithms/search_algorithm.dart';
import '/algorithms/recommendation_algorithm.dart';
import 'guided_search_screen.dart';
import '../widgets/hostel_card.dart';
import 'describe_search_screen.dart';
import 'profile_screen.dart';
import 'preference_screen.dart';
import 'hostel_results_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}


class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final Stream<QuerySnapshot> _hostelsStream =
      FirebaseFirestore.instance.collection('hostels').snapshots();

  // Stream directly on the user's preferences document — auto-updates
  // whenever the student saves new preferences from any screen.
  Stream<DocumentSnapshot>? _preferencesStream;

  final String _searchText = "";
  String _selectedFilter = "";

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _chipsScrollController = ScrollController();
  final ScrollController _hostelsScrollController = ScrollController();

  final GlobalKey _searchBarKey = GlobalKey();
  OverlayEntry? _searchOverlay;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _preferencesStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _chipsScrollController.dispose();
    _hostelsScrollController.dispose();
    _removeSearchOverlay();
    super.dispose();
  }
  
@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _preferencesStream == null
          ? const Center(child: Text('Please log in to see recommendations'))
          : StreamBuilder<DocumentSnapshot>(
        stream: _preferencesStream,
        builder: (context, preferenceSnapshot) {
          if (preferenceSnapshot.hasError) {
            return const Center(child: Text('Failed to load preferences'));
          }

          if (!preferenceSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Extract preferences map — empty map if not set yet
          final raw = preferenceSnapshot.data!.data();
          final preferences = raw != null
              ? Map<String, dynamic>.from(
                  (raw as Map<String, dynamic>)['preferences'] ?? {})
              : <String, dynamic>{};

          return StreamBuilder<QuerySnapshot>(
            stream: _hostelsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Failed to load hostels'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No hostels available'));
              }

          final filteredDocs = _filterHostels(snapshot.data!.docs);

          // recommendHostels returns List<HostelRecommendation>; unwrap to docs for _buildHostelList
          final recommendedDocs =
              RecommendationAlgorithm.recommendHostels(
            hostels: filteredDocs,
            preferences: preferences,
          ).map((r) => r.doc).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              SliverToBoxAdapter(child: _buildCategoryChips()),
              SliverToBoxAdapter(child: const SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildSectionHeader("Recommended Hostels", onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HostelResultsScreen(preferences: preferences),
                  ),
                );
              })),
              SliverToBoxAdapter(child: const SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildHostelList(recommendedDocs)),
              SliverToBoxAdapter(child: const SizedBox(height: 12)),
              for (var location in ["Kikumi", "Near Main Gate", "Kikoni"])
                if (_hostelsForLocation(filteredDocs, location).isNotEmpty) ...[
                  SliverToBoxAdapter(child: _buildSectionHeader("Hostels near $location", onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HostelResultsScreen(preferences: {
                          ...preferences,
                          'preferredLocation': location,
                        }),
                      ),
                    );
                  })),
                  SliverToBoxAdapter(child: const SizedBox(height: 12)),
                  SliverToBoxAdapter(child: _buildHostelList(_hostelsForLocation(filteredDocs, location))),
                  SliverToBoxAdapter(child: const SizedBox(height: 20)),
                ],
              SliverToBoxAdapter(child: const SizedBox(height: 30)),
            ],
          );
        },
      );
    },
  ),
    );
  }
  List<QueryDocumentSnapshot> _filterHostels(
    List<QueryDocumentSnapshot> docs) {

    List<QueryDocumentSnapshot> searched =
        SearchAlgorithm.searchHostels(
      hostels: docs,
      query: _searchText,
    );

    return searched.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      final hostelType =
          (data['type'] ?? '').toString().toLowerCase();

      final singlePrice = (data['singlePrice'] ?? '')
          .toString()
          .replaceAll(RegExp(r'[^0-9]'), '');

      switch (_selectedFilter) {
        case "Girls":
          return hostelType == "girls";

        case "Boys":
          return hostelType == "boys";

        case "Single":
          return singlePrice.isNotEmpty;

        case "Budget":
          if (singlePrice.isEmpty) return false;
          return int.parse(singlePrice) <= 500000;

        default:
          return true;
      }
    }).toList();
  }

void _removeSearchOverlay() {
    _searchOverlay?.remove();
    _searchOverlay = null;
  }

  void _openSearchOptions() {
    // If already open, close it (toggle behaviour).
    if (_searchOverlay != null) {
      _removeSearchOverlay();
      return;
    }

    // Measure the search bar's position on screen.
    final RenderBox? box =
        _searchBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final Offset offset = box.localToGlobal(Offset.zero);
    final double barBottom = offset.dy + box.size.height;

    // Horizontal margins for the panel (12 px from each screen edge).
    const double hMargin = 12.0;
    // The panel aligns with the search bar's left edge, minus the margin
    // so it floats a touch wider, capped to screen width.
    final double screenWidth = MediaQuery.of(context).size.width;
    final double panelLeft = (offset.dx - hMargin).clamp(hMargin, screenWidth - hMargin);
    final double panelRight = hMargin;

    _searchOverlay = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            // ── barrier: dims the screen and dismisses on tap ──────────
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeSearchOverlay,
                child: Container(color: Colors.black.withValues(alpha: 0.25)),
              ),
            ),

            // ── the floating panel ─────────────────────────────────────
            Positioned(
              top: barBottom + 10,
              left: panelLeft,
              right: panelRight,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 14),
                        child: Text(
                          "How would you like to search?",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _searchOptionCard(
                        icon: Icons.edit_note,
                        title: "Describe what you want",
                        subtitle: "Type a sentence describing your ideal hostel",
                        onTap: () {
                          _removeSearchOverlay();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DescribeSearchScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _searchOptionCard(
                        icon: Icons.checklist,
                        title: "Guided search",
                        subtitle: "Answer a few quick questions",
                        onTap: () {
                          _removeSearchOverlay();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GuidedSearchScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_searchOverlay!);
  }

  Widget _searchOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Icon with tinted background
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Trailing chevron
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
  
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back,', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('Find your hostel', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentProfileScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline, color: Colors.white),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  key: _searchBarKey,
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: GestureDetector(
                    onTap: _openSearchOptions,
                    child: const AbsorbPointer(
                      child: TextField(
                        enabled: false,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Start your search",
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentPreferenceScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

// ===== UPDATED: chips are now tappable AND scroll horizontally =====
Widget _buildCategoryChips() {
  final categories = [
    {"label": "All", "icon": Icons.apps},
    {"label": "Budget", "icon": Icons.savings_outlined},
    {"label": "Girls", "icon": Icons.female},
    {"label": "Boys", "icon": Icons.male},
    {"label": "Single", "icon": Icons.bed},
    {"label": "Double", "icon": Icons.king_bed_outlined},
    {"label": "Mixed", "icon": Icons.people_outline},
    {"label": "Luxury", "icon": Icons.diamond_outlined},
    {"label": "Cheap", "icon": Icons.attach_money},
  ];

  return SizedBox(
    height: 58,
    child: ListView.builder(
      controller: _chipsScrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final label = categories[index]["label"] as String;
        final icon = categories[index]["icon"] as IconData;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildChip(label, icon),
        );
      },
    ),
  );
}




Widget _buildChip(String label, IconData icon) {
  final filterValue = label == "All" ? "" : label;
  final isActive = _selectedFilter == filterValue;

  return GestureDetector(
    onTap: () {
      setState(() {
        _selectedFilter = filterValue;
      });
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppColors.primary
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isActive ? Colors.white : Colors.black,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }


List<QueryDocumentSnapshot> _hostelsForLocation(
    List<QueryDocumentSnapshot> docs, String location) {
  final needle = location.toLowerCase();
  return docs.where((doc) {
    final data = doc.data() as Map<String, dynamic>;
    final hostelLocation = (data['location'] ?? '').toString().toLowerCase();
    return hostelLocation.contains(needle);
  }).toList();
}

Widget _buildHostelList(List<QueryDocumentSnapshot> hostelDocs) {
    if (hostelDocs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("No hostels found.", style: TextStyle(fontSize: 16)),
        ),
      );
    }

    return SizedBox(
      height: 260,
      child: ListView.builder(
        controller: _hostelsScrollController,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: hostelDocs.length,
        itemBuilder: (context, index) {
          final data = hostelDocs[index].data() as Map<String, dynamic>;
          return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: HostelCard(
                hostelId: hostelDocs[index].id,
                name: data['hostelName'] ?? 'Unnamed Hostel',
                distance: data['location'] ?? '',
                singlePrice: data['singlePrice'] ?? '0',
                doublePrice: data['doublePrice'] ?? '0',
                rating: ((data['averageRating'] ?? 0.0) as num).toStringAsFixed(1),
                distanceFromCampus: data['distance']?.toString(),
              ),
            );
        },
      ),
    );
  }

    
  

}

