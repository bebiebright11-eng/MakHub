import 'package:flutter/material.dart';

class StudentSearchScreen extends StatefulWidget {
  const StudentSearchScreen({super.key});

  @override
  State<StudentSearchScreen> createState() => _StudentSearchScreenState();
}

class _StudentSearchScreenState extends State<StudentSearchScreen> {
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
                  decoration: InputDecoration(
                    hintText: 'Search hostels by name or location',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const Icon(Icons.tune, color: Color(0xFF2563EB), size: 20),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('18 hostels found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Row(
                  children: [
                    const Icon(Icons.swap_vert, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Sort: Nearest', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildHostelItem('Nsibirwa Hostel', '0.4 km', '700K', '4.8', ['Wi-Fi', 'Shuttle', 'Kitchen']),
                _buildHostelItem('Olympia Suites', '0.9 km', '950K', '4.6', ['Wi-Fi', 'Pool', 'Laundry']),
                _buildHostelItem('Akamwesi Court', '1.2 km', '820K', '4.9', ['Wi-Fi', 'Reading', 'Single']),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _buildMiniChip('Budget', Icons.account_balance_wallet_outlined, true),
          _buildMiniChip('Distance', Icons.location_on_outlined, false),
          _buildMiniChip('Girls', Icons.female_outlined, true),
          _buildMiniChip('Boys', Icons.male_outlined, false),
          _buildMiniChip('Single', Icons.person_outline, false),
          _buildMiniChip('Double', Icons.people_outline, true),
        ],
      ),
    );
  }

  Widget _buildMiniChip(String label, IconData icon, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2563EB) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: isActive ? Colors.white : Colors.black, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.black, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHostelItem(String name, String distance, String price, String rating, List<String> features) {
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
                        onPressed: () {},
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
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Booking'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}
