import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'hostel_details_screen.dart';
import 'package:flutter/gestures.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'active_booking_screen.dart';
import '/algorithms/search_algorithm.dart';
import '/algorithms/recommendation_algorithm.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}


class _StudentHomeScreenState extends State<StudentHomeScreen> {
    final Stream<QuerySnapshot> _hostelsStream =
    FirebaseFirestore.instance
        .collection('hostels')
        .snapshots();
    String _searchText = "";
    String _selectedFilter = "";
final TextEditingController _searchController =
    TextEditingController();

    final ScrollController _chipsScrollController = ScrollController();
final ScrollController _hostelsScrollController = ScrollController();


@override
void dispose() {
  _searchController.dispose();
  _chipsScrollController.dispose();
  _hostelsScrollController.dispose();
  super.dispose();
}
  
@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadPreferences(),
        builder: (context, preferenceSnapshot) {

          if (!preferenceSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final preferences = preferenceSnapshot.data!;

          return StreamBuilder<QuerySnapshot>(
            stream: _hostelsStream,
            builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hostels available'));
          }

          final filteredDocs = _filterHostels(snapshot.data!.docs);

          final recommendedDocs =
              RecommendationAlgorithm.recommendHostels(
            hostels: filteredDocs,
            preferences: preferences,
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              SliverToBoxAdapter(child: _buildCategoryChips()),
              SliverToBoxAdapter(child: const SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildSectionHeader("Recommended Hostels")),
              SliverToBoxAdapter(child: const SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildHostelList(recommendedDocs)),
              SliverToBoxAdapter(child: const SizedBox(height: 12)),
              for (var location in ["Kikumi", "Near Main Gate", "Kikoni"])
                if (_hostelsForLocation(filteredDocs, location).isNotEmpty) ...[
                  SliverToBoxAdapter(child: _buildSectionHeader("Hostels near $location")),
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }
  Future<void> _goToActiveBooking(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You're not logged in.")),
    );
    return;
  }

  try {
    final bookingQuery = await FirebaseFirestore.instance
        .collection('bookings')
        .where('studentId', isEqualTo: user.uid)
        .orderBy('bookingDate', descending: true)
        .limit(1)
        .get();

    if (bookingQuery.docs.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You don't have any bookings yet."),
        ),
      );
      return;
    }

    final bookingDoc = bookingQuery.docs.first;

    final bookingData = bookingDoc.data();

    final hostelId = bookingData['hostelId'] ?? '';
    final roomId = bookingData['roomId'] ?? '';
    final floorId = bookingData['floorId'] ?? '';

    final hostelDoc = await FirebaseFirestore.instance
        .collection('hostels')
        .doc(hostelId)
        .get();

    final hostelName =
        hostelDoc.data()?['hostelName'] ?? 'Unknown Hostel';

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentActiveBookingScreen(
          bookingId: bookingDoc.id,
          hostelName: hostelName,
          roomNumber: roomId,
          bookingStatus:
              bookingData['bookingStatus'] ?? 'Pending',
          hostelId: hostelId,
          roomId: roomId,  
          floorId: floorId,   
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Something went wrong: $e"),
      ),
    );
  }
}
  Future<Map<String, dynamic>> _loadPreferences() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return {};
  }

  final doc = await FirebaseFirestore.instance
      .collection("users")
      .doc(user.uid)
      .get();

  if (!doc.exists) {
    return {};
  }

  return Map<String, dynamic>.from(
    doc.data()?["preferences"] ?? {},
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


  
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline, color: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
  controller: _searchController,
  onChanged: (value) {
    setState(() {
      _searchText = value.toLowerCase();
    });
  },
  decoration: const InputDecoration(
    border: InputBorder.none,
    hintText: "Search by hostel name or location",
    prefixIcon: Icon(Icons.search),
  ),
),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.tune, color: Colors.white),
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
            ? const Color(0xFF2563EB)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? const Color(0xFF2563EB)
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
    );
  }


List<QueryDocumentSnapshot> _hostelsForLocation(
    List<QueryDocumentSnapshot> docs, String location) {
  return docs.where((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return (data['location'] ?? '') == location;
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
            child: _buildHostelCard(
              hostelId: hostelDocs[index].id,
              name: data['hostelName'] ?? 'Unnamed Hostel',
              distance: data['location'] ?? '',
              singlePrice: data['singlePrice'] ?? '0',
              doublePrice: data['doublePrice'] ?? '0',
              rating: '4.5',
            ),
          );
        },
      ),
    );
  }

    
  

Widget _buildAllHostelsList(List<QueryDocumentSnapshot> hostelDocs) {
    if (hostelDocs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("No hostels found.", style: TextStyle(fontSize: 16)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: hostelDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildAllHostelCard(
              hostelId: doc.id,
              name: data['hostelName'] ?? 'Unnamed Hostel',
              distance: data['location'] ?? '',
              singlePrice: data['singlePrice'] ?? '0',
              doublePrice: data['doublePrice'] ?? '0',
              rating: '4.5',
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAllHostelCard({
    required String hostelId,
    required String name,
    required String distance,
    required String singlePrice,
    required String doublePrice,
    required String rating,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
            ),
            child: const Center(child: Icon(Icons.image, size: 32, color: Colors.grey)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.grey, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          distance,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ),
                      const Icon(Icons.star, color: Color(0xFFF97316), size: 13),
                      const SizedBox(width: 2),
                      Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
  children: [
    Expanded(
      child: Text(
        'Single UGX $singlePrice',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 11),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: Text(
        'Double UGX $doublePrice',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 11),
      ),
    ),
  ],
),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HostelDetailsScreen(hostelId: hostelId),
                        ),
                      );
                    },
                    child: const Text(
                      'View Details',
                      style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildHostelCard({
  required String hostelId,
  required String name,
  required String distance,
  required String singlePrice,
  required String doublePrice,
  required String rating,
}) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HostelDetailsScreen(hostelId: hostelId),
        ),
      );
    },
    child: SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 170,
                  width: 170,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.image, size: 32, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_border, size: 16, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star, size: 13, color: Colors.black87),
              const SizedBox(width: 2),
              Text(rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            distance,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            'UGX $singlePrice · single',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildPriceOption(String type, String price) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            Text('UGX $price', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      selectedItemColor: const Color(0xFF2563EB),
      unselectedItemColor: Colors.grey,
      onTap: (index){
        if (index == 0) return;
        if (index == 1){
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentSearchScreen(),
            ),
          );
          return;
        }
        if (index==2){
          _goToActiveBooking(context);
          return;
        }
        if (index==3){
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentNotificationsScreen(),
            ),
          );
          return;
        }
        if (index==4){
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentProfileScreen(),
            ),
          );
          return;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Booking'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Notifications'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}