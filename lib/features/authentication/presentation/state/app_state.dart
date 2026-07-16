import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  int totalRooms = 120;
  int availableRooms = 45;
  int occupiedRooms = 65;
  int pendingPayments = 12;
  int reservedRooms = 10;
  int studentsReportingToday = 8;

  void updateStats() {
    notifyListeners();
  }
}
