import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/constants/app_colors.dart';
import '/algorithms/occupancy_algorithm.dart';
import '/algorithms/revenue_algorithm.dart';
import '/algorithms/rating_backfill_service.dart';
import 'admin_hostels_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_notification_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_add_hostel_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_finances_screen.dart';
import 'admin_withdrawals_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // ── Live data futures ──────────────────────────────────────────────────
  late Future<_DashboardStats> _statsFuture;

  // ── Rating backfill state ─────────────────────────────────────────────
  bool _backfillRunning = false;
  int  _backfillDone    = 0;
  int  _backfillTotal   = 0;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<_DashboardStats> _loadStats() async {
    // ── Diagnostic loader ─────────────────────────────────────────────────
    // Each query runs independently so a single failure does not hide the
    // others.  Results are logged to the console; the dashboard falls back
    // to safe defaults for any query that fails.

    // ── 1. Hostels ────────────────────────────────────────────────────────
    int hostelCount = 0;
    debugPrint('[Dashboard] Loading hostels...');
    try {
      final snap = await FirebaseFirestore.instance
          .collection('hostels')
          .get();
      hostelCount = snap.docs.length;
      debugPrint('[Dashboard] Hostels ✓  ($hostelCount found)');
    } catch (e, st) {
      debugPrint('[Dashboard] Hostels ✗  FAILED: $e');
      debugPrint(st.toString());
    }

    // ── 2. Occupancy ──────────────────────────────────────────────────────
    OccupancyResult occupancy = const OccupancyResult(
      total: 0, occupied: 0, available: 0, reserved: 0, percentage: 0.0,
    );
    debugPrint('[Dashboard] Loading occupancy (collectionGroup rooms)...');
    try {
      occupancy = await OccupancyAlgorithm.computeAll();
      debugPrint(
        '[Dashboard] Occupancy ✓  '
        '(total=${occupancy.total}, occupied=${occupancy.occupied}, '
        'available=${occupancy.available})',
      );
    } catch (e, st) {
      debugPrint('[Dashboard] Occupancy ✗  FAILED: $e');
      debugPrint(st.toString());
    }

    // ── 3. Revenue ────────────────────────────────────────────────────────
    RevenueResult revenue = RevenueResult(
      total: 0, paymentCount: 0, window: RevenueWindow.daily,
      from: _epoch, to: _epoch,
    );
    debugPrint(
      '[Dashboard] Loading revenue (payments — paymentTime >= today)...',
    );
    try {
      revenue = await RevenueAlgorithm.daily();
      debugPrint(
        '[Dashboard] Revenue ✓  '
        '(${revenue.formattedTotal}, ${revenue.paymentCount} payment(s))',
      );
    } catch (e, st) {
      debugPrint('[Dashboard] Revenue ✗  FAILED: $e');
      debugPrint(st.toString());
    }

    // ── 4. Recent bookings ────────────────────────────────────────────────
    List<QueryDocumentSnapshot> recentBookings = [];
    debugPrint(
      '[Dashboard] Loading bookings '
      '(orderBy bookingDate desc, limit 5)...',
    );
    try {
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('bookingDate', descending: true)
          .limit(5)
          .get();
      recentBookings = snap.docs;
      debugPrint('[Dashboard] Bookings ✓  (${recentBookings.length} found)');
    } catch (e, st) {
      debugPrint('[Dashboard] Bookings ✗  FAILED: $e');
      debugPrint(st.toString());
    }

    debugPrint('[Dashboard] _loadStats complete.');

    return _DashboardStats(
      hostelCount: hostelCount,
      occupancy: occupancy,
      revenue: revenue,
      recentBookings: recentBookings,
    );
  }

  // Safe default DateTime used as a fallback for RevenueResult.
  static final DateTime _epoch = DateTime(2000);

  void _refresh() => setState(() => _statsFuture = _loadStats());

  /// Runs the one-time rating backfill and shows progress + result via
  /// a SnackBar.  Safe to call multiple times — each call re-reads all
  /// reviews from Firestore and overwrites the hostel document values.
  Future<void> _runBackfill() async {
    if (_backfillRunning) return;
    setState(() {
      _backfillRunning = true;
      _backfillDone    = 0;
      _backfillTotal   = 0;
    });

    // Show a persistent "in progress" snack while running.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recalculating ratings… please wait.'),
        duration: Duration(minutes: 5),
      ),
    );

    final result = await RatingBackfillService.instance.runBackfill(
      onProgress: (done, total) {
        if (!mounted) return;
        setState(() {
          _backfillDone  = done;
          _backfillTotal = total;
        });
      },
    );

    if (!mounted) return;
    setState(() => _backfillRunning = false);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: result.failed == 0 ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 6),
        content: Text(
          'Ratings updated ✓  '
          '${result.updated} hostel${result.updated == 1 ? '' : 's'} updated, '
          '${result.noReviews} with no reviews'
          '${result.failed > 0 ? ', ${result.failed} failed' : ''}.',
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'MakHub Admin',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/role-selection',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<_DashboardStats>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final err = snapshot.error.toString();
              // Detect the index-required error specifically so we can give
              // a more actionable message, but show a friendly UI for any error.
              final isIndexError = err.contains('failed-precondition') ||
                  err.contains('index') ||
                  err.contains('FAILED_PRECONDITION');

              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isIndexError
                            ? Icons.cloud_off_outlined
                            : Icons.error_outline,
                        size: 56,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isIndexError
                            ? 'Dashboard unavailable'
                            : 'Failed to load dashboard',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isIndexError
                            ? 'A database configuration issue is preventing the dashboard from loading. Please contact your system administrator.'
                            : 'Something went wrong. Please try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final stats = snapshot.data!;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────
                  const Text(
                    'Welcome, Admin',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Here's what's happening today at MakHub.",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // ── Summary cards ──────────────────────────────────
                  _sectionLabel("TODAY'S SUMMARY"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _summaryCard(
                        stats.hostelCount.toString(),
                        'Total Hostels',
                        Icons.apartment,
                        AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      _summaryCard(
                        stats.occupancy.available.toString(),
                        'Available',
                        Icons.meeting_room,
                        Colors.green,
                      ),
                      const SizedBox(width: 10),
                      _summaryCard(
                        stats.occupancy.occupied.toString(),
                        'Occupied',
                        Icons.people,
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Occupancy + revenue row ────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          title: 'Occupancy',
                          value:
                              '${stats.occupancy.percentage}%',
                          subtitle:
                              '${stats.occupancy.occupied} / ${stats.occupancy.total} rooms',
                          icon: Icons.donut_large,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _metricCard(
                          title: 'Revenue Today',
                          value: stats.revenue.formattedTotal,
                          subtitle:
                              '${stats.revenue.paymentCount} payment${stats.revenue.paymentCount == 1 ? '' : 's'}',
                          icon: Icons.payments_outlined,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Quick actions ──────────────────────────────────
                  _sectionLabel('QUICK ACTIONS'),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.1,
                    children: [
                      _ActionButton('Add Hostel', Icons.add_business, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminAddHostelScreen(),
                          ),
                        );
                      }),
                      _ActionButton('Finances', Icons.account_balance_wallet_outlined, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminFinancesScreen(),
                          ),
                        );
                      }),
                      _ActionButton('Payments', Icons.payment, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminPaymentsScreen(),
                          ),
                        );
                      }),
                      _ActionButton('Hostels', Icons.apartment, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminHostelsScreen(),
                          ),
                        );
                      }),
                      _ActionButton('Notifications', Icons.notifications, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminNotificationsScreen(),
                          ),
                        );
                      }),
                      _WithdrawalActionButton(onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminWithdrawalsScreen(),
                          ),
                        );
                      }),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Recent bookings ────────────────────────────────
                  _sectionLabel('RECENT BOOKINGS'),
                  const SizedBox(height: 12),
                  if (stats.recentBookings.isEmpty)
                    const Text('No recent bookings.',
                        style: TextStyle(color: Colors.grey))
                  else
                    ...stats.recentBookings.map((doc) {
                      final b = doc.data() as Map<String, dynamic>;
                      final status =
                          (b['bookingStatus'] ?? 'pending').toString();
                      final studentId =
                          (b['studentId'] ?? '').toString();
                      final ts =
                          b['bookingDate'] as Timestamp?;
                      final timeAgo = ts != null
                          ? _timeAgo(ts.toDate())
                          : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.calendar_today,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Booking ${doc.id.substring(0, 8)}…',
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                  Text(
                                    'Student: $studentId',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color:
                                            Colors.grey.shade600,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                _statusChip(status),
                                const SizedBox(height: 4),
                                Text(
                                  timeAgo,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 20),

                  // ── System health ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield, color: Colors.green),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'System Health Normal\nAll servers operational.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Maintenance ────────────────────────────────────
                  _sectionLabel('MAINTENANCE'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
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
                        // Title row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.star_rate_outlined,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recalculate All Ratings',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Recomputes averageRating and reviewCount '
                                    'on every hostel document from the '
                                    'reviews collection.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Progress indicator (visible while running)
                        if (_backfillRunning) ...[
                          const SizedBox(height: 14),
                          LinearProgressIndicator(
                            value: _backfillTotal > 0
                                ? _backfillDone / _backfillTotal
                                : null,
                            backgroundColor: Colors.grey.shade200,
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _backfillTotal > 0
                                ? 'Processing $_backfillDone / $_backfillTotal hostels…'
                                : 'Loading hostel list…',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],

                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _backfillRunning ? null : _runBackfill,
                            icon: _backfillRunning
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.refresh, size: 16),
                            label: Text(
                              _backfillRunning
                                  ? 'Running…'
                                  : 'Run Now',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 1:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminHostelsScreen()));
              break;
            case 2:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminBookingsScreen()));
              break;
            case 3:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()));
              break;
            case 4:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminProfileScreen()));
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.apartment), label: 'Hostels'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
            color: Colors.grey, letterSpacing: 0.8),
      );

  Widget _summaryCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'confirmed':
        color = Colors.green;
        break;
      case 'payment_received':
        color = AppColors.primary;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Data holder ──────────────────────────────────────────────────────────────

class _DashboardStats {
  final int hostelCount;
  final OccupancyResult occupancy;
  final RevenueResult revenue;
  final List<QueryDocumentSnapshot> recentBookings;

  const _DashboardStats({
    required this.hostelCount,
    required this.occupancy,
    required this.revenue,
    required this.recentBookings,
  });
}

// ── Action button widget ─────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton(this.title, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Withdrawal action button with live pending badge ─────────────────────────
/// Quick-action tile for Withdrawals that shows a live red badge with
/// the count of pending withdrawal requests.
class _WithdrawalActionButton extends StatelessWidget {
  final VoidCallback onTap;

  const _WithdrawalActionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(14),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('withdrawal_requests')
              .where('status', isEqualTo: 'Pending')
              .snapshots(),
          builder: (context, snapshot) {
            final count = snapshot.data?.docs.length ?? 0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Tile content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_circle_up_outlined,
                          color: AppColors.primary, size: 26),
                      const SizedBox(height: 6),
                      const Text(
                        'Withdrawals',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                // Red badge — only shown when count > 0
                if (count > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
