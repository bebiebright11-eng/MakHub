import 'package:flutter/material.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryChips(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Recommended Hostels'),
                  const SizedBox(height: 16),
                  _buildHostelList(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Near Campus'),
                  const SizedBox(height: 16),
                  // Add more content here as needed
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
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
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text('Search by hostel name or location', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                    ],
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

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildChip('Budget', Icons.account_balance_wallet_outlined, true),
          const SizedBox(width: 12),
          _buildChip('Location', Icons.location_on_outlined, false),
          const SizedBox(width: 12),
          _buildChip('Girls', Icons.female_outlined, false),
          const SizedBox(width: 12),
          _buildChip('Single', Icons.person_outline, false),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2563EB) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: isActive ? Colors.white : Colors.black, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        ],
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
          TextButton(
            onPressed: () {},
            child: const Text('See all', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHostelList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildHostelCard('Nakawa Heights Hostel', '0.4 km to campus', '850K', '550K', '4.8'),
          const SizedBox(width: 20),
          _buildHostelCard('Kikoni Plaza', '0.7 km to campus', '900K', '600K', '4.6'),
        ],
      ),
    );
  }

  Widget _buildHostelCard(String name, String distance, String singlePrice, String doublePrice, String rating) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(rating, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.favorite_border, color: Color(0xFFF97316), size: 18),
                ),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.grey, size: 14),
                    const SizedBox(width: 4),
                    Text(distance, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildPriceOption('Single', singlePrice),
                    const SizedBox(width: 12),
                    _buildPriceOption('Double', doublePrice),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('View Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          )
        ],
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
