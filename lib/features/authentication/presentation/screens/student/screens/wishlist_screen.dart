import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/wishlist_service.dart';
import '../widgets/hostel_card.dart';
import 'hostel_details_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wishlist',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your saved and recently viewed hostels',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            // ── Favourites section ──────────────────────────────────────────
            const SliverToBoxAdapter(
              child: _SectionHeader(title: 'Favourites', icon: Icons.favorite),
            ),
            _FavouritesSliver(),

            // ── Recently Viewed section ─────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            const SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Recently Viewed',
                icon: Icons.history,
              ),
            ),
            _RecentlyViewedSliver(),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Favourites sliver ─────────────────────────────────────────────────────────

class _FavouritesSliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: WishlistService.instance.favouritesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: _EmptyState(
              icon: Icons.favorite_border,
              message: 'No favourites yet',
              subtitle:
                  'Tap the heart icon on any hostel card to save it here.',
            ),
          );
        }

        return SliverToBoxAdapter(
          child: SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data();
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: HostelCard(
                    hostelId: data['hostelId'] ?? docs[index].id,
                    name: data['hostelName'] ?? '',
                    distance: data['location'] ?? '',
                    singlePrice: data['singlePrice'] ?? '0',
                    doublePrice: data['doublePrice'] ?? '0',
                    rating: '4.5',
                    distanceFromCampus: data['distance']?.toString(),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ── Recently Viewed sliver ────────────────────────────────────────────────────

class _RecentlyViewedSliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: WishlistService.instance.recentlyViewedStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: _EmptyState(
              icon: Icons.history,
              message: 'No recently viewed hostels',
              subtitle: 'Hostels you open will appear here automatically.',
            ),
          );
        }

        // Vertical list of wider cards for recently viewed
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final data = docs[index].data();
              final hostelId = data['hostelId'] ?? docs[index].id;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: _RecentHostelCard(hostelId: hostelId, data: data),
              );
            },
            childCount: docs.length,
          ),
        );
      },
    );
  }
}

// ── Recent hostel card (horizontal layout, full width) ─────────────────────

class _RecentHostelCard extends StatelessWidget {
  final String hostelId;
  final Map<String, dynamic> data;

  const _RecentHostelCard({required this.hostelId, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['hostelName'] ?? '';
    final location = data['location'] ?? '';
    final distance = data['distance']?.toString() ?? '';
    final singlePrice = data['singlePrice'] ?? '';
    final doublePrice = data['doublePrice'] ?? '';
    final photos = List<String>.from(data['photos'] ?? []);
    final imageUrl = photos.isNotEmpty ? photos[0] : null;

    final singleK = HostelCard.staticFormatPrice(singlePrice);
    final doubleK = HostelCard.staticFormatPrice(doublePrice);
    String priceLabel = '';
    if (singleK.isNotEmpty && doubleK.isNotEmpty) {
      priceLabel = 'S $singleK  ·  D $doubleK';
    } else if (singleK.isNotEmpty) {
      priceLabel = 'Single $singleK';
    } else if (doubleK.isNotEmpty) {
      priceLabel = 'Double $doubleK';
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HostelDetailsScreen(hostelId: hostelId),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: Container(
                width: 100,
                height: 90,
                color: Colors.grey.shade200,
                child: imageUrl != null
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : const Center(
                        child: Icon(Icons.image, color: Colors.grey, size: 28),
                      ),
              ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (distance.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 11,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              '$distance from campus',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (priceLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        priceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Chevron
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state widget ────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
