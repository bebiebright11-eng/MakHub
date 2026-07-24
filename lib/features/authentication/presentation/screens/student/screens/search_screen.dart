import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/algorithms/search_algorithm.dart';
import 'hostel_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'active_booking_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'home_screen.dart';

class StudentSearchScreen extends StatefulWidget {
  const StudentSearchScreen({super.key});

  @override
  State<StudentSearchScreen> createState() => _StudentSearchScreenState();
}

class _StudentSearchScreenState extends State<StudentSearchScreen> {
  final Stream<QuerySnapshot> _hostelsStream =
    FirebaseFirestore.instance
        .collection('hostels')
        .snapshots();

  final TextEditingController _searchController =
      TextEditingController();

  String _searchText = "";
  String _selectedFilter = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
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
        title: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchText = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search hostels by name or location',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const Icon(Icons.tune, color: Color(0xFF2563EB), size: 20),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
    stream: _hostelsStream,
    builder: (context, snapshot) {

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(
          child: Text("No hostels found"),
        );
      }

      final hostelDocs = _filterHostels(snapshot.data!.docs);

      return Column(
        children: [
          
          _buildFilterBar(),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${hostelDocs.length} hostels found",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                Row(
                  children: [
                    const Icon(
                      Icons.swap_vert,
                      size: 16,
                      color: Colors.grey,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      "Sort: Nearest",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24),

              itemCount: hostelDocs.length,

              itemBuilder: (context, index) {

                final data = hostelDocs[index].data()
                    as Map<String, dynamic>;

                return _buildHostelItem(
                  hostelDocs[index].id,
                  data["hostelName"] ?? "",
                  data["location"] ?? "",
                  data["singlePrice"] ?? "",
                  "4.5",
                  List<String>.from(data["facilities"] ?? []),
                );
              },
            ),
          ),
        ],
      );
    },
  ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Future<void> _goToActiveBooking(BuildContext context) async {
  debugPrint("Booking tab tapped");

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
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Something went wrong: $e")),
    );
  }
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

      final doublePrice = (data['doublePrice'] ?? '')
          .toString()
          .replaceAll(RegExp(r'[^0-9]'), '');

      switch (_selectedFilter) {
        case "Girls":
          return hostelType == "girls";

        case "Boys":
          return hostelType == "boys";

        case "Single":
          return singlePrice.isNotEmpty;

        case "Double":
          return doublePrice.isNotEmpty;

        case "Budget":
          final single =
              singlePrice.isEmpty ? 999999999 : int.parse(singlePrice);
          
          final doubleRoom =
              doublePrice.isEmpty ? 999999999 : int.parse(doublePrice);

          return single <= 500000 || doubleRoom <= 500000;    
        default:
          return true;
      }
    }).toList();
  }
  
  Widget _buildFilterBar() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _buildMiniChip('Budget', Icons.account_balance_wallet_outlined),
          _buildMiniChip('Distance', Icons.location_on_outlined),
          _buildMiniChip('Girls', Icons.female_outlined),
          _buildMiniChip('Boys', Icons.male_outlined),
          _buildMiniChip('Single', Icons.person_outline),
          _buildMiniChip('Double', Icons.people_outline),
        ],
      ),
    );
  }

  Widget _buildMiniChip(
      String label,
      IconData icon,) {

    final filterValue = label;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedFilter == filterValue) {
            _selectedFilter = "";
          } else {
            _selectedFilter = filterValue;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: _selectedFilter == filterValue
              ? const Color(0xFF2563EB)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _selectedFilter == filterValue
                ? const Color(0xFF2563EB)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: _selectedFilter == filterValue
                  ? Colors.white
                  : Colors.black,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: _selectedFilter == filterValue
                    ? Colors.white
                    : Colors.black,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostelItem(String hostelId, String name, String distance, String price, String rating, List<String> features) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const Center(child: Icon(Icons.image, color: Colors.grey)),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF97316), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [const Icon(Icons.star, color: Colors.white, size: 10), const SizedBox(width: 4), Text(rating, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))]),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.favorite, color: Color(0xFFF97316), size: 16)),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Row(children: [const Icon(Icons.location_on, size: 12, color: Color(0xFF2563EB)), const SizedBox(width: 4), Text(distance, style: const TextStyle(color: Colors.grey, fontSize: 11))]),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: features.map((f) => _buildFeatureTag(f)).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('From', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        Text('UGX $price', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder :(_) => HostelDetailsScreen(hostelId: hostelId,),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: const Text('View', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFeatureTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getFeatureIcon(label), size: 10, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  IconData _getFeatureIcon(String label) {
    switch (label) {
      case 'Wi-Fi': return Icons.wifi;
      case 'Shuttle': return Icons.airport_shuttle;
      case 'Kitchen': return Icons.restaurant;
      case 'Pool': return Icons.pool;
      case 'Laundry': return Icons.local_laundry_service;
      case 'Reading': return Icons.menu_book;
      default: return Icons.check;
    }
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 1,
      selectedItemColor: const Color(0xFF2563EB),
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:(_) => const StudentHomeScreen(),
               ),
            );
        }

        if (index == 1) {
          return; 
        }
        if(index == 2){
          _goToActiveBooking(context);
          return;
        }
        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentNotificationsScreen(),
            ),
          );
          return;
        }
        if (index == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                const StudentProfileScreen(),
            ),
          );
          return;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          label: 'Booking',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          label: 'Alerts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}
