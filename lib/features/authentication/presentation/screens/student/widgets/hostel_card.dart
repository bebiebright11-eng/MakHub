import 'package:flutter/material.dart';
import '../screens/hostel_details_screen.dart';

class HostelCard extends StatelessWidget {
  final String hostelId;
  final String name;
  final String distance;
  final String singlePrice;
  final String doublePrice;
  final String rating;

  const HostelCard({
    super.key,
    required this.hostelId,
    required this.name,
    required this.distance,
    required this.singlePrice,
    required this.doublePrice,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HostelDetailsScreen(hostelId: hostelId),
          ),
        );
      },
      child: SizedBox(
        width: 170,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 170,
                    width: 170,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.image, size: 32, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border, size: 16, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 13, color: Colors.black87),
                const SizedBox(width: 2),
                Text(rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              distance,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              'UGX $singlePrice · single',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}