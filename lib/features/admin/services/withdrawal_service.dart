import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/constants/payment_constants.dart';

/// Handles all withdrawal approval logic for MakHub Admin.
///
/// The single public entry point is [approveWithdrawal].
/// Everything else (balance updates, booking flags, notifications,
/// history records) is committed atomically inside one Firestore
/// batch so either all steps succeed or none do.
class WithdrawalService {
  WithdrawalService._();
  static final WithdrawalService instance = WithdrawalService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Generates a human-readable withdrawal ID from a Firestore doc ID.
  /// e.g. "WDR-20260730-A1B2C3"
  static String generateWithdrawalId(String docId, DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final suffix = docId.length >= 6
        ? docId.substring(docId.length - 6).toUpperCase()
        : docId.toUpperCase();
    return 'WDR-$y$m$d-$suffix';
  }

  /// Calculates the current available balance for a hostel by counting
  /// confirmed bookings and subtracting already-approved withdrawal amounts.
  Future<double> getAvailableBalance(String hostelId) async {
    // Total confirmed bookings × bookingFee
    final bookingsSnap = await _db
        .collection('bookings')
        .where('hostelId', isEqualTo: hostelId)
        .where('bookingStatus', isEqualTo: 'confirmed')
        .get();
    final totalRevenue =
        bookingsSnap.docs.length * PaymentConstants.bookingFee.toDouble();

    // Sum all approved withdrawal amounts
    final approvedSnap = await _db
        .collection('withdrawal_requests')
        .where('hostelId', isEqualTo: hostelId)
        .where('status', isEqualTo: 'Approved')
        .get();

    double totalWithdrawn = 0;
    for (final doc in approvedSnap.docs) {
      final amt = (doc.data()['amount'] as num?)?.toDouble() ?? 0;
      totalWithdrawn += amt;
    }

    return (totalRevenue - totalWithdrawn).clamp(0, double.infinity);
  }

  // ── Core approval ──────────────────────────────────────────────────────

  /// Approves a pending withdrawal request atomically.
  ///
  /// Steps executed in a single Firestore batch:
  ///   A. Update withdrawal_requests/{requestId}.status → 'Approved'
  ///   B. Write a permanent record to withdrawal_requests with approvedAt,
  ///      approvedBy, remainingBalance (balance tracking via status field)
  ///   C. Send a notification to the hostel personnel
  ///   D. Send a notification to the admin (mark request as read)
  ///
  /// Balance and booking counts are derived on-the-fly from Firestore
  /// (confirmed bookings minus approved withdrawals) so no separate
  /// balance document is needed and the numbers are always accurate.
  Future<WithdrawalApprovalResult> approveWithdrawal({
    required String requestDocId,
    required String hostelId,
    required String hostelName,
    required String personnelId,
    required String personnelName,
    required int numberOfBookings,
    required double amount,
    required DateTime requestedAt,
  }) async {
    try {
      final adminUid = FirebaseAuth.instance.currentUser?.uid ?? 'admin';

      // Calculate remaining balance BEFORE this approval so we can store it
      final balanceBefore = await getAvailableBalance(hostelId);
      final remainingBalance =
          (balanceBefore - amount).clamp(0, double.infinity).toDouble();

      // Human-readable withdrawal ID
      final withdrawalId = generateWithdrawalId(requestDocId, requestedAt);

      final batch = _db.batch();

      // ── A. Update the withdrawal_requests document ──────────────────
      final requestRef =
          _db.collection('withdrawal_requests').doc(requestDocId);
      batch.update(requestRef, {
        'status': 'Approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': adminUid,
        'withdrawalId': withdrawalId,
        'remainingBalance': remainingBalance,
      });

      // ── B. Write permanent history to 'withdrawals' collection ──────
      final historyRef = _db.collection('withdrawals').doc();
      batch.set(historyRef, {
        'withdrawalId': withdrawalId,
        'requestDocId': requestDocId,
        'hostelId': hostelId,
        'hostelName': hostelName,
        'personnelId': personnelId,
        'personnelName': personnelName,
        'numberOfBookings': numberOfBookings,
        'amount': amount,
        'status': 'Approved',
        'requestedAt': Timestamp.fromDate(requestedAt),
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': adminUid,
        'remainingBalance': remainingBalance,
      });

      // ── C. Notify hostel personnel ──────────────────────────────────
      if (personnelId.isNotEmpty) {
        final personnelNotifRef = _db
            .collection('users')
            .doc(personnelId)
            .collection('notifications')
            .doc();
        batch.set(personnelNotifRef, {
          'title': 'Withdrawal Approved',
          'subtitle':
              'Your withdrawal request has been approved.\n'
              'Withdrawal ID: $withdrawalId\n'
              'Amount: UGX ${_formatAmount(amount)}\n'
              'Remaining Balance: UGX ${_formatAmount(remainingBalance)}',
          'type': 'withdrawal',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      // ── D. Notify the admin (confirmation in their own feed) ────────
      if (adminUid.isNotEmpty) {
        final adminNotifRef = _db
            .collection('users')
            .doc(adminUid)
            .collection('notifications')
            .doc();
        batch.set(adminNotifRef, {
          'title': 'Withdrawal Approved',
          'subtitle':
              '$hostelName — $withdrawalId approved for UGX ${_formatAmount(amount)}.',
          'type': 'withdrawal',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      await batch.commit();

      return WithdrawalApprovalResult.success(
        withdrawalId: withdrawalId,
        remainingBalance: remainingBalance,
      );
    } catch (e) {
      return WithdrawalApprovalResult.failed(e.toString());
    }
  }

  // ── Formatting helper ──────────────────────────────────────────────────

  static String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final List<String> result = [];
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) result.add(',');
      result.add(parts[i]);
    }
    return result.join();
  }

  static String formatUGX(double amount) => 'UGX ${_formatAmount(amount)}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Result object
// ─────────────────────────────────────────────────────────────────────────────

class WithdrawalApprovalResult {
  final bool success;
  final String? withdrawalId;
  final double? remainingBalance;
  final String? errorMessage;

  const WithdrawalApprovalResult._({
    required this.success,
    this.withdrawalId,
    this.remainingBalance,
    this.errorMessage,
  });

  factory WithdrawalApprovalResult.success({
    required String withdrawalId,
    required double remainingBalance,
  }) =>
      WithdrawalApprovalResult._(
        success: true,
        withdrawalId: withdrawalId,
        remainingBalance: remainingBalance,
      );

  factory WithdrawalApprovalResult.failed(String message) =>
      WithdrawalApprovalResult._(success: false, errorMessage: message);
}
