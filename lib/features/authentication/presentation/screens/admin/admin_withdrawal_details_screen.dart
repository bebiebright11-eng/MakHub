import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/constants/app_colors.dart';
import '/features/admin/services/finance_service.dart';
import '/features/admin/services/withdrawal_service.dart';

/// Admin Withdrawal Details Screen.
///
/// Shows full details of a single pending withdrawal request and
/// provides an **Approve Withdrawal** button. Approval is delegated
/// entirely to [WithdrawalService.approveWithdrawal] which commits
/// the update, history record, and both notifications atomically.
class AdminWithdrawalDetailsScreen extends StatefulWidget {
  final String requestDocId;
  final Map<String, dynamic> data;

  const AdminWithdrawalDetailsScreen({
    super.key,
    required this.requestDocId,
    required this.data,
  });

  @override
  State<AdminWithdrawalDetailsScreen> createState() =>
      _AdminWithdrawalDetailsScreenState();
}

class _AdminWithdrawalDetailsScreenState
    extends State<AdminWithdrawalDetailsScreen> {
  bool _approving = false;
  double? _availableBalance;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final hostelId = (widget.data['hostelId'] ?? '').toString();
    if (hostelId.isEmpty) return;
    final balance =
        await WithdrawalService.instance.getAvailableBalance(hostelId);
    if (mounted) setState(() => _availableBalance = balance);
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'N/A';
    final d = ts.toDate();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _approve() async {
    setState(() => _approving = true);

    final hostelId = (widget.data['hostelId'] ?? '').toString();
    final hostelName =
        (widget.data['hostelName'] ?? 'Unknown Hostel').toString();
    final personnelId = (widget.data['personnelId'] ?? '').toString();
    final personnelName =
        (widget.data['personnelName'] ?? 'Hostel Personnel').toString();
    final numberOfBookings =
        (widget.data['numberOfBookings'] as num?)?.toInt() ?? 0;
    final amount = (widget.data['amount'] as num?)?.toDouble() ?? 0;
    final requestedAt =
        (widget.data['dateRequested'] as Timestamp?)?.toDate() ??
            DateTime.now();

    final result = await WithdrawalService.instance.approveWithdrawal(
      requestDocId: widget.requestDocId,
      hostelId: hostelId,
      hostelName: hostelName,
      personnelId: personnelId,
      personnelName: personnelName,
      numberOfBookings: numberOfBookings,
      amount: amount,
      requestedAt: requestedAt,
    );

    if (!mounted) return;
    setState(() => _approving = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Withdrawal approved. ${result.withdrawalId}',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approval failed: ${result.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final hostelName = (data['hostelName'] ?? 'Unknown Hostel').toString();
    final personnelName =
        (data['personnelName'] ?? 'Hostel Personnel').toString();
    final numberOfBookings = (data['numberOfBookings'] as num?)?.toInt() ?? 0;
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final requestedAt = data['dateRequested'] as Timestamp?;
    final status = (data['status'] ?? 'Pending').toString();
    final withdrawalId = data['withdrawalId'] as String? ??
        WithdrawalService.generateWithdrawalId(
            widget.requestDocId, requestedAt?.toDate() ?? DateTime.now());

    final isAlreadyApproved = status.toLowerCase() == 'approved';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Withdrawal Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hostel + ID header ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.apartment,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hostelName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              withdrawalId,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(status: status),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _sectionLabel('REQUEST DETAILS'),
            const SizedBox(height: 12),

            // ── Detail rows ────────────────────────────────────────
            _DetailCard(rows: [
              _DetailRow(label: 'Withdrawal ID', value: withdrawalId),
              _DetailRow(label: 'Hostel Name', value: hostelName),
              _DetailRow(label: 'Requested By', value: personnelName),
              _DetailRow(
                  label: 'Number of Bookings',
                  value: numberOfBookings.toString()),
              _DetailRow(
                label: 'Amount Requested',
                value: FinanceService.formatUGX(amount),
                valueColor: Colors.green,
              ),
              _DetailRow(
                label: 'Available Balance',
                value: _availableBalance != null
                    ? FinanceService.formatUGX(_availableBalance!)
                    : 'Calculating…',
                valueColor: AppColors.primary,
              ),
              _DetailRow(
                  label: 'Request Date',
                  value: _formatDate(requestedAt)),
              _DetailRow(label: 'Status', value: status),
            ]),

            const SizedBox(height: 32),

            // ── Approve button ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    (_approving || isAlreadyApproved) ? null : _approve,
                icon: _approving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  isAlreadyApproved
                      ? 'Already Approved'
                      : _approving
                          ? 'Approving…'
                          : 'Approve Withdrawal',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.grey,
          letterSpacing: 0.8,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable detail card
// ─────────────────────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final List<_DetailRow> rows;
  const _DetailCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: rows
            .map((row) => _buildRow(row))
            .expand((w) => [w, const Divider(height: 1)])
            .toList()
          ..removeLast(),
      ),
    );
  }

  Widget _buildRow(_DetailRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            row.label,
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade600),
          ),
          Flexible(
            child: Text(
              row.value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: row.valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow(
      {required this.label, required this.value, this.valueColor});
}

// ─────────────────────────────────────────────────────────────────────────────
// Status badge
// ─────────────────────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
