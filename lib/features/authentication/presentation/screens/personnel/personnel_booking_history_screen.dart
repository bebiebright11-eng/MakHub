import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import '/features/admin/services/finance_service.dart';
import '../admin/admin_bookings_details_screen.dart';

/// Personnel Booking History Screen.
///
/// Shows confirmed bookings for this hostel, grouped by date.
/// In-memory search by student name or booking ID.
/// Tapping a booking card opens the existing [AdminBookingDetailsScreen].
class PersonnelBookingHistoryScreen extends StatefulWidget {
  final String hostelId;
  final String hostelName;

  const PersonnelBookingHistoryScreen({
    super.key,
    required this.hostelId,
    required this.hostelName,
  });

  @override
  State<PersonnelBookingHistoryScreen> createState() =>
      _PersonnelBookingHistoryScreenState();
}

class _PersonnelBookingHistoryScreenState
    extends State<PersonnelBookingHistoryScreen> {
  late Future<List<ResolvedBooking>> _bookingsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _bookingsFuture = _load();
  }

  Future<List<ResolvedBooking>> _load() =>
      FinanceService.instance.getBookingHistory(widget.hostelId);

  void _refresh() => setState(() => _bookingsFuture = _load());

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

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
              'Booking History',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<ResolvedBooking>>(
        future: _bookingsFuture,
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
                      'Failed to load bookings:\n${snapshot.error}',
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

          final allBookings = snapshot.data ?? [];

          // In-memory filter — no extra Firestore calls
          final filtered = FinanceService.instance
              .searchBookings(allBookings, _searchQuery);

          // Group by date
          final groups = FinanceService.instance.groupByDate(filtered);

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Search bar ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      onChanged: (v) => setState(
                          () => _searchQuery = v.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Search Student or Booking ID...',
                        hintStyle: const TextStyle(
                            fontSize: 14, color: Colors.grey),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
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
                  ),
                ),

                // ── Content ────────────────────────────────────────
                if (allBookings.isEmpty)
                  SliverToBoxAdapter(
                    child: _EmptyState(
                        icon: Icons.book_outlined,
                        message: 'No bookings yet.'),
                  )
                else if (groups.isEmpty)
                  SliverToBoxAdapter(
                    child: _EmptyState(
                        icon: Icons.search_off,
                        message: 'No bookings match your search.'),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                                  builder: (_) =>
                                      AdminBookingDetailsScreen(
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily group
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
        // Date header
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

        // Booking cards under this date
        ...group.bookings.map(
          (b) => _BookingCard(
              booking: b, onTap: () => onBookingTap(b)),
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking card
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

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
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
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'ID: ${booking.shortBookingId}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(message,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
