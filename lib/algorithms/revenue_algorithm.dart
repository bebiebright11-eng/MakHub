import 'package:cloud_firestore/cloud_firestore.dart';

/// Aggregates revenue from confirmed payments.
///
/// Reads from the `payments` collection, filtering by:
///   paymentStatus == 'confirmed'
///   paymentTime   within the requested date window
///
/// Optionally scoped to a specific hostelId when set.
class RevenueAlgorithm {
  const RevenueAlgorithm._();

  // ── Public API ────────────────────────────────────────────────────────────

  static Future<RevenueResult> daily({String? hostelId}) =>
      _compute(RevenueWindow.daily, hostelId: hostelId);

  static Future<RevenueResult> weekly({String? hostelId}) =>
      _compute(RevenueWindow.weekly, hostelId: hostelId);

  static Future<RevenueResult> monthly({String? hostelId}) =>
      _compute(RevenueWindow.monthly, hostelId: hostelId);

  // ── Core ─────────────────────────────────────────────────────────────────

  static Future<RevenueResult> _compute(
    RevenueWindow window, {
    String? hostelId,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime from = _windowStart(now, window);

    // Base query: confirmed payments in the time window
    Query query = FirebaseFirestore.instance
        .collection('payments')
        .where('paymentStatus', isEqualTo: 'confirmed')
        .where('paymentTime', isGreaterThanOrEqualTo: Timestamp.fromDate(from));

    final snapshot = await query.get();

    double total = 0;
    int count = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Optionally scope to one hostel via bookingId → booking → hostelId
      if (hostelId != null) {
        final bookingId = data['bookingId']?.toString() ?? '';
        if (bookingId.isEmpty) continue;

        final bookingDoc = await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .get();

        if (!bookingDoc.exists) continue;
        final bData = bookingDoc.data() as Map<String, dynamic>;
        if (bData['hostelId'] != hostelId) continue;
      }

      final raw = data['amount'];
      final double? amount =
          raw is num ? raw.toDouble() : double.tryParse(raw.toString());
      if (amount != null && amount > 0) {
        total += amount;
        count++;
      }
    }

    return RevenueResult(
      total: total,
      paymentCount: count,
      window: window,
      from: from,
      to: now,
    );
  }

  static DateTime _windowStart(DateTime now, RevenueWindow window) {
    switch (window) {
      case RevenueWindow.daily:
        return DateTime(now.year, now.month, now.day);
      case RevenueWindow.weekly:
        return now.subtract(const Duration(days: 7));
      case RevenueWindow.monthly:
        return DateTime(now.year, now.month, 1);
    }
  }
}

enum RevenueWindow { daily, weekly, monthly }

class RevenueResult {
  final double total;
  final int paymentCount;
  final RevenueWindow window;
  final DateTime from;
  final DateTime to;

  const RevenueResult({
    required this.total,
    required this.paymentCount,
    required this.window,
    required this.from,
    required this.to,
  });

  /// e.g. "UGX 1,200,000" formatted with commas.
  String get formattedTotal {
    final parts = total.toStringAsFixed(0).split('');
    final List<String> result = [];
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) result.add(',');
      result.add(parts[i]);
    }
    return 'UGX ${result.join()}';
  }

  String get windowLabel {
    switch (window) {
      case RevenueWindow.daily:
        return 'Today';
      case RevenueWindow.weekly:
        return 'This week';
      case RevenueWindow.monthly:
        return 'This month';
    }
  }
}
