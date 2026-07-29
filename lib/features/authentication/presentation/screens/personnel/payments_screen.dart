import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/algorithms/payment_verification_algorithm.dart';
import 'payment_details_screen.dart';

class PendingPaymentsScreen extends StatefulWidget {
  const PendingPaymentsScreen({super.key});

  @override
  State<PendingPaymentsScreen> createState() => _PendingPaymentsScreenState();
}

class _PendingPaymentsScreenState extends State<PendingPaymentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<String?> _getPersonnelHostelId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('personnel')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
    }

    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>?;
    return (data?['hostelId'] ?? data?['hostelID']) as String?;
  }

  Future<void> _confirmPayment(String paymentDocId, String bookingId) async {
    try {
      final result = await PaymentVerificationAlgorithm.verify(paymentDocId);

      if (!mounted) return;

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Verification failed.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment confirmed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to confirm payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Confirmations', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<String?>(
        future: _getPersonnelHostelId(),
        builder: (context, hostelSnapshot) {
          if (hostelSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final hostelId = hostelSnapshot.data;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search Booking ID or Name',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('payments')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No payment records found.'));
                    }

                    // Filter client-side defensively for status, hostelId, and search query
                    final docs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      // Check status (pending)
                      final status = (data['paymentStatus'] ?? data['status'] ?? 'pending').toString().toLowerCase();
                      if (status != 'pending') return false;

                      // Scope by hostelId if available on doc
                      final docHostelId = data['hostelId'] ?? data['hostelID'];
                      if (hostelId != null && docHostelId != null && docHostelId != hostelId) {
                        return false;
                      }

                      // Apply search filter
                      if (_searchQuery.isNotEmpty) {
                        final bookingId = (data['bookingId'] ?? data['paymentId'] ?? doc.id).toString().toLowerCase();
                        final studentName = (data['studentName'] ?? data['userName'] ?? '').toString().toLowerCase();
                        return bookingId.contains(_searchQuery) || studentName.contains(_searchQuery);
                      }

                      return true;
                    }).toList();

                    if (docs.isEmpty) {
                      return const Center(child: Text('No pending payments to verify.'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final paymentDocId = doc.id;
                        final bookingId = (data['bookingId'] ?? data['paymentId'] ?? paymentDocId).toString();
                        final studentName = (data['studentName'] ?? data['userName'] ?? 'Student').toString();
                        final hostelName = (data['hostelName'] ?? 'Hostel').toString();
                        final roomNumber = (data['roomNumber'] ?? data['roomId'] ?? 'N/A').toString();
                        final amount = data['amount'] != null ? 'UGX ${data['amount']}' : 'N/A';

                        return _paymentCard(
                          context,
                          paymentDocId: paymentDocId,
                          bookingId: bookingId,
                          name: studentName,
                          hostel: hostelName,
                          room: roomNumber,
                          amount: amount,
                          time: 'Pending',
                          data: data,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _paymentCard(
    BuildContext context, {
    required String paymentDocId,
    required String bookingId,
    required String name,
    required String hostel,
    required String room,
    required String amount,
    required String time,
    required Map<String, dynamic> data,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ID: $bookingId', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Pending', style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$hostel â€¢ Room $room', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentDetailsScreen(bookingId: bookingId),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _confirmPayment(paymentDocId, bookingId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirm'),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}