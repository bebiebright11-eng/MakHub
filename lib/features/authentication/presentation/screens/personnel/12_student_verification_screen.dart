import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentVerificationScreen extends StatelessWidget {
  final String studentId; // Can be student ID, user ID, or booking ID

  const StudentVerificationScreen({super.key, required this.studentId});

  Future<Map<String, dynamic>?> _fetchVerificationData() async {
    // 1. Try fetching from 'bookings' collection
    final bookingDoc = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(studentId)
        .get();

    if (bookingDoc.exists && bookingDoc.data() != null) {
      final data = Map<String, dynamic>.from(bookingDoc.data()!);
      data['docId'] = bookingDoc.id;
      data['sourceCollection'] = 'bookings';
      return data;
    }

    // 2. Try searching by studentId in 'bookings'
    final bookingQuery = await FirebaseFirestore.instance
        .collection('bookings')
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();

    if (bookingQuery.docs.isNotEmpty) {
      final data = Map<String, dynamic>.from(bookingQuery.docs.first.data());
      data['docId'] = bookingQuery.docs.first.id;
      data['sourceCollection'] = 'bookings';
      return data;
    }

    // 3. Fallback: Search in 'users' or 'students' collection
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(studentId)
        .get();

    if (userDoc.exists && userDoc.data() != null) {
      final data = Map<String, dynamic>.from(userDoc.data()!);
      data['docId'] = userDoc.id;
      data['sourceCollection'] = 'users';
      return data;
    }

    return null;
  }

  Future<void> _processVerification(
    BuildContext context, {
    required String docId,
    required String sourceCollection,
    required bool isApproved,
  }) async {
    try {
      final status = isApproved ? 'checked_in' : 'verification_failed';
      
      // Update primary collection record
      await FirebaseFirestore.instance
          .collection(sourceCollection)
          .doc(docId)
          .update({
        'status': status,
        'bookingStatus': status,
        'isCheckedIn': isApproved,
        'verifiedAt': FieldValue.serverTimestamp(),
        if (isApproved) 'checkedInAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isApproved
                ? 'Student checked in successfully!'
                : 'Student verification rejected.',
          ),
          backgroundColor: isApproved ? Colors.green : Colors.red,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Verification', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchVerificationData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Student or booking details not found.'));
          }

          final data = snapshot.data!;
          final docId = data['docId'] as String;
          final sourceCollection = data['sourceCollection'] as String;

          final studentName = (data['studentName'] ?? data['name'] ?? data['userName'] ?? 'John Doe').toString();
          final bookingIdStr = (data['bookingId'] ?? data['docId'] ?? studentId).toString();
          final hostelName = (data['hostelName'] ?? data['hostel'] ?? 'Elite Residency').toString();
          final roomNumber = (data['roomNumber'] ?? data['room'] ?? 'N/A').toString();
          final roommate = (data['friendName'] ?? data['roommate'] ?? data['friend'] ?? 'N/A').toString();
          final admissionDocUrl = (data['admissionLetterUrl'] ?? data['documentUrl'] ?? data['admissionLetter']) as String?;
          final isVerified = data['isVerified'] == true || data['admissionVerified'] == true;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFFDBEAFE),
                  child: Icon(Icons.person, size: 50, color: Color(0xFF2563EB)),
                ),
                const SizedBox(height: 16),
                Text(
                  studentName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    children: [
                      _infoRow('Booking ID', bookingIdStr),
                      _infoRow('Hostel', hostelName),
                      _infoRow('Room', roomNumber),
                      _infoRow('Admission Letter', isVerified ? 'Verified ✓' : 'Pending Review'),
                      _infoRow('Friend (Double)', roommate),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: admissionDocUrl != null && admissionDocUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            admissionDocUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Unable to load document image'),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.file_present, size: 60, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Admission Letter Preview', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _processVerification(
                          context,
                          docId: docId,
                          sourceCollection: sourceCollection,
                          isApproved: false,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _processVerification(
                          context,
                          docId: docId,
                          sourceCollection: sourceCollection,
                          isApproved: true,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Check In Student'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
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