import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/algorithms/search_algorithm.dart';
import '/algorithms/recommendation_algorithm.dart';
import '/algorithms/popularity_service.dart';
import '/algorithms/popularity_recommendation_algorithm.dart';
import '/algorithms/trending_service.dart';
import '/algorithms/trending_recommendation_algorithm.dart';
import '/algorithms/budget_service.dart';
import '/algorithms/budget_recommendation_algorithm.dart';
import '/algorithms/location_service.dart';
import '/algorithms/location_recommendation_algorithm.dart';
import '/algorithms/recent_search_service.dart';
import '/algorithms/search_match_algorithm.dart';
import '/algorithms/discovery_service.dart';
import '/models/search_criteria.dart';
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

  // One independent ScrollController per horizontal section so each list
  // scrolls independently without interfering with the others.
  final ScrollController _recentSearchScrollController = ScrollController();
  final ScrollController _recommendedScrollController = ScrollController();
  final ScrollController _trendingScrollController = ScrollController();
  final ScrollController _budgetFriendlyScrollController = ScrollController();
  final ScrollController _kikumiScrollController = ScrollController();
  final ScrollController _mainGateScrollController = ScrollController();
  final ScrollController _kikoniScrollController = ScrollController();
  // ── Discovery section scroll controllers ─────────────────────────────────
  final ScrollController _moreWaitingScrollController = ScrollController();
  final ScrollController _newHostelsScrollController = ScrollController();

  final GlobalKey _searchBarKey = GlobalKey();
  OverlayEntry? _searchOverlay;

  // ── Popularity data cache ─────────────────────────────────────────────────
  Future<Map<String, HostelPopularityData>>? _popularityFuture;
  List<String> _lastPopularityHostelIds = [];

  // ── Trending data cache ───────────────────────────────────────────────────
  Future<Map<String, HostelTrendingData>>? _trendingFuture;
  List<String> _lastTrendingHostelIds = [];

  // ── Recent search cache ───────────────────────────────────────────────────
  // Loaded once on init and refreshed each time the student returns from a
  // search screen.  Null means the student has never searched.
  Future<SearchCriteria?>? _recentSearchFuture;

  // ── Student first name ────────────────────────────────────────────────────
  // Read from the user document so the discovery section heading is personal.
  String _studentFirstName = '';

  /// Reloads the recent search from Firestore.
  void _reloadRecentSearch() {
    setState(() {
      _recentSearchFuture = RecentSearchService.instance.load();
    });
  }

  @override
  void initState() {
    super.initState();
    // Load the student's most recent search immediately so the
    // "Based on your recent search" section appears on first frame.
    _recentSearchFuture = RecentSearchService.instance.load();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _preferencesStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
      _loadStudentFirstName(user.uid);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _chipsScrollController.dispose();
    _recentSearchScrollController.dispose();
    _recommendedScrollController.dispose();
    _trendingScrollController.dispose();
    _budgetFriendlyScrollController.dispose();
    _kikumiScrollController.dispose();
    _mainGateScrollController.dispose();
    _kikoniScrollController.dispose();
    _moreWaitingScrollController.dispose();
    _newHostelsScrollController.dispose();
    _removeSearchOverlay();
    super.dispose();
  }

  /// Reads the student's full name from Firestore and extracts the first word
  /// as the display first name used in the discovery section heading.
  Future<void> _loadStudentFirstName(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final fullName =
          (doc.data()?['fullName'] ?? '').toString().trim();
      if (fullName.isNotEmpty && mounted) {
        setState(() {
          _studentFirstName = fullName.split(' ').first;
        });
      }
    } catch (_) {
      // Non-fatal — heading falls back to the emoji-only variant.
    }
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

          // ── Trigger popularity/trending fetches when the hostel set changes ─
          final hostelIds = filteredDocs.map((d) => d.id).toList();
          final sortedIds = ([...hostelIds]..sort()).toString();
          if (sortedIds !=
              ([..._lastPopularityHostelIds]..sort()).toString()) {
            _lastPopularityHostelIds = hostelIds;
            _popularityFuture =
                PopularityService.instance.fetchPopularityData(hostelIds);
          }
          if (sortedIds !=
              ([..._lastTrendingHostelIds]..sort()).toString()) {
            _lastTrendingHostelIds = hostelIds;
            _trendingFuture =
                TrendingService.instance.fetchTrendingData(hostelIds);
          }

          // recommendHostels returns List<HostelRecommendation>; unwrap to docs
          final recommendedDocs =
              RecommendationAlgorithm.recommendHostels(
            hostels: filteredDocs,
            preferences: preferences,
          ).map((r) => r.doc).toList();

          // ── Discovery pools ────────────────────────────────────────────────
          // Recomputed on every build so the shuffle is fresh on each
          // dashboard open.  Zero extra Firestore reads — reuses trending data
          // already held in _trendingFuture via the FutureBuilder below.

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              SliverToBoxAdapter(child: _buildCategoryChips()),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),

              // ── Based on your recent search ──────────────────────────
              // Shown only when the student has previously performed a
              // search.  Uses SearchMatchAlgorithm to rank hostels in the
              // same order as the search results screen, but shows standard
              // HostelCards with no Match % badge.
              SliverToBoxAdapter(
                child: FutureBuilder<SearchCriteria?>(
                  future: _recentSearchFuture,
                  builder: (context, recentSnap) {
                    // Hide the section entirely while loading or when there
                    // is no recent search.
                    if (!recentSnap.hasData || recentSnap.data == null) {
                      return const SizedBox.shrink();
                    }

                    final recentCriteria = recentSnap.data!;

                    // Rank the current hostel set using SearchMatchAlgorithm
                    // so the order matches what the student saw on the
                    // results screen.
                    final recentDocs = SearchMatchAlgorithm.score(
                      hostels: filteredDocs,
                      criteria: recentCriteria,
                    ).map((r) => r.doc).toList();

                    if (recentDocs.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          "Based on your recent search",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HostelResultsScreen(
                                criteria: recentCriteria,
                              ),
                            ),
                          ).then((_) => _reloadRecentSearch()),
                        ),
                        const SizedBox(height: 12),
                        _buildHostelList(
                          recentDocs,
                          scrollController: _recentSearchScrollController,
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),

              // ── 😂 "More waiting for you!" discovery section ─────────
              // Shown only when the student has done at least one search.
              // Contains a random shuffle of low-exposure + new hostels.
              SliverToBoxAdapter(
                child: FutureBuilder<SearchCriteria?>(
                  future: _recentSearchFuture,
                  builder: (context, recentSnap) {
                    // Only show this section after the student has searched.
                    if (!recentSnap.hasData || recentSnap.data == null) {
                      return const SizedBox.shrink();
                    }
                    return FutureBuilder<Map<String, HostelTrendingData>>(
                      future: _trendingFuture,
                      builder: (context, trendSnap) {
                        final trendingData =
                            trendSnap.data ?? const {};
                        final discovery = DiscoveryService.instance.fetch(
                          allHostels: filteredDocs,
                          trendingData: trendingData,
                        );
                        // Combine low-exposure and new hostels, deduplicate,
                        // then shuffle the combined list for variety.
                        final seen = <String>{};
                        final combined = [
                          ...discovery.lowExposure,
                          ...discovery.newHostels,
                        ].where((d) => seen.add(d.id)).toList();

                        if (combined.isEmpty) return const SizedBox.shrink();

                        final heading = _studentFirstName.isNotEmpty
                            ? '😂 $_studentFirstName, there is more waiting for you!'
                            : '😂 There is more waiting for you!';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDiscoverySectionHeader(heading),
                            const SizedBox(height: 12),
                            _buildHostelList(
                              combined,
                              scrollController:
                                  _moreWaitingScrollController,
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Recommended For You ──────────────────────────────────
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  "Recommended For You",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Recommendation sections never show Match % — pass an
                      // empty SearchCriteria so no badge appears.
                      builder: (_) => const HostelResultsScreen(
                        criteria: SearchCriteria(),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 12)),
              // FutureBuilder wraps only this section so the popularity fetch
              // never blocks or re-renders the rest of the dashboard.
              SliverToBoxAdapter(
                child: FutureBuilder<Map<String, HostelPopularityData>>(
                  future: _popularityFuture,
                  builder: (context, popularitySnap) {
                    // While loading, show the preference-based order as a
                    // graceful fallback so the section is never empty.
                    final List<QueryDocumentSnapshot> baseDisplayDocs;

                    if (popularitySnap.connectionState == ConnectionState.done &&
                        popularitySnap.hasData) {
                      // Popularity data ready — rank by weighted score.
                      baseDisplayDocs = PopularityRecommendationAlgorithm.rank(
                        hostels: filteredDocs,
                        popularityData: popularitySnap.data!,
                      ).map((r) => r.doc).toList();
                    } else {
                      // Still loading — fall back to preference-based order.
                      baseDisplayDocs = recommendedDocs;
                    }

                    // ── Mix in ~2 discovery hostels ───────────────────
                    // Take the top 8 from the ranked list, then append up
                    // to 2 random low-exposure hostels not already shown.
                    final top8 = baseDisplayDocs.take(8).toList();
                    final excludeIds = top8.map((d) => d.id).toSet();

                    return FutureBuilder<Map<String, HostelTrendingData>>(
                      future: _trendingFuture,
                      builder: (context, trendSnap) {
                        final trendingData = trendSnap.data ?? const {};
                        final discovery = DiscoveryService.instance.fetch(
                          allHostels: filteredDocs,
                          trendingData: trendingData,
                        );
                        final mix =
                            DiscoveryService.instance.pickDiscoveryMix(
                          lowExposure: discovery.lowExposure,
                          excludeIds: excludeIds,
                          count: 2,
                        );

                        final displayDocs = [...top8, ...mix];

                        return _buildHostelList(
                          displayDocs,
                          scrollController: _recommendedScrollController,
                        );
                      },
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 24)),

              // ── Trending Now ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildSectionHeader("Trending Now"),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: FutureBuilder<Map<String, HostelTrendingData>>(
                  future: _trendingFuture,
                  builder: (context, trendingSnap) {
                    final List<QueryDocumentSnapshot> displayDocs;
                    if (trendingSnap.connectionState == ConnectionState.done &&
                        trendingSnap.hasData) {
                      displayDocs = TrendingRecommendationAlgorithm.rank(
                        hostels: filteredDocs,
                        trendingData: trendingSnap.data!,
                      ).map((r) => r.doc).toList();
                    } else {
                      displayDocs = recommendedDocs;
                    }
                    return _buildHostelList(
                      displayDocs,
                      scrollController: _trendingScrollController,
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 24)),

              // ── Budget Friendly ──────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildSectionHeader("Budget Friendly"),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: FutureBuilder<Map<String, HostelPopularityData>>(
                  future: _popularityFuture,
                  builder: (context, popularitySnap) {
                    final List<QueryDocumentSnapshot> displayDocs;
                    if (popularitySnap.connectionState == ConnectionState.done &&
                        popularitySnap.hasData) {
                      final budgetData = BudgetService.instance
                          .fromPopularityData(popularitySnap.data!);
                      displayDocs = BudgetRecommendationAlgorithm.rank(
                        hostels: filteredDocs,
                        budgetData: budgetData,
                      ).map((r) => r.doc).toList();
                    } else {
                      displayDocs = recommendedDocs;
                    }
                    return _buildHostelList(
                      displayDocs,
                      scrollController: _budgetFriendlyScrollController,
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 24)),

              // ── Location-based sections ──────────────────────────────
              for (final entry in [
                MapEntry("Kikumi",         _kikumiScrollController),
                MapEntry("Near Main Gate", _mainGateScrollController),
                MapEntry("Kikoni",         _kikoniScrollController),
              ])
                if (_hostelsForLocation(filteredDocs, entry.key).isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      "Hostels near ${entry.key}",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HostelResultsScreen(
                            criteria: SearchCriteria(location: entry.key),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: const SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: FutureBuilder<Map<String, HostelPopularityData>>(
                      future: _popularityFuture,
                      builder: (context, popularitySnap) {
                        final locationDocs =
                            _hostelsForLocation(filteredDocs, entry.key);
                        final List<QueryDocumentSnapshot> displayDocs;
                        if (popularitySnap.connectionState ==
                                ConnectionState.done &&
                            popularitySnap.hasData) {
                          final locationData = LocationService.instance
                              .fromPopularityData(popularitySnap.data!);
                          displayDocs = LocationRecommendationAlgorithm.rank(
                            hostels: locationDocs,
                            locationData: locationData,
                          ).map((r) => r.doc).toList();
                        } else {
                          displayDocs = locationDocs;
                        }
                        return _buildHostelList(
                          displayDocs,
                          scrollController: entry.value,
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(child: const SizedBox(height: 24)),
                ],
              SliverToBoxAdapter(child: const SizedBox(height: 30)),

              // ── 😊 "You're lucky! New hostels" discovery section ─────
              // Always shown (no search required).
              // Contains ONLY newly added hostels, randomly reshuffled
              // on every dashboard open.
              SliverToBoxAdapter(
                child: FutureBuilder<Map<String, HostelTrendingData>>(
                  future: _trendingFuture,
                  builder: (context, trendSnap) {
                    final trendingData = trendSnap.data ?? const {};
                    final discovery = DiscoveryService.instance.fetch(
                      allHostels: filteredDocs,
                      trendingData: trendingData,
                    );

                    if (discovery.newHostels.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDiscoverySectionHeader(
                          '😊 You\'re lucky! Be among the first to explore these new hostels.',
                        ),
                        const SizedBox(height: 12),
                        _buildHostelList(
                          discovery.newHostels,
                          scrollController: _newHostelsScrollController,
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),

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

  /// Discovery section header — no arrow button, wraps long headings,
  /// uses the same bold style as the regular header.
  Widget _buildDiscoverySectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

Widget _buildHostelList(
    List<QueryDocumentSnapshot> hostelDocs, {
    ScrollController? scrollController,
  }) {
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
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: hostelDocs.length,
        itemBuilder: (context, index) {
          final data = hostelDocs[index].data() as Map<String, dynamic>;
          final List<dynamic> photos = data['photos'] as List<dynamic>? ?? [];
          final String? imageUrl =
              photos.isNotEmpty ? photos.first?.toString() : null;
          final int? availableRooms =
              (data['availableRooms'] as num?)?.toInt();
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: HostelCard(
              hostelId: hostelDocs[index].id,
              name: data['hostelName'] ?? 'Unnamed Hostel',
              distance: data['location'] ?? '',
              singlePrice: data['singlePrice'] ?? '0',
              doublePrice: data['doublePrice'] ?? '0',
              rating: ((data['averageRating'] ?? 0.0) as num)
                  .toStringAsFixed(1),
              reviewCount:
                  (data['reviewCount'] as num?)?.toInt() ?? 0,
              distanceFromCampus: data['distance']?.toString(),
              imageUrl: imageUrl,
              availableRooms: availableRooms,
            ),
          );
        },
      ),
    );
  }

    
  

}

