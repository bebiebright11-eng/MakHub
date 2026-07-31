import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import '/features/admin/services/finance_service.dart';
import 'admin_hostel_finance_details_screen.dart';
import 'admin_notification_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_hostels_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_dashboard_screen.dart';

/// Admin Finances — Screen 1.
///
/// Displays three platform-level summary cards, a hostel search bar,
/// and a list of every hostel with its individual financial summary.
/// All data flows through [FinanceService]; no Firestore calls in this file.
class AdminFinancesScreen extends StatefulWidget {
  const AdminFinancesScreen({super.key});

  @override
  State<AdminFinancesScreen> createState() => _AdminFinancesScreenState();
}

class _AdminFinancesScreenState extends State<AdminFinancesScreen> {
  // ── State ────────────────────────────────────────────────────────────────
  late Future<_FinancesData> _dataFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_FinancesData> _load() async {
    final platform =
        await FinanceService.instance.getTotalHostelRevenue();
    final hostels =
        await FinanceService.instance.getAllHostelFinancialSummaries();
    // Sort hostels by revenue descending so busiest hostels appear first
    hostels.sort((a, b) => b.hostelRevenue.compareTo(a.hostelRevenue));
    return _FinancesData(platform: platform, hostels: hostels);
  }

  void _refresh() => setState(() => _dataFuture = _load());

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Finances',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<_FinancesData>(
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

          // Filter hostels in memory — no extra Firestore call
          final filtered = _searchQuery.isEmpty
              ? data.hostels
              : data.hostels
                  .where((h) => h.hostelName
                      .toLowerCase()
                      .contains(_searchQuery))
                  .toList();

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Platform summary cards ───────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('PLATFORM SUMMARY'),
                        const SizedBox(height: 12),
                        // Row 1 — Revenue + MakHub Earnings
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryCard(
                                label: 'Total Hostel Revenue',
                                value: FinanceService.formatUGX(
                                    data.platform.totalHostelRevenue),
                                icon: Icons.account_balance_wallet_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryCard(
                                label: 'MakHub Earnings',
                                value: FinanceService.formatUGX(
                                    data.platform.makHubEarnings),
                                icon: Icons.trending_up,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Row 2 — Registered Hostels (full width)
                        _SummaryCard(
                          label: 'Registered Hostels',
                          value: data.platform.hostelCount.toString(),
                          icon: Icons.apartment_outlined,
                          color: AppColors.accent,
                          fullWidth: true,
                          subtitle:
                              '${data.platform.confirmedBookingCount} confirmed booking${data.platform.confirmedBookingCount == 1 ? '' : 's'} across all hostels',
                        ),
                        const SizedBox(height: 24),
                        _sectionLabel('HOSTEL FINANCES'),
                        const SizedBox(height: 12),
                        // Search bar
                        TextField(
                          onChanged: (v) => setState(
                              () => _searchQuery = v.trim().toLowerCase()),
                          decoration: InputDecoration(
                            hintText: 'Search hostel...',
                            hintStyle: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                            prefixIcon: const Icon(Icons.search,
                                color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // ── Hostel financial list ────────────────────────────
                filtered.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 48),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off,
                                    size: 56,
                                    color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text(
                                  'No hostels match your search.',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final h = filtered[index];
                              return _HostelFinanceCard(
                                summary: h,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AdminHostelFinanceDetailsScreen(
                                        hostelId: h.hostelId,
                                        hostelName: h.hostelName,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            childCount: filtered.length,
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Finances is a quick-action screen, not bottom-nav
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminDashboardScreen()),
                (route) => false,
              );
              break;
            case 1:
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminHostelsScreen()));
              break;
            case 2:
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminBookingsScreen()));
              break;
            case 3:
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminNotificationsScreen()));
              break;
            case 4:
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminProfileScreen()));
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.apartment), label: 'Hostels'),
          BottomNavigationBarItem(
              icon: Icon(Icons.book), label: 'Bookings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
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
// Private data holder
// ─────────────────────────────────────────────────────────────────────────────

class _FinancesData {
  final PlatformFinancialSummary platform;
  final List<HostelFinancialSummary> hostels;
  const _FinancesData({required this.platform, required this.hostels});
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary card widget
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool fullWidth;
  final String? subtitle;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: fullWidth ? double.infinity : null,
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
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
                  label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: fullWidth ? 20 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    return card;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hostel financial card
// ─────────────────────────────────────────────────────────────────────────────

class _HostelFinanceCard extends StatelessWidget {
  final HostelFinancialSummary summary;
  final VoidCallback onTap;

  const _HostelFinanceCard({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Header row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.apartment,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    summary.hostelName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // Booking count badge (orange)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${summary.confirmedBookingCount} Booking${summary.confirmedBookingCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right,
                    color: Colors.grey, size: 18),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Finance figures row
            Row(
              children: [
                Expanded(
                  child: _FinanceFigure(
                    label: 'Hostel Revenue',
                    value: FinanceService.formatUGX(summary.hostelRevenue),
                    color: AppColors.primary,
                  ),
                ),
                Container(
                    width: 1, height: 36, color: Colors.grey.shade200),
                Expanded(
                  child: _FinanceFigure(
                    label: 'MakHub Earnings',
                    value:
                        FinanceService.formatUGX(summary.makHubEarnings),
                    color: Colors.green,
                    align: CrossAxisAlignment.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceFigure extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final CrossAxisAlignment align;

  const _FinanceFigure({
    required this.label,
    required this.value,
    required this.color,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
