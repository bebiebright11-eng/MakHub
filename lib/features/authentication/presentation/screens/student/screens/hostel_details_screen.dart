import 'package:flutter/material.dart';
import 'floor_selection_screen.dart';

class HostelDetailsScreen extends StatelessWidget {
  const HostelDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleSection(),
                  const SizedBox(height: 16),
                  _buildTags(),
                  const SizedBox(height: 24),
                  _buildPricingCards(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Description'),
                  const SizedBox(height: 8),
                  const Text(
                    'A modern, secure hostel just minutes from campus. Enjoy spacious rooms, reliable Wi-Fi, daily shuttle service, and a friendly student community designed for comfortable living and focused study.',
                    style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Facilities'),
                  const SizedBox(height: 16),
                  _buildFacilitiesGrid(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Hostel Rules'),
                  const SizedBox(height: 16),
                  _buildRules(),
                  const SizedBox(height: 24),
                  _buildReviewsSection(),
                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomButtons(context),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            image: const DecorationImage(
              image: NetworkImage('https://via.placeholder.com/600x400'), // Replace with actual image
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Play Button Overlay
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Color(0xFF2563EB), size: 32),
            ),
          ),
        ),
        // Top Buttons
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
        // Dots Indicator
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index == 0 ? Colors.white : Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            )),
          ),
        ),
        // Tour Label
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
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

  Widget _buildTitleSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kilimanjaro Hostel', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Color(0xFF2563EB)),
                const SizedBox(width: 4),
                Text('Wandegeya, Kampala', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.star, color: Color(0xFF2563EB), size: 14),
              SizedBox(width: 4),
              Text('4.8', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTags() {
    return Row(
      children: [
        _buildTag('Security A+', const Color(0xFFFFF7ED), const Color(0xFFF97316), Icons.security),
        const SizedBox(width: 12),
        _buildTag('0.6 km to Campus', const Color(0xFFF1F5F9), Colors.black, Icons.directions_walk),
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

  Widget _buildPricingCards() {
    return Row(
      children: [
        _buildPriceCard('Single Room', '450K'),
        const SizedBox(width: 16),
        _buildPriceCard('Double Room', '320K'),
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
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

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildFacilitiesGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _facilityItem('Wi-Fi', Icons.wifi),
        _facilityItem('Shuttle', Icons.airport_shuttle),
        _facilityItem('Kitchen', Icons.restaurant),
        _facilityItem('Laundry', Icons.local_laundry_service),
        _facilityItem('Reading', Icons.menu_book),
        _facilityItem('Pool', Icons.pool),
      ],
    );
  }

  Widget _facilityItem(String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 20),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRules() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _ruleRow(Icons.access_time, 'Gate closes at 11:00 PM', const Color(0xFFF97316)),
          const SizedBox(height: 12),
          _ruleRow(Icons.no_smoking, 'No smoking indoors', Colors.red),
          const SizedBox(height: 12),
          _ruleRow(Icons.people_outline, 'Visitors until 8:00 PM only', Colors.blue),
          const SizedBox(height: 12),
          _ruleRow(Icons.volume_up_outlined, 'Quiet hours after 10:00 PM', Colors.amber),
        ],
      ),
    );
  }

  Widget _ruleRow(IconData icon, String rule, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 12),
        Text(rule, style: TextStyle(color: Colors.grey.shade800, fontSize: 14)),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Student Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () {}, child: const Text('See all', style: TextStyle(color: Color(0xFF2563EB)))),
          ],
        ),
        const SizedBox(height: 12),
        Container(
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Michael O.', style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.orange, size: 14),
                            Icon(Icons.star, color: Colors.orange, size: 14),
                            Icon(Icons.star, color: Colors.orange, size: 14),
                            Icon(Icons.star, color: Colors.orange, size: 14),
                            Icon(Icons.star, color: Colors.orange, size: 14),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text('2d ago', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Clean rooms, fast Wi-Fi and the shuttle makes campus so easy. Highly recommend!',
                style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentFloorSelectionScreen())),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFDBEAFE)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.layers_outlined, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text('View Floors', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
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
