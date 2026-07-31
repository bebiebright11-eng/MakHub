import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/constants/app_colors.dart';
import '/features/admin/services/finance_service.dart';

/// Personnel Withdrawal History Screen.
///
/// Lists all withdrawal requests submitted by this hostel,
/// sorted newest first. Each card shows:
///   Withdrawal ID, Request Date, Number of Bookings, Amount, Status.
class PersonnelWithdrawalHistoryScreen extends StatelessWidget {
  final String hostelId;
  final String hostelName;

  const PersonnelWithdrawalHistoryScreen({
    super.key,
    required this.hostelId,
    required this.hostelName,
  });

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'N/A';
    final d = ts.toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _shortId(String id) =>
      id.length > 6 ? 'WR-${id.substring(id.length - 5).toUpperCase()}' : 'WR-$id';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hostelName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const Text(
              'Withdrawal History',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Stream withdrawal requests for this hostel, newest first.
        // Using a stream so the list updates automatically when the
        // Admin approves or rejects a request.
        stream: FirebaseFirestore.instance
            .collection('withdrawal_requests')
            .where('hostelId', isEqualTo: hostelId)
            .orderBy('dateRequested', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading withdrawal history:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'No withdrawal requests yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final withdrawalId = _shortId(doc.id);
              final date =
                  _formatDate(data['dateRequested'] as Timestamp?);
              final numberOfBookings = data['numberOfBookings'];
              final bookingCount = numberOfBookings is int
                  ? numberOfBookings
                  : int.tryParse(
                          numberOfBookings?.toString() ?? '0') ??
                      0;
              final amount = (data['amount'] as num?)?.toDouble() ?? 0;
              final status =
                  (data['status'] ?? 'Pending').toString();

              return _WithdrawalCard(
                withdrawalId: withdrawalId,
                date: date,
                bookingCount: bookingCount,
                amount: amount,
                status: status,
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Withdrawal card
// ─────────────────────────────────────────────────────────────────────────────

class _WithdrawalCard extends StatelessWidget {
  final String withdrawalId;
  final String date;
  final int bookingCount;
  final double amount;
  final String status;

  const _WithdrawalCard({
    required this.withdrawalId,
    required this.date,
    required this.bookingCount,
    required this.amount,
    required this.status,
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row — ID + Status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                withdrawalId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Details row
          Row(
            children: [
              // Bookings
              _Detail(
                icon: Icons.bookmark_outline,
                label: 'Bookings',
                value: '$bookingCount',
              ),
              const SizedBox(width: 24),
              // Amount
              _Detail(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Amount',
                value: FinanceService.formatUGX(amount),
                valueColor: Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Date
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                'Requested: $date',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _Detail({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: Colors.grey.shade400)),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
