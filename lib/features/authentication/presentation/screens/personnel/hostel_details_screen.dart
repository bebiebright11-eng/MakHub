import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HostelDetailsScreen extends StatefulWidget {
  const HostelDetailsScreen({super.key});
  @override
  State<HostelDetailsScreen> createState() => _HostelDetailsScreenState();
}

class _HostelDetailsScreenState extends State<HostelDetailsScreen> {
  late Future<DocumentSnapshot?> _hostelFuture;
  String? _hostelId;

  @override
  void initState() {
    super.initState();
    _hostelFuture = _getHostelForPersonnel();
  }

  Future<DocumentSnapshot?> _getHostelForPersonnel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final personnelQuery = await FirebaseFirestore.instance
        .collection('personnel')
        .where('firebaseUid', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (personnelQuery.docs.isEmpty) return null;

    final hostelId = personnelQuery.docs.first.data()['hostelId'] as String?;
    if (hostelId == null) return null;

    _hostelId = hostelId;

    return FirebaseFirestore.instance.collection('hostels').doc(hostelId).get();
  }

  Future<void> _pickReportingDate(DateTime? currentDate) async {
    if (_hostelId == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (picked == null) return;

    await FirebaseFirestore.instance
        .collection('hostels')
        .doc(_hostelId)
        .update({'reportingDate': Timestamp.fromDate(picked)});

    setState(() {
      _hostelFuture = _getHostelForPersonnel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hostel Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
     body: FutureBuilder<DocumentSnapshot?>(
        future: _hostelFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return const Center(child: Text('No hostel assigned to this account'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final photos = List<String>.from(data['photos'] ?? []);
          final facilities = List<String>.from(data['facilities'] ?? []);
          final rules = List<String>.from(data['rules'] ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hostel Header
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: photos.isNotEmpty
                        ? Image.network(photos[0], fit: BoxFit.cover, width: double.infinity, height: 200)
                        : const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),
                Text(data['hostelName'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(data['location'] ?? '', style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(width: 16),
                    const Icon(Icons.directions_walk, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(data['walkingTime'] ?? '', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Hostel Code (read-only for personnel) ─────────────
                if ((data['hostelCode'] ?? '').toString().isNotEmpty) ...[
                  const Text(
                    'Hostel Code',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tag,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          data['hostelCode'].toString().toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

            // Video Tour Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_circle_fill),
                label: const Text('View Tour Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  data['description'] ?? '',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                ),
                const SizedBox(height: 24),

                const Text('Facilities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                facilities.isEmpty
                    ? Text('No facilities listed', style: TextStyle(color: Colors.grey.shade600))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: facilities.map((f) => _facilityChip(f, Icons.check_circle_outline)).toList(),
                      ),
                const SizedBox(height: 24),

                const Text('Pricing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _priceRow('Single Room', 'UGX ${data['singlePrice'] ?? 0} / Semester'),
                _priceRow('Double Room', 'UGX ${data['doublePrice'] ?? 0} / Semester'),
                const SizedBox(height: 24),

                const Text('Reporting Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final reportingTimestamp = data['reportingDate'] as Timestamp?;
                    final reportingDate = reportingTimestamp?.toDate();

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            reportingDate != null
                                ? '${reportingDate.day}/${reportingDate.month}/${reportingDate.year}'
                                : 'Not set',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextButton.icon(
                            onPressed: () => _pickReportingDate(reportingDate),
                            icon: const Icon(Icons.edit_calendar, size: 18),
                            label: const Text('Change'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                const Text('Hostel Rules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                rules.isEmpty
                    ? Text('No rules listed', style: TextStyle(color: Colors.grey.shade600))
                    : Column(children: rules.map((r) => _ruleItem(r)).toList()),
                const SizedBox(height: 24),

                const Text('Security & Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.security, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Security Rating: ${data['securityRating'] ?? '-'}/5.0', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 8),
                    const Text('Student Reviews: See Reviews collection', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
            
  Widget _facilityChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _priceRow(String type, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(type, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(price, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _ruleItem(String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.grey),
          const SizedBox(width: 8),
          Text(rule, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
