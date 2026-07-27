import 'package:cloud_firestore/cloud_firestore.dart';

/// The result of a conflict check.
/// [allowed] = true means the booking can proceed.
/// [allowed] = false means it must be blocked; [reason] explains why.
class ConflictResult {
  final bool allowed;
  final String reason;

  const ConflictResult.allowed()
      : allowed = true,
        reason = '';

  const ConflictResult.blocked(this.reason) : allowed = false;
}

/// Checks all pre-conditions that must pass before a booking is created.
///
/// Checks performed (in order):
///   1. Student already has an active booking  → blocked
///   2. Room status is not 'Available'         → blocked
///   3. Room is at full capacity               → blocked
///
/// All checks hit Firestore directly so the result is always fresh.
class BookingConflictAlgorithm {
  /// [studentId]  – the Firebase Auth UID of the booking student.
  /// [hostelId]   – the hostel containing the room.
  /// [floorId]    – the floor containing the room.
  /// [roomId]     – the specific room being booked.
  static Future<ConflictResult> check({
    required String studentId,
    required String hostelId,
    required String floorId,
    required String roomId,
  }) async {
    // ── 1. Active booking check ───────────────────────────────────────────
    // An "active" booking is any booking whose status is not cancelled/rejected.
    final activeBookingQuery = await FirebaseFirestore.instance
        .collection('bookings')
        .where('studentId', isEqualTo: studentId)
        .where('bookingStatus', whereIn: ['pending', 'confirmed', 'approved'])
        .limit(1)
        .get();

    if (activeBookingQuery.docs.isNotEmpty) {
      return const ConflictResult.blocked(
        'You already have an active booking. '
        'Please cancel it before making a new one.',
      );
    }

    // ── 2. Room status check ─────────────────────────────────────────────
    final roomDoc = await FirebaseFirestore.instance
        .collection('hostels')
        .doc(hostelId)
        .collection('floors')
        .doc(floorId)
        .collection('rooms')
        .doc(roomId)
        .get();

    if (!roomDoc.exists) {
      return const ConflictResult.blocked(
        'This room no longer exists. Please choose a different room.',
      );
    }

    final roomData = roomDoc.data()!;
    final String status = (roomData['status'] ?? '').toString();

    if (status == 'Occupied') {
      return const ConflictResult.blocked(
        'This room is fully occupied. Please choose a different room.',
      );
    }

    if (status == 'Reserved') {
      return const ConflictResult.blocked(
        'This room is already reserved. Please choose a different room.',
      );
    }

    // ── 3. Capacity check ────────────────────────────────────────────────
    final int capacity = _parseInt(roomData['capacity']) ?? 1;
    final int occupied = _parseInt(roomData['occupied']) ?? 0;

    if (occupied >= capacity) {
      return const ConflictResult.blocked(
        'No beds are available in this room. Please choose a different room.',
      );
    }

    return const ConflictResult.allowed();
  }

  static int? _parseInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }
}
