import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentVerificationScreen extends StatelessWidget {
  // Despite the name, this is actually the BOOKING document's ID,
  // passed in from ReportingStudentsScreen as `docId`.
  final String studentId;

  const StudentVerificationScreen({super.key, required this.studentId});

  Future<Map<String, dynamic>?> _fetchVerificationData() async {
    final firestore = FirebaseFirestore.instance;

    final bookingDoc = await firestore.collection('bookings').doc(studentId).get();
    if (!bookingDoc.exists || bookingDoc.data() == null) {
      return null;
    }

    final booking = bookingDoc.data()!;
    final result = <String, dynamic>{
      'docId': bookingDoc.id,
      'sourceCollection': 'bookings',
      'bookingStatus': booking['bookingStatus'],
      'friendBooking': booking['friendBooking'] == true,
    };

    // Resolve student name from users/{studentId}
    final studentRef = booking['studentId'] as String?;
    if (studentRef != null) {
      final userDoc = await firestore.collection('users').doc(studentRef).get();
      if (userDoc.exists) {
        result['studentName'] = userDoc.data()?['fullName'];
        result['admissionLetterUrl'] = userDoc.data()?['admissionLetterUrl'];
      }
    }

    // Resolve hostel name from hostels/{hostelId}
    final hostelRef = booking['hostelId'] as String?;
    if (hostelRef != null) {
      final hostelDoc = await firestore.collection('hostels').doc(hostelRef).get();
      if (hostelDoc.exists) {
        result['hostelName'] = hostelDoc.data()?['hostelName'];
      }
    }

    // Resolve room number from hostels/{hostelId}/floors/{floorId}/rooms/{roomId}
    final floorRef = booking['floorId'] as String?;
    final roomRef = booking['roomId'] as String?;
    if (hostelRef != null && floorRef != null && roomRef != null) {
      final roomDoc = await firestore
          .collection('hostels')
          .doc(hostelRef)
          .collection('floors')
          .doc(floorRef)
          .collection('rooms')
          .doc(roomRef)
          .get();
      if (roomDoc.exists) {
        result['roomNumber'] = roomDoc.data()?['roomNumber'];
      }
    }

    return result;
  }

  Future<void> _processVerification(
    BuildContext context, {
    required String docId,
    required String sourceCollection,
    required bool isApproved,
  }) async {
    try {
      final status = isApproved ? 'checked_in' : 'verification_failed';

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
            return const Center(child: Text('Booking not found.'));
          }

          final data = snapshot.data!;
          final docId = data['docId'] as String;
          final sourceCollection = data['sourceCollection'] as String;

          final studentName = (data['studentName'] ?? 'Unknown Student').toString();
          final hostelName = (data['hostelName'] ?? 'Unknown Hostel').toString();
          final roomNumberRaw = (data['roomNumber'] ?? 'N/A').toString();
          final roomNumber = roomNumberRaw.startsWith('Room') ? roomNumberRaw : 'Room $roomNumberRaw';
          final friendBooking = data['friendBooking'] == true;
          final admissionDocUrl = data['admissionLetterUrl'] as String?;
          final bookingStatus = (data['bookingStatus'] ?? 'pending').toString();

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
                      _infoRow('Booking ID', docId),
                      _infoRow('Hostel', hostelName),
                      _infoRow('Room', roomNumber),
                      _infoRow('Status', bookingStatus),
                      _infoRow('Booked with a friend', friendBooking ? 'Yes' : 'No'),
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
                              Text('No admission letter uploaded', style: TextStyle(color: Colors.grey)),
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