import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'receipt_screen.dart';

class StudentBookingDetailsScreen extends StatefulWidget {
  final String hostelId;
  final String floorId;
  final String roomId;

  const StudentBookingDetailsScreen({
    super.key,
    required this.hostelId,
    required this.floorId,
    required this.roomId,
  });

  @override
  State<StudentBookingDetailsScreen> createState() => _StudentBookingDetailsScreenState();
}

class _StudentBookingDetailsScreenState extends State<StudentBookingDetailsScreen> {
  bool _isOnlyMe = true;
  bool _isSaving = false;
  final _friendNameController = TextEditingController();
  final _friendPhoneController = TextEditingController();

  late final Stream<DocumentSnapshot> _hostelStream =
      FirebaseFirestore.instance.collection('hostels').doc(widget.hostelId).snapshots();
  late final Stream<DocumentSnapshot> _roomStream =
      FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots();

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _friendNameController.dispose();
    _friendPhoneController.dispose();
    super.dispose();
  }

  Future<void> _createBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to book')),
      );
      return;
    }

    if (!_isOnlyMe &&
        (_friendNameController.text.trim().isEmpty ||
            _friendPhoneController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in your friend\'s details')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final bookingRef = await FirebaseFirestore.instance.collection('bookings').add({
        'studentId': user.uid,
        'hostelId': widget.hostelId,
        'roomId': widget.roomId,
        'bookingStatus': 'pending',
        'bookingDate': FieldValue.serverTimestamp(),
        'friendBooking': !_isOnlyMe,
        if (!_isOnlyMe) 'friendName': _friendNameController.text.trim(),
        if (!_isOnlyMe) 'friendPhone': _friendPhoneController.text.trim(),
      });

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => StudentReceiptScreen(bookingId: bookingRef.id)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking Details', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Review your booking summary and choose an option', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _hostelStream,
        builder: (context, hostelSnap) {
          return StreamBuilder<DocumentSnapshot>(
            stream: _roomStream,
            builder: (context, roomSnap) {
              if (!hostelSnap.hasData || !roomSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final hostelData = hostelSnap.data!.data() as Map<String, dynamic>? ?? {};
              final roomData = roomSnap.data!.data() as Map<String, dynamic>? ?? {};

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(hostelData, roomData),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Booking Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
                          child: const Text('Choose one', style: TextStyle(color: Color(0xFFF97316), fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildOptionCard('Only Me', 'Book the room for yourself only', _isOnlyMe, () => setState(() => _isOnlyMe = true)),
                        const SizedBox(width: 16),
                        _buildOptionCard('Me & Friend', 'Share the room with another student', !_isOnlyMe, () => setState(() => _isOnlyMe = false)),
                      ],
                    ),
                    if (!_isOnlyMe) ...[
                      const SizedBox(height: 32),
                      _buildFriendDetailsSection(),
                    ],
                    const SizedBox(height: 40), 
                  ],
                ),
              );
            },
          );
        },
      ),
      // We combine both components layout-wise into the bottom parameter 
      // so that they stack nicely and don't conflict with the virtual keyboard.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomAction(),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> hostelData, Map<String, dynamic> roomData) {
    const bookingFee = 50000;
    const mobileMoneyCharge = 2000;
    final total = bookingFee + mobileMoneyCharge;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hostel Name', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(hostelData['hostelName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                child: Text('Security ${hostelData['securityRating'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem('Room Number', 'Room ${roomData['roomNumber'] ?? ''}'),
              _summaryItem('Booking Fee', 'UGX $bookingFee'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem('Mobile Money Charges', 'UGX $mobileMoneyCharge'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total Amount', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text('UGX $total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2563EB))),
                ],
              ),
            ],
          ),
          const Divider(height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payable now', style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text('Secure booking confirmation', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _summaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildOptionCard(String title, String subtitle, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: const Color(0xFF2563EB)),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.people_outline, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Friend Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 24),
          _buildField('Friend\'s Full Name', 'Enter full name', Icons.person_outline, _friendNameController),
          const SizedBox(height: 20),
          _buildField('Friend\'s Phone Number', '+256 700 000 000', Icons.phone_outlined, _friendPhoneController),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Upload Friend\'s Admission Letter ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Column(
              children: [
                const Icon(Icons.description_outlined, color: Color(0xFF2563EB), size: 32),
                const SizedBox(height: 12),
                const Text('Tap to upload document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Text('PDF, JPG or PNG required', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Choose File'),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'The friend\'s admission letter is required to verify that both occupants are admitted university students.',
            style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String hint, IconData icon, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            blurRadius: 10, 
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _createBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Continue to Payment', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 2,
      selectedItemColor: const Color(0xFF2563EB),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Booking'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Notifications'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}