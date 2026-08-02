import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/constants/payment_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models returned by the Finance Service.
// Keep these here so UI code imports one file.
// ─────────────────────────────────────────────────────────────────────────────

/// Summary for the whole platform (all hostels combined).
class PlatformFinancialSummary {
  final double totalHostelRevenue;
  final double makHubEarnings;
  final int confirmedBookingCount;
  final int hostelCount;

  const PlatformFinancialSummary({
    required this.totalHostelRevenue,
    required this.makHubEarnings,
    required this.confirmedBookingCount,
    required this.hostelCount,
  });
}

/// Summary scoped to a single hostel.
class HostelFinancialSummary {
  final String hostelId;
  final String hostelName;
  final double hostelRevenue;
  final double makHubEarnings;
  final int confirmedBookingCount;

  /// Architecture for future withdrawals.
  /// [amountWithdrawn] is always 0 until the withdrawal feature ships.
  final double amountWithdrawn;

  double get remainingBalance => hostelRevenue - amountWithdrawn;

  const HostelFinancialSummary({
    required this.hostelId,
    required this.hostelName,
    required this.hostelRevenue,
    required this.makHubEarnings,
    required this.confirmedBookingCount,
    this.amountWithdrawn = 0,
  });
}

/// A single resolved booking ready for display in the UI.
class ResolvedBooking {
  final String bookingDocId;
  final String shortBookingId;
  final String studentName;
  final String hostelName;
  final String floorName;
  final String roomNumber;
  final String roomType;
  final String bookingStatus;
  final DateTime bookingDate;
  final double amountPaid;

  const ResolvedBooking({
    required this.bookingDocId,
    required this.shortBookingId,
    required this.studentName,
    required this.hostelName,
    required this.floorName,
    required this.roomNumber,
    required this.roomType,
    required this.bookingStatus,
    required this.bookingDate,
    required this.amountPaid,
  });

  String get formattedDate {
    final d = bookingDate;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  String get formattedAmount => _formatUGX(amountPaid);

  String get displayDate {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${bookingDate.day} ${months[bookingDate.month - 1]} ${bookingDate.year}';
  }
}

/// A group of bookings that share the same calendar date.
class DailyBookingGroup {
  final DateTime date;
  final List<ResolvedBooking> bookings;

  const DailyBookingGroup({required this.date, required this.bookings});

  int get count => bookings.length;
  double get dailyRevenue =>
      bookings.fold(0, (total, b) => total + b.amountPaid);

  String get formattedRevenue => _formatUGX(dailyRevenue);

  String get displayDate {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Result from [FinanceService.prepareWithdrawalData].
/// Wires in the amounts needed for any future withdrawal provider.
/// Payment provider integrations receive this object and never reach
/// into Firestore directly — keeping FinanceService the single
/// source of financial truth.
class WithdrawalData {
  final String hostelId;
  final String hostelName;
  final double availableBalance;

  /// Architecture hook: populate [paymentProvider] when MTN / bank
  /// integrations are added. The UI passes a provider identifier and
  /// FinanceService builds the payload — the provider never reads
  /// Firestore itself.
  final String? paymentProvider; // e.g. 'mtn_momo', 'bank_transfer'
  final Map<String, dynamic> providerPayload;

  const WithdrawalData({
    required this.hostelId,
    required this.hostelName,
    required this.availableBalance,
    this.paymentProvider,
    this.providerPayload = const {},
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Formatting helpers (package-private)
// ─────────────────────────────────────────────────────────────────────────────

String _formatUGX(double amount) {
  final parts = amount.toStringAsFixed(0).split('');
  final List<String> result = [];
  for (int i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) result.add(',');
    result.add(parts[i]);
  }
  return 'UGX ${result.join()}';
}

String _shortId(String id) =>
    id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase();

// ─────────────────────────────────────────────────────────────────────────────
// Finance Service
// ─────────────────────────────────────────────────────────────────────────────

/// Single source of truth for all financial calculations in MakHub Admin.
///
/// Fee split per confirmed booking (all values from [PaymentConstants]):
///
///   Student pays:  bookingFee + mobileMoneyCharge + serviceFee = UGX 112,500
///
///   Hostel Revenue  += bookingFee            (UGX 100,000 per booking)
///   MakHub Earnings += serviceFee
///                    + mobileMoneyCharge     (UGX  12,500 per booking)
///
/// Only `bookingStatus == 'confirmed'` bookings are counted.
/// [amountWithdrawn] is always 0 until the withdrawal feature ships.
///
/// Future payment provider integrations must call [prepareWithdrawalData]
/// and drive their own HTTP / SDK calls — they never touch Firestore directly.
class FinanceService {
  FinanceService._();

  static final FinanceService instance = FinanceService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Fee accessors from PaymentConstants ──────────────────────────────────

  /// What the hostel earns per confirmed booking.
  int get _bookingFee => PaymentConstants.bookingFee;

  /// What MakHub earns per confirmed booking (service + mobile money charge).
  int get _makHubFeePerBooking =>
      PaymentConstants.serviceFee + PaymentConstants.mobileMoneyCharge;

  /// Total amount the student pays per booking.
  int get _totalAmountPerBooking => PaymentConstants.totalAmount;

  // ─────────────────────────────────────────────────────────────────────────
  // Platform-level queries
  // ─────────────────────────────────────────────────────────────────────────

  /// Total revenue across all hostels and total MakHub earnings.
  Future<PlatformFinancialSummary> getTotalHostelRevenue() async {
    final bookingsSnap = await _db
        .collection('bookings')
        .where('bookingStatus', isEqualTo: 'confirmed')
        .get();

    final count = bookingsSnap.docs.length;

    // Hostel Revenue = bookingFee only (UGX 100,000 per booking)
    final hostelRevenue = count * _bookingFee.toDouble();

    // MakHub Earnings = serviceFee + mobileMoneyCharge (UGX 12,500 per booking)
    final makHubEarnings = count * _makHubFeePerBooking.toDouble();

    final hostelSnap = await _db.collection('hostels').get();

    return PlatformFinancialSummary(
      totalHostelRevenue: hostelRevenue,
      makHubEarnings: makHubEarnings,
      confirmedBookingCount: count,
      hostelCount: hostelSnap.docs.length,
    );
  }

  /// MakHub platform earnings = confirmed booking count × (serviceFee + mobileMoneyCharge).
  Future<double> getMakHubEarnings() async {
    final snap = await _db
        .collection('bookings')
        .where('bookingStatus', isEqualTo: 'confirmed')
        .get();
    return snap.docs.length * _makHubFeePerBooking.toDouble();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Per-hostel queries
  // ─────────────────────────────────────────────────────────────────────────

  /// Revenue for a single hostel.
  /// Hostel earns only the bookingFee portion (UGX 100,000 per confirmed booking).
  Future<double> getHostelRevenue(String hostelId) async {
    final snap = await _db
        .collection('bookings')
        .where('hostelId', isEqualTo: hostelId)
        .where('bookingStatus', isEqualTo: 'confirmed')
        .get();
    return snap.docs.length * _bookingFee.toDouble();
  }

  /// Confirmed booking count for a single hostel.
  Future<int> getHostelBookingCount(String hostelId) async {
    final snap = await _db
        .collection('bookings')
        .where('hostelId', isEqualTo: hostelId)
        .where('bookingStatus', isEqualTo: 'confirmed')
        .get();
    return snap.docs.length;
  }

  /// Full financial summary for a single hostel.
  Future<HostelFinancialSummary> getHostelFinancialSummary(
    String hostelId,
    String hostelName,
  ) async {
    final count = await getHostelBookingCount(hostelId);

    // Hostel earns bookingFee only (UGX 100,000 per booking)
    final revenue = count * _bookingFee.toDouble();

    // MakHub earns serviceFee + mobileMoneyCharge (UGX 12,500 per booking)
    final earnings = count * _makHubFeePerBooking.toDouble();

    return HostelFinancialSummary(
      hostelId: hostelId,
      hostelName: hostelName,
      hostelRevenue: revenue,
      makHubEarnings: earnings,
      confirmedBookingCount: count,
      amountWithdrawn: 0, // withdrawal feature not yet implemented
    );
  }

  /// Resolved booking history for a hostel, sorted newest first.
  /// Every booking is resolved (student name, room, floor) using
  /// cached sub-document reads.
  Future<List<ResolvedBooking>> getBookingHistory(String hostelId) async {
    final bookingsSnap = await _db
        .collection('bookings')
        .where('hostelId', isEqualTo: hostelId)
        .orderBy('bookingDate', descending: true)
        .get();

    // Pre-fetch hostels/{hostelId} once
    final hostelDoc = await _db.collection('hostels').doc(hostelId).get();
    final hostelName =
        (hostelDoc.data()?['hostelName'] ?? 'Unknown Hostel').toString();

    // Cache student, floor, room lookups for this call
    final Map<String, String> studentCache = {};
    final Map<String, Map<String, String>> floorRoomCache = {};

    final List<ResolvedBooking> result = [];

    for (final doc in bookingsSnap.docs) {
      final data = doc.data();

      // Student name
      final studentId = (data['studentId'] ?? '').toString();
      String studentName = 'Unknown Student';
      if (studentId.isNotEmpty) {
        if (studentCache.containsKey(studentId)) {
          studentName = studentCache[studentId]!;
        } else {
          try {
            final sDoc = await _db.collection('users').doc(studentId).get();
            studentName =
                (sDoc.data()?['fullName'] ?? 'Unknown Student').toString();
            studentCache[studentId] = studentName;
          } catch (_) {}
        }
      }

      // Floor + Room
      final floorId = (data['floorId'] ?? '').toString();
      final roomId = (data['roomId'] ?? '').toString();
      String floorName = 'N/A';
      String roomNumber = 'N/A';
      String roomType = 'N/A';

      final cacheKey = '$floorId/$roomId';
      if (floorRoomCache.containsKey(cacheKey)) {
        final cached = floorRoomCache[cacheKey]!;
        floorName = cached['floorName']!;
        roomNumber = cached['roomNumber']!;
        roomType = cached['roomType']!;
      } else if (floorId.isNotEmpty) {
        try {
          final floorDoc = await _db
              .collection('hostels')
              .doc(hostelId)
              .collection('floors')
              .doc(floorId)
              .get();
          floorName = (floorDoc.data()?['floorName'] ??
                  floorDoc.data()?['floorNumber'] ??
                  'N/A')
              .toString();

          if (roomId.isNotEmpty) {
            final roomDoc = await _db
                .collection('hostels')
                .doc(hostelId)
                .collection('floors')
                .doc(floorId)
                .collection('rooms')
                .doc(roomId)
                .get();
            roomNumber =
                (roomDoc.data()?['roomNumber'] ?? 'N/A').toString();
            roomType =
                (roomDoc.data()?['roomType'] ?? 'N/A').toString();
          }
          floorRoomCache[cacheKey] = {
            'floorName': floorName,
            'roomNumber': roomNumber,
            'roomType': roomType,
          };
        } catch (_) {}
      }

      // Booking date
      final ts = data['bookingDate'] as Timestamp?;
      final bookingDate = ts?.toDate() ?? DateTime.now();

      // Amount shown on each booking card = what the student actually paid
      // = bookingFee + mobileMoneyCharge + serviceFee (UGX 112,500)
      final double amountPaid = _totalAmountPerBooking.toDouble();

      // Status
      final status = (data['bookingStatus'] ?? 'confirmed').toString();

      result.add(ResolvedBooking(
        bookingDocId: doc.id,
        shortBookingId: _shortId(doc.id),
        studentName: studentName,
        hostelName: hostelName,
        floorName: floorName,
        roomNumber: roomNumber,
        roomType: roomType,
        bookingStatus: status,
        bookingDate: bookingDate,
        amountPaid: amountPaid,
      ));
    }

    return result;
  }

  /// Groups a list of [ResolvedBooking] by calendar date (newest first).
  List<DailyBookingGroup> groupByDate(List<ResolvedBooking> bookings) {
    final Map<String, List<ResolvedBooking>> map = {};

    for (final b in bookings) {
      final key =
          '${b.bookingDate.year}-${b.bookingDate.month.toString().padLeft(2, '0')}-${b.bookingDate.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(b);
    }

    // Sort by date descending
    final sortedKeys = map.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((key) {
      final parts = key.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return DailyBookingGroup(date: date, bookings: map[key]!);
    }).toList();
  }

  /// Daily revenue for a hostel (today only).
  Future<double> getDailyRevenue(String hostelId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap = await _db
        .collection('bookings')
        .where('hostelId', isEqualTo: hostelId)
        .where('bookingStatus', isEqualTo: 'confirmed')
        .where('bookingDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('bookingDate', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    return snap.docs.length * _bookingFee.toDouble();
  }

  /// In-memory search over a list of resolved bookings.
  /// Matches student name or booking ID (case-insensitive).
  List<ResolvedBooking> searchBookings(
    List<ResolvedBooking> bookings,
    String query,
  ) {
    if (query.trim().isEmpty) return bookings;
    final q = query.trim().toLowerCase();
    return bookings.where((b) {
      return b.studentName.toLowerCase().contains(q) ||
          b.shortBookingId.toLowerCase().contains(q);
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Financial summaries for all hostels (used on the list screen)
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns a [HostelFinancialSummary] for every hostel in one pass.
  /// Loads all confirmed bookings once, then groups them per hostel.
  Future<List<HostelFinancialSummary>> getAllHostelFinancialSummaries() async {
    // Fetch all hostels
    final hostelsSnap = await _db.collection('hostels').get();

    // Fetch all confirmed bookings in one query
    final bookingsSnap = await _db
        .collection('bookings')
        .where('bookingStatus', isEqualTo: 'confirmed')
        .get();

    // Count bookings per hostel
    final Map<String, int> countPerHostel = {};
    for (final doc in bookingsSnap.docs) {
      final data = doc.data();
      final hId = (data['hostelId'] ?? '').toString();
      if (hId.isNotEmpty) {
        countPerHostel[hId] = (countPerHostel[hId] ?? 0) + 1;
      }
    }

    return hostelsSnap.docs.map((hostelDoc) {
      final data = hostelDoc.data();
      final hostelName = (data['hostelName'] ?? 'Unknown Hostel').toString();
      final count = countPerHostel[hostelDoc.id] ?? 0;

      // Hostel earns bookingFee only (UGX 100,000 per booking)
      final revenue = count * _bookingFee.toDouble();

      // MakHub earns serviceFee + mobileMoneyCharge (UGX 12,500 per booking)
      final makHubEarnings = count * _makHubFeePerBooking.toDouble();

      return HostelFinancialSummary(
        hostelId: hostelDoc.id,
        hostelName: hostelName,
        hostelRevenue: revenue,
        makHubEarnings: makHubEarnings,
        confirmedBookingCount: count,
        amountWithdrawn: 0,
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Future withdrawal architecture
  // ─────────────────────────────────────────────────────────────────────────

  /// Prepares the data payload needed to initiate a withdrawal.
  ///
  /// Payment providers (MTN MoMo, bank transfer, etc.) should receive
  /// a [WithdrawalData] object and never interact with Firestore directly.
  /// This ensures FinanceService remains the single source of financial truth.
  ///
  /// [paymentProvider] — pass 'mtn_momo', 'bank_transfer', etc. when ready.
  Future<WithdrawalData> prepareWithdrawalData(
    String hostelId,
    String hostelName, {
    String? paymentProvider,
  }) async {
    final summary = await getHostelFinancialSummary(hostelId, hostelName);

    return WithdrawalData(
      hostelId: hostelId,
      hostelName: hostelName,
      availableBalance: summary.remainingBalance,
      paymentProvider: paymentProvider,
      providerPayload: {
        // Populate these fields when provider integrations are built
        'amount': summary.remainingBalance,
        'currency': 'UGX',
        'hostelId': hostelId,
        'hostelName': hostelName,
        // 'accountNumber': '',  // MTN/Bank account when available
        // 'reference': '',      // transaction reference
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Formatting helpers (exposed for UI convenience)
  // ─────────────────────────────────────────────────────────────────────────

  static String formatUGX(double amount) => _formatUGX(amount);
}
