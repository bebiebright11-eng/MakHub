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

  Future<void> fetchStats() async {
    // Collection group query: searches every 'rooms' subcollection,
    // no matter which hostel or floor it's nested under.
    final roomsSnapshot =
        await FirebaseFirestore.instance.collectionGroup('rooms').get();

    int total = roomsSnapshot.docs.length;
    int available = 0;
    int occupied = 0;
    int reserved = 0;

    for (var doc in roomsSnapshot.docs) {
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

    notifyListeners();
  }
}