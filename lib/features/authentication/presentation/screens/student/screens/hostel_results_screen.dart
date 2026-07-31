import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/hostel_card.dart';
import '/algorithms/recommendation_algorithm.dart';
import 'hostel_details_screen.dart';

class HostelResultsScreen extends StatelessWidget {
  final Map<String, dynamic> preferences;

  const HostelResultsScreen({
    super.key,
    required this.preferences,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Results"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('hostels').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hostels available."));
          }

          final ranked = RecommendationAlgorithm.recommendHostels(
            hostels: snapshot.data!.docs,
            preferences: preferences,
          );

          if (ranked.isEmpty) {
            return const Center(child: Text("No matching hostels found."));
          }

          // Split into top matches and "you might also like"
          // ranked is List<HostelRecommendation> — keep it typed so we can
          // show the matchPercent badge on each card.
          final topMatches = ranked.take(5).toList();
          final moreOptions =
              ranked.length > 5 ? ranked.skip(5).toList() : <HostelRecommendation>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Text(
                    "Top Matches",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                ...topMatches.map((r) => _buildLargeHostelCard(context, r.doc, matchPercent: r.matchPercent)),
                if (moreOptions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: const Text(
                      "You might also like",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            rating: ((data['averageRating'] ?? 0.0) as num).toStringAsFixed(1),
                            reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
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

Widget _buildLargeHostelCard(BuildContext context, QueryDocumentSnapshot doc, {int matchPercent = 0}) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['hostelName'] ?? 'Unnamed Hostel';
    final distance = data['location'] ?? '';
    final singlePrice = data['singlePrice'] ?? '0';
    final rating = ((data['averageRating'] ?? 0.0) as num).toStringAsFixed(1);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HostelDetailsScreen(hostelId: doc.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
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
                // Match % badge
                if (matchPercent > 0)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$matchPercent% match',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border, size: 20, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 14, color: Colors.black87),
                const SizedBox(width: 2),
                Text(rating, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              distance,
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