import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/payment_constants.dart';
import '/features/admin/services/finance_service.dart';
import '../../state/app_state.dart';
import 'personnel_withdrawal_request_screen.dart';
import 'personnel_booking_history_screen.dart';
import 'personnel_withdrawal_history_screen.dart';

/// Personnel Finances Screen.
///
/// Scoped entirely to the logged-in hostel personnel's hostelId.
/// Displays:
///   - Available Balance (hostelRevenue - amountWithdrawn)
///   - Pending Bookings count (bookings not yet withdrawn against)
///   - Request Withdrawal button
///   - View Booking History nav card
///   - View Withdrawal History nav card
///
/// All monetary values are calculated from confirmed bookings via
/// [FinanceService] — nothing is hardcoded.
class PersonnelFinancesScreen extends StatefulWidget {
  const PersonnelFinancesScreen({super.key});

  @override
  State<PersonnelFinancesScreen> createState() =>
      _PersonnelFinancesScreenState();
}

class _PersonnelFinancesScreenState extends State<PersonnelFinancesScreen> {
  late Future<_PersonnelFinanceData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_PersonnelFinanceData> _load() async {
    final hostelId = AppState().hostelId;
    final hostelName = AppState().hostelName;

    // Fetch summary (revenue, earnings, booking count) from FinanceService
    final summary = await FinanceService.instance.getHostelFinancialSummary(
      hostelId,
      hostelName,
    );

    // Count total bookings for this hostel (pending withdrawal = confirmed
    // bookings whose revenue has not yet been withdrawn).
    // Withdrawals track number of bookings — so pending = total confirmed
    // minus bookings already counted in approved withdrawals.
    final withdrawnBookings = await _countWithdrawnBookings(hostelId);
    final pendingBookings =
        (summary.confirmedBookingCount - withdrawnBookings).clamp(0, 999999);

    // Available balance = pending bookings × bookingFee
    final availableBalance =
        pendingBookings * PaymentConstants.bookingFee.toDouble();

    return _PersonnelFinanceData(
      summary: summary,
      pendingBookings: pendingBookings,
      availableBalance: availableBalance,
      withdrawnBookings: withdrawnBookings,
    );
  }

  /// Sums numberOfBookings from all APPROVED withdrawal requests for this hostel.
  Future<int> _countWithdrawnBookings(String hostelId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('withdrawal_requests')
          .where('hostelId', isEqualTo: hostelId)
          .where('status', isEqualTo: 'Approved')
          .get();

      int total = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final n = data['numberOfBookings'];
        total += (n is int ? n : int.tryParse(n?.toString() ?? '0') ?? 0);
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  void _refresh() => setState(() => _dataFuture = _load());

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hostelName = AppState().hostelName;

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
              hostelName.isNotEmpty ? hostelName : 'Finances',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const Text(
              'Financial Overview',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<_PersonnelFinanceData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(
                error: snapshot.error.toString(), onRetry: _refresh);
          }

          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section label ──────────────────────────────────
                  _sectionLabel('SUMMARY'),
                  const SizedBox(height: 12),

                  // ── Summary cards row ──────────────────────────────
                  Row(
                    children: [
                      // Card 1 — Available Balance
                      Expanded(
                        child: _SummaryCard(
                          label: 'Available Balance',
                          value: FinanceService.formatUGX(
                              data.availableBalance),
                          icon: Icons.account_balance_wallet_outlined,
                          color: AppColors.primary,
                          subtitle: 'Not yet withdrawn',
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Card 2 — Pending Bookings
                      Expanded(
                        child: _SummaryCard(
                          label: 'Pending Bookings',
                          value:
                              '${data.pendingBookings} Booking${data.pendingBookings == 1 ? '' : 's'}',
                          icon: Icons.bookmark_outline,
                          color: AppColors.accent,
                          subtitle: 'Awaiting withdrawal',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _sectionLabel('ACTIONS'),
                  const SizedBox(height: 12),

                  // ── Request Withdrawal button ──────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: data.pendingBookings == 0
                          ? null
                          : () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PersonnelWithdrawalRequestScreen(
                                    hostelId: AppState().hostelId,
                                    hostelName: AppState().hostelName,
                                    personnelId: AppState().personnelId,
                                    personnelName: AppState().personnelName,
                                    maxBookings: data.pendingBookings,
                                  ),
                                ),
                              );
                              // Refresh summary after returning in case a
                              // withdrawal was submitted.
                              _refresh();
                            },
                      icon: const Icon(Icons.arrow_circle_up_outlined),
                      label: const Text(
                        'Request Withdrawal',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),

                  if (data.pendingBookings == 0) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'No pending bookings to withdraw against.',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  _sectionLabel('HISTORY'),
                  const SizedBox(height: 12),

                  // ── View Booking History card ──────────────────────
                  _NavCard(
                    title: 'View Booking History',
                    subtitle:
                        '${data.summary.confirmedBookingCount} confirmed booking${data.summary.confirmedBookingCount == 1 ? '' : 's'}',
                    icon: Icons.history_edu_outlined,
                    color: AppColors.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonnelBookingHistoryScreen(
                          hostelId: AppState().hostelId,
                          hostelName: AppState().hostelName,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── View Withdrawal History card ───────────────────
                  _NavCard(
                    title: 'View Withdrawal History',
                    subtitle: 'All your withdrawal requests',
                    icon: Icons.receipt_long_outlined,
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonnelWithdrawalHistoryScreen(
                          hostelId: AppState().hostelId,
                          hostelName: AppState().hostelName,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
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
// Data holder
// ─────────────────────────────────────────────────────────────────────────────

class _PersonnelFinanceData {
  final HostelFinancialSummary summary;
  final int pendingBookings;
  final double availableBalance;
  final int withdrawnBookings;

  const _PersonnelFinanceData({
    required this.summary,
    required this.pendingBookings,
    required this.availableBalance,
    required this.withdrawnBookings,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary card
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style:
                  TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation card (Booking History / Withdrawal History)
// ─────────────────────────────────────────────────────────────────────────────

class _NavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Failed to load finances',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
