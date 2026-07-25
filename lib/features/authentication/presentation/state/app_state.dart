import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  int totalRooms = 0;
  int availableRooms = 0;
  int occupiedRooms = 0;
  int pendingPayments = 0;
  int reservedRooms = 0;
  int studentsReportingToday = 0;
  // Logged in hostel personnel
String personnelId = "";
String personnelName = "";
String personnelEmail = "";

String hostelId = "";
String hostelName = "";


  Future<void> fetchStats() async {
    // Collection group query, filtered to only this personnel's hostel
    // via each room document's parent path.
    final roomsSnapshot = await FirebaseFirestore.instance
        .collectionGroup('rooms')
        .get();

    int total = 0;
    int available = 0;
    int occupied = 0;
    int reserved = 0;

    for (var doc in roomsSnapshot.docs) {
      // Each room's path looks like: hostels/{hostelId}/floors/{floorId}/rooms/{roomId}
      final belongsToThisHostel =
          doc.reference.path.contains('hostels/$hostelId/');

      if (!belongsToThisHostel) continue;

      total++;
      final status = doc.data()['status'] ?? '';
      if (status == 'Available') {
        available++;
      } else if (status == 'Occupied') {
        occupied++;
      } else if (status == 'Reserved') {
        reserved++;
      }
    }

    totalRooms = total;
    availableRooms = available;
    occupiedRooms = occupied;
    reservedRooms = reserved;

    // Pending payments scoped to this hostel
    final pendingPaymentsSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('paymentStatus', isEqualTo: 'pending')
        .get();

    int pendingCount = 0;
    for (var paymentDoc in pendingPaymentsSnapshot.docs) {
      final bookingId = paymentDoc.data()['bookingId'];
      if (bookingId == null) continue;

      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (bookingDoc.exists && bookingDoc.data()?['hostelId'] == hostelId) {
        pendingCount++;
      }
    }

    pendingPayments = pendingCount;

    notifyListeners();
  }
void setPersonnel({
  required String personnelId,
  required String personnelName,
  required String personnelEmail,
  required String hostelId,
  required String hostelName,
}) {
  this.personnelId = personnelId;
  this.personnelName = personnelName;
  this.personnelEmail = personnelEmail;
  this.hostelId = hostelId;
  this.hostelName = hostelName;

  notifyListeners();
}

}

