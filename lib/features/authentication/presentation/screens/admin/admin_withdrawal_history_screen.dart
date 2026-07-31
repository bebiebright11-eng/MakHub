import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/constants/app_colors.dart';
import '/features/admin/services/finance_service.dart';
import '/features/admin/services/withdrawal_service.dart';
import 'admin_withdrawal_details_screen.dart';

/// Admin Withdrawal History Screen.
///
/// Streams all approved withdrawal requests, groups them by date,
/// and supports in-memory search by withdrawal ID, hostel name,
/// or personnel name. Tapping a record opens Withdrawal Details.
class AdminWithdrawalHistoryScreen extends StatefulWidget {
  const AdminWithdrawalHistoryScreen({super.key});

  @override
  State<AdminWithdrawalHistoryScreen> createState() =>
      _AdminWithdrawalHistoryScreenState();
}

class _AdminWithdrawalHistoryScreenState
    extends State<AdminWithdrawalHistoryScreen> {
  String _searchQuery = '';

  // ── Grouping helpers ────────────────────────────────────────────────────

  String _dateKey(Timestamp? ts) {
    if (ts == null) return '0000-00-00';
    final d = ts.toDate();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _displayDate(String key) {
    if (key == '0000-00-00') return 'Unknown Date';
    final parts = key.split('-');
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final month = int.tryParse(parts[1]) ?? 1;
    return '${int.tryParse(parts[2]) ?? 0} ${months[month - 1]} ${parts[0]}';
  }

  /// Groups docs by approval date (approvedAt field), newest first.
  List<_DateGroup> _groupByDate(List<QueryDocumentSnapshot> docs) {
    final Map<String, List<QueryDocumentSnapshot>> map = {};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final key = _dateKey(data['approvedAt'] as Timestamp? ??
          data['dateRequested'] as Timestamp?);
      map.putIfAbsent(key, () => []).add(doc);
    }
    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return sortedKeys
        .map((k) => _DateGroup(dateKey: k, docs: map[k]!))
        .toList();
  }

  bool _matches(Map<String, dynamic> data, String docId, String q) {
    if (q.isEmpty) return true;
    final withdrawalId =
        (data['withdrawalId'] ?? WithdrawalService.generateWithdrawalId(
                docId, (data['approvedAt'] as Timestamp?)?.toDate() ?? DateTime.now()))
            .toString()
            .toLowerCase();
    final hostel = (data['hostelName'] ?? '').toString().toLowerCase();
    final personnel = (data['personnelName'] ?? '').toString().toLowerCase();
    return withdrawalId.contains(q) ||
        hostel.contains(q) ||
        personnel.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Withdrawal History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Stream all approved requests; ordering by approvedAt desc.
        // The composite index (status + approvedAt) will be auto-created
        // or Firestore will provide a link if needed.
        stream: FirebaseFirestore.instance
            .collection('withdrawal_requests')
            .where('status', isEqualTo: 'Approved')
            .orderBy('approvedAt', descending: true)
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
                  'Error loading history:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];

          // In-memory search filter
          final filtered = _searchQuery.isEmpty
              ? allDocs
              : allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _matches(data, doc.id, _searchQuery);
                }).toList();

          final groups = _groupByDate(filtered);

          return CustomScrollView(
            slivers: [
              // ── Search bar ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(
                        () => _searchQuery = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText:
                          'Search by ID, hostel or personnel…',
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
              if (allDocs.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history,
                            size: 56, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No approved withdrawals yet.',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                )
              else if (groups.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 56, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No results match your search.',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final group = groups[index];
                        return _DateGroupWidget(
                          dateLabel: _displayDate(group.dateKey),
                          docs: group.docs,
                          onTap: (doc, data) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AdminWithdrawalDetailsScreen(
                                  requestDocId: doc.id,
                                  data: data,
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
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date group widget
// ─────────────────────────────────────────────────────────────────────────────

class _DateGroupWidget extends StatelessWidget {
  final String dateLabel;
  final List<QueryDocumentSnapshot> docs;
  final void Function(QueryDocumentSnapshot, Map<String, dynamic>) onTap;

  const _DateGroupWidget({
    required this.dateLabel,
    required this.docs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Sum total approved amount for this date
    double dayTotal = 0;
    for (final doc in docs) {
      dayTotal +=
          ((doc.data() as Map<String, dynamic>)['amount'] as num?)
                  ?.toDouble() ??
              0;
    }

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
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateLabel,
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
                    FinanceService.formatUGX(dayTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    '${docs.length} withdrawal${docs.length == 1 ? '' : 's'}',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Cards
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _HistoryCard(
            docId: doc.id,
            data: data,
            onTap: () => onTap(doc, data),
          );
        }),

        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History card
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _HistoryCard(
      {required this.docId, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hostelName = (data['hostelName'] ?? 'Unknown Hostel').toString();
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final status = (data['status'] ?? 'Approved').toString();
    final withdrawalId = data['withdrawalId'] as String? ??
        WithdrawalService.generateWithdrawalId(
          docId,
          (data['approvedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );

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
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 20),
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
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    withdrawalId,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  FinanceService.formatUGX(amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.green,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data holder
// ─────────────────────────────────────────────────────────────────────────────

class _DateGroup {
  final String dateKey;
  final List<QueryDocumentSnapshot> docs;
  const _DateGroup({required this.dateKey, required this.docs});
}
