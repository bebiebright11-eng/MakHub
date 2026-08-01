import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/hostel_card.dart';
import '/algorithms/search_match_algorithm.dart';
import '/models/search_criteria.dart';
import 'hostel_details_screen.dart';

/// Displays the results of a student's active search and shows a Match %
/// badge on each card.
///
/// The Match % is calculated exclusively by [SearchMatchAlgorithm] against
/// the [SearchCriteria] the student just entered.  It never uses saved
/// preferences, default values, or hidden assumptions.
class HostelResultsScreen extends StatelessWidget {
  final SearchCriteria criteria;

  const HostelResultsScreen({
    super.key,
    required this.criteria,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Results'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('hostels').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hostels available.'));
          }

          // Score every hostel against the student's current search criteria.
          final results = SearchMatchAlgorithm.score(
            hostels: snapshot.data!.docs,
            criteria: criteria,
          );

          if (results.isEmpty) {
            return const Center(child: Text('No matching hostels found.'));
          }

          // Top 5 shown as large cards with the Match % badge.
          // The remainder shown in a horizontal "You might also like" row.
          final topMatches = results.take(5).toList();
          final moreOptions = results.length > 5
              ? results.skip(5).toList()
              : <SearchMatchResult>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Top Matches',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                ...topMatches.map(
                  (r) => _SearchResultCard(
                    doc: r.doc,
                    matchPercent: r.matchPercent,
                  ),
                ),
                if (moreOptions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'You might also like',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: moreOptions.length,
                      itemBuilder: (context, index) {
                        final r = moreOptions[index];
                        final data = r.doc.data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: HostelCard(
                            hostelId: r.doc.id,
                            name: data['hostelName'] ?? 'Unnamed Hostel',
                            distance: data['location'] ?? '',
                            singlePrice: data['singlePrice'] ?? '0',
                            doublePrice: data['doublePrice'] ?? '0',
                            rating: ((data['averageRating'] ?? 0.0) as num)
                                .toStringAsFixed(1),
                            reviewCount:
                                (data['reviewCount'] as num?)?.toInt() ?? 0,
                            distanceFromCampus: data['distance']?.toString(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Large result card with Match % badge ─────────────────────────────────────

class _SearchResultCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final int matchPercent;

  const _SearchResultCard({required this.doc, required this.matchPercent});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['hostelName'] ?? 'Unnamed Hostel';
    final location = data['location'] ?? '';
    final singlePrice = data['singlePrice'] ?? '0';
    final rating =
        ((data['averageRating'] ?? 0.0) as num).toStringAsFixed(1);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HostelDetailsScreen(hostelId: doc.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Hostel image placeholder
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
                  ),
                ),

                // Match % badge — only shown when criteria were provided.
                if (matchPercent > 0)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$matchPercent% match',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Wishlist icon
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 20,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Name + rating row
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 14, color: Colors.black87),
                const SizedBox(width: 2),
                Text(
                  rating,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 4),
            Text(
              location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'UGX $singlePrice · single',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
