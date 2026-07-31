import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import '/features/admin/services/finance_service.dart';
import 'admin_bookings_details_screen.dart';

/// Admin Finances — Screen 2 (Hostel Financial Details).
///
/// Shows three summary cards for one hostel, then booking history
/// grouped by date. A search bar filters bookings by student name
/// or booking ID entirely in memory — no extra Firestore calls.
class AdminHostelFinanceDetailsScreen extends StatefulWidget {
  final String hostelId;
  final String hostelName;

  const AdminHostelFinanceDetailsScreen({
    super.key,
    required this.hostelId,
    required this.hostelName,
  });

  @override
  State<AdminHostelFinanceDetailsScreen> createState() =>
      _AdminHostelFinanceDetailsScreenState();
}

class _AdminHostelFinanceDetailsScreenState
    extends State<AdminHostelFinanceDetailsScreen> {
  // ── State ────────────────────────────────────────────────────────────────
  late Future<_HostelFinanceData> _dataFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_HostelFinanceData> _load() async {
    final summary = await FinanceService.instance.getHostelFinancialSummary(
      widget.hostelId,
      widget.hostelName,
    );
    final bookings =
        await FinanceService.instance.getBookingHistory(widget.hostelId);
    return _HostelFinanceData(summary: summary, bookings: bookings);
  }

  void _refresh() => setState(() => _dataFuture = _load());

  // ── Build ────────────────────────────────────────────────────────────────
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
              widget.hostelName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const Text(
              'Financial Details',
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
      body: FutureBuilder<_HostelFinanceData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load data:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final summary = data.summary;

          // Apply in-memory search filter
          final filteredBookings = FinanceService.instance
              .searchBookings(data.bookings, _searchQuery);

          // Group filtered bookings by date for display
          final groups =
              FinanceService.instance.groupByDate(filteredBookings);

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Hostel summary cards ──────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('HOSTEL SUMMARY'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniSummaryCard(
                                label: 'Hostel Revenue',
                                value: FinanceService.formatUGX(
                                    summary.hostelRevenue),
                                icon: Icons.account_balance_wallet_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniSummaryCard(
                                label: 'MakHub Earnings',
                                value: FinanceService.formatUGX(
                                    summary.makHubEarnings),
                                icon: Icons.trending_up,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniSummaryCard(
                                label: 'Total Bookings',
                                value: summary.confirmedBookingCount
                                    .toString(),
                                icon: Icons.bookmark_outline,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _sectionLabel('BOOKING HISTORY'),
                        const SizedBox(height: 12),

                        // Search bar
                        TextField(
                          onChanged: (v) => setState(
                              () => _searchQuery = v.trim().toLowerCase()),
                          decoration: InputDecoration(
                            hintText: 'Search Student or Booking ID...',
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

                // ── Booking history grouped by date ──────────────
                if (data.bookings.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.book_outlined,
                                size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'No bookings yet.',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (groups.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'No bookings match your search.',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final group = groups[index];
                          return _DailyGroup(
                            group: group,
                            onBookingTap: (booking) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminBookingDetailsScreen(
                                    studentName: booking.studentName,
                                    hostel: booking.hostelName,
                                    floor: booking.floorName,
                                    roomNumber: booking.roomNumber,
                                    roomType: booking.roomType,
                                    bookingStatus: _capitalize(
                                        booking.bookingStatus),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        childCount: groups.length,
                      ),
                    ),
                  ),
              ],
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

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private data holder
// ─────────────────────────────────────────────────────────────────────────────

class _HostelFinanceData {
  final HostelFinancialSummary summary;
  final List<ResolvedBooking> bookings;
  const _HostelFinanceData({required this.summary, required this.bookings});
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini summary card (3-across layout)
// ─────────────────────────────────────────────────────────────────────────────

class _MiniSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily group header + booking cards
// ─────────────────────────────────────────────────────────────────────────────

class _DailyGroup extends StatelessWidget {
  final DailyBookingGroup group;
  final void Function(ResolvedBooking) onBookingTap;

  const _DailyGroup({required this.group, required this.onBookingTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header card
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 15, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.displayDate,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    group.formattedRevenue,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    '${group.count} Booking${group.count == 1 ? '' : 's'}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Booking cards for this date
        ...group.bookings
            .map((booking) => _BookingCard(
                  booking: booking,
                  onTap: () => onBookingTap(booking),
                )),

        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual booking card
// ─────────────────────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final ResolvedBooking booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderGrey),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),

            // Main info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student name + status badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking.studentName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      _StatusBadge(status: booking.bookingStatus),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Room
                  Row(
                    children: [
                      const Icon(Icons.meeting_room_outlined,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Room ${booking.roomNumber}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        booking.formattedDate,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Booking ID + amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ID: ${booking.shortBookingId}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        booking.formattedAmount,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status badge chip
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    Color color;
    if (normalized == 'confirmed') {
      color = Colors.green;
    } else if (normalized == 'room reserved') {
      color = AppColors.accent;
    } else {
      color = Colors.grey;
    }

    final label = status.isEmpty
        ? 'Confirmed'
        : status[0].toUpperCase() + status.substring(1).toLowerCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
