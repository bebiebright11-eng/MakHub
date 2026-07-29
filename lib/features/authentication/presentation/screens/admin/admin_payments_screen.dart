import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_payment_details_screen.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  String _selectedFilter = "All";
  String _searchQuery = "";

  // Cache resolved payment details so the stream doesn't re-fetch on rebuild
  final Map<String, Map<String, String>> _detailsCache = {};

  // Resolve student, hostel and room info via the linked booking document
  Future<Map<String, String>> _resolvePayment(
      QueryDocumentSnapshot doc) async {
    if (_detailsCache.containsKey(doc.id)) return _detailsCache[doc.id]!;

    final data = doc.data() as Map<String, dynamic>;
    final firestore = FirebaseFirestore.instance;

    String studentName = 'Unknown Student';
    String hostelName = 'Unknown Hostel';
    String roomNumber = 'N/A';
    String balance = 'N/A';

    try {
      final bookingId = (data['bookingId'] ?? '').toString();
      if (bookingId.isNotEmpty) {
        final bookingDoc =
            await firestore.collection('bookings').doc(bookingId).get();
        final booking = bookingDoc.data();

        final studentId = (booking?['studentId'] ?? '').toString();
        if (studentId.isNotEmpty) {
          final studentDoc =
              await firestore.collection('users').doc(studentId).get();
          studentName =
              (studentDoc.data()?['fullName'] ?? 'Unknown Student').toString();
        }

        final hostelId = (booking?['hostelId'] ?? '').toString();
        final floorId = (booking?['floorId'] ?? '').toString();
        final roomId = (booking?['roomId'] ?? '').toString();

        if (hostelId.isNotEmpty) {
          final hostelDoc =
              await firestore.collection('hostels').doc(hostelId).get();
          final hostel = hostelDoc.data();
          hostelName = (hostel?['hostelName'] ?? 'Unknown Hostel').toString();

          if (floorId.isNotEmpty && roomId.isNotEmpty) {
            final roomDoc = await firestore
                .collection('hostels')
                .doc(hostelId)
                .collection('floors')
                .doc(floorId)
                .collection('rooms')
                .doc(roomId)
                .get();
            final room = roomDoc.data();
            roomNumber = (room?['roomNumber'] ?? 'N/A').toString();

            // Remaining balance = room price - amount paid on this record
            final roomType = (room?['roomType'] ?? '').toString();
            final priceRaw = hostel == null
                ? null
                : (roomType == 'Single'
                    ? hostel['singlePrice']
                    : hostel['doublePrice']);
            final roomPrice = int.tryParse(priceRaw?.toString() ?? '');
            final paid = _amountOf(data);
            if (roomPrice != null && paid != null) {
              balance = 'UGX ${roomPrice - paid}';
            }
          }
        }
      }
    } catch (_) {
      // Keep fallbacks if any lookup fails
    }

    final resolved = {
      'studentName': studentName,
      'hostelName': hostelName,
      'roomNumber': roomNumber,
      'balance': balance,
    };
    _detailsCache[doc.id] = resolved;
    return resolved;
  }

  int? _amountOf(Map<String, dynamic> data) {
    final raw = data['amount'];
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'N/A';
    final d = ts.toDate();
    return "${d.day}/${d.month}/${d.year}";
  }

  String _statusLabel(String raw) {
    if (raw.isEmpty) return 'Pending';
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  // Compact UGX formatting for the stat cards (e.g. UGX 1.2M, UGX 300K)
  String _formatCompact(int amount) {
    if (amount >= 1000000) {
      return "UGX ${(amount / 1000000).toStringAsFixed(1)}M";
    }
    if (amount >= 1000) {
      return "UGX ${(amount / 1000).toStringAsFixed(1)}K";
    }
    return "UGX $amount";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payments"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('payments').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                  child: Text('Error loading payments: ${snapshot.error}'));
            }

            final allDocs = snapshot.data?.docs ?? [];

            // Live stat totals computed from the full payment records
            int confirmedTotal = 0;
            int pendingTotal = 0;
            for (final doc in allDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final status = (data['paymentStatus'] ?? data['status'] ?? '')
                  .toString()
                  .toLowerCase();
              final amount = _amountOf(data) ?? 0;
              if (status == 'confirmed') {
                confirmedTotal += amount;
              } else if (status == 'pending') {
                pendingTotal += amount;
              }
            }

            // Sort newest first (client-side so docs missing paymentTime still show)
            final docs = allDocs.toList()
              ..sort((a, b) {
                final ta = (a.data() as Map<String, dynamic>)['paymentTime']
                    as Timestamp?;
                final tb = (b.data() as Map<String, dynamic>)['paymentTime']
                    as Timestamp?;
                if (ta == null && tb == null) return 0;
                if (ta == null) return 1;
                if (tb == null) return -1;
                return tb.compareTo(ta);
              });

            // Apply status filter
            final filtered = docs.where((doc) {
              if (_selectedFilter == "All") return true;
              final data = doc.data() as Map<String, dynamic>;
              final status =
                  (data['paymentStatus'] ?? data['status'] ?? 'pending')
                      .toString()
                      .toLowerCase();
              return status == _selectedFilter.toLowerCase();
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Track collected revenue, pending balances, and student payments.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    _statCard(_formatCompact(confirmedTotal),
                        "Total\nPayments", AppColors.primary),
                    const SizedBox(width: 10),
                    _statCard(_formatCompact(pendingTotal),
                        "Pending\nClearance", Colors.orange),
                    const SizedBox(width: 10),
                    _statCard(
                        "${allDocs.length}", "Payment\nRecords", Colors.green),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  onChanged: (value) {
                    setState(() => _searchQuery = value.trim().toLowerCase());
                  },
                  decoration: InputDecoration(
                    hintText: "Search payments...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _filterChip("All"),
                      const SizedBox(width: 8),
                      _filterChip("Pending"),
                      const SizedBox(width: 8),
                      _filterChip("Confirmed"),
                      const SizedBox(width: 8),
                      _filterChip("Rejected"),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            _selectedFilter == "All"
                                ? "No payment records yet"
                                : "No ${_selectedFilter.toLowerCase()} payments",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final doc = filtered[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final status = _statusLabel(
                                (data['paymentStatus'] ??
                                        data['status'] ??
                                        'pending')
                                    .toString());
                            final amount = _amountOf(data);
                            final amountLabel =
                                amount != null ? 'UGX $amount' : 'N/A';
                            final date = _formatDate(
                                data['paymentTime'] as Timestamp?);
                            final reference = doc.id.length > 6
                                ? doc.id.substring(doc.id.length - 6)
                                : doc.id;
                            final method = (data['paymentMethod'] ??
                                    (data['mobileNumber'] != null
                                        ? 'Mobile Money'
                                        : 'N/A'))
                                .toString();

                            return FutureBuilder<Map<String, String>>(
                              future: _resolvePayment(doc),
                              builder: (context, detailsSnapshot) {
                                final details = detailsSnapshot.data;

                                if (details == null) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                  );
                                }

                                // Apply search on resolved student/hostel names
                                if (_searchQuery.isNotEmpty &&
                                    !details['studentName']!
                                        .toLowerCase()
                                        .contains(_searchQuery) &&
                                    !details['hostelName']!
                                        .toLowerCase()
                                        .contains(_searchQuery)) {
                                  return const SizedBox.shrink();
                                }

                                return _paymentCard(
                                  context: context,
                                  name: details['studentName']!,
                                  hostelRoom:
                                      "${details['hostelName']} • Room ${details['roomNumber']}",
                                  amount: amountLabel,
                                  date: date,
                                  reference: reference,
                                  status: status,
                                  balance: details['balance']!,
                                  method: method,
                                  paymentDocId: doc.id,
                                  bookingId:
                                      (data['bookingId'] ?? '').toString(),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final selected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _paymentCard({
    required BuildContext context,
    required String name,
    required String hostelRoom,
    required String amount,
    required String date,
    required String reference,
    required String status,
    required String balance,
    required String method,
    required String paymentDocId,
    required String bookingId,
  }) {
    Color statusColor;
    if (status == "Confirmed") {
      statusColor = Colors.green;
    } else if (status == "Pending") {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(hostelRoom, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text("Ref: $reference", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminPaymentDetailsScreen(
                      studentName: name,
                      hostelRoom: hostelRoom,
                      amount: amount,
                      status: status,
                      balance: balance,
                      method: method,
                      reference: reference,
                      paymentDocId: paymentDocId,
                      bookingId: bookingId,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text("View Details"),
            ),
          ),
        ],
      ),
    );
  }
}
