import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentDetailsScreen extends StatelessWidget {
  final String bookingId;
  const PaymentDetailsScreen({super.key, required this.bookingId});

  Future<DocumentSnapshot?> _fetchPaymentDoc() async {
    // 1. Try fetching directly by document ID in 'payments'
    final docDirect = await FirebaseFirestore.instance
        .collection('payments')
        .doc(bookingId)
        .get();

    if (docDirect.exists) return docDirect;

    // 2. Query by 'bookingId' field in 'payments'
    final queryByBooking = await FirebaseFirestore.instance
        .collection('payments')
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();

    if (queryByBooking.docs.isNotEmpty) {
      return queryByBooking.docs.first;
    }

    // 3. Fallback: Query by 'paymentId' field in 'payments'
    final queryByPaymentId = await FirebaseFirestore.instance
        .collection('payments')
        .where('paymentId', isEqualTo: bookingId)
        .limit(1)
        .get();

    if (queryByPaymentId.docs.isNotEmpty) {
      return queryByPaymentId.docs.first;
    }

    return null;
  }

  Future<void> _updatePaymentStatus(
    BuildContext context,
    String paymentDocId,
    String? linkedBookingId,
    String newStatus,
  ) async {
    try {
      // Update Payment Document
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(paymentDocId)
          .update({'paymentStatus': newStatus});

      // Update Booking Document if linked
      final targetBookingId = (linkedBookingId != null && linkedBookingId.isNotEmpty)
          ? linkedBookingId
          : bookingId;

      final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(targetBookingId);
      final bookingDoc = await bookingRef.get();

      if (bookingDoc.exists) {
        await bookingRef.update({
          'bookingStatus': newStatus == 'confirmed' ? 'confirmed' : 'rejected',
        });
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'confirmed'
                ? 'Payment Received. Receipt generated!'
                : 'Payment Rejected.',
          ),
          backgroundColor: newStatus == 'confirmed' ? Colors.green : Colors.red,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (timestamp is String) {
      return timestamp;
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot?>(
        future: _fetchPaymentDoc(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return const Center(child: Text('Payment record not found.'));
          }

          final paymentDoc = snapshot.data!;
          final data = paymentDoc.data() as Map<String, dynamic>;

          final paymentDocId = paymentDoc.id;
          final realBookingId = (data['bookingId'] ?? data['paymentId'] ?? bookingId).toString();
          final studentName = (data['studentName'] ?? data['userName'] ?? 'Student').toString();
          final hostelName = (data['hostelName'] ?? 'Hostel').toString();
          final roomNumber = (data['roomNumber'] ?? data['roomId'] ?? 'N/A').toString();
          final amount = data['amount'] != null ? 'UGX ${data['amount']}' : 'UGX 50,000';
          
          final transferTime = _formatTimestamp(data['paymentTime'] ?? data['paymentDate'] ?? data['createdAt']);
          final transactionRef = (data['transactionReference'] ?? data['transactionID'] ?? data['ref'] ?? 'N/A').toString();
          final mobileNum = (data['mobileMoneyNumber'] ?? data['mobileNumber'] ?? data['phone'] ?? 'N/A').toString();
          
          final receiptUrl = (data['receiptImage'] ?? data['receiptUrl']) as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Booking Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _infoRow('Booking ID', realBookingId),
                _infoRow('Student Name', studentName),
                _infoRow('Hostel', hostelName),
                _infoRow('Room', roomNumber),
                const Divider(height: 32),
                const Text('Payment Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _infoRow('Amount Paid', amount),
                _infoRow('Mobile Number', mobileNum),
                _infoRow('Transfer Time', transferTime),
                _infoRow('Transaction Ref', transactionRef),
                const SizedBox(height: 24),
                const Text('Transfer Receipt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: receiptUrl != null && receiptUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            receiptUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Failed to load receipt image'),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt, size: 80, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('No receipt uploaded', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updatePaymentStatus(
                          context,
                          paymentDocId,
                          realBookingId,
                          'rejected',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Reject Payment'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updatePaymentStatus(
                          context,
                          paymentDocId,
                          realBookingId,
                          'confirmed',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Payment Received'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}