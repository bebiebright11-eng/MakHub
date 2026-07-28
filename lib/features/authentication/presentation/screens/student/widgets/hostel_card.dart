import 'package:flutter/material.dart';
import '../screens/hostel_details_screen.dart';

class HostelCard extends StatelessWidget {
  final String hostelId;
  final String name;
  /// Area / neighbourhood label, e.g. "Kikoni".
  final String distance;
  final String singlePrice;
  final String doublePrice;
  final String rating;
  /// Raw distance-from-campus string from Firestore, e.g. "0.8 km" or "800m".
  /// Optional — if absent the distance badge is omitted.
  final String? distanceFromCampus;

  const HostelCard({
    super.key,
    required this.hostelId,
    required this.name,
    required this.distance,
    required this.singlePrice,
    required this.doublePrice,
    required this.rating,
    this.distanceFromCampus,
  });

  /// Converts a raw price string (e.g. "700000", "700,000", "350k") to a
  /// compact "K" label like "700K" or "350K".
  /// Returns an empty string when the input cannot be parsed.
  static String _formatPrice(String raw) {
    // Strip everything except digits and dots.
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return '';
    final double? value = double.tryParse(cleaned);
    if (value == null || value == 0) return '';
    // Already stored as a "k" value (e.g. "350") in some docs — treat values
    // below 1000 as already-in-thousands.
    final double thousands = value < 1000 ? value : value / 1000;
    // Show one decimal only when there is a meaningful fractional part.
    final bool hasDecimal = (thousands - thousands.truncateToDouble()).abs() >= 0.05;
    final String formatted = hasDecimal
        ? thousands.toStringAsFixed(1)
        : thousands.round().toString();
    return '${formatted}K';
  }

  /// Formats a distance-from-campus string into a compact campus label,
  /// e.g. "0.8 km"  → "0.8 km from campus"
  ///      "800m"    → "800 m from campus"
  /// Returns null when the input is blank or unparseable.
  static String? _formatCampusDistance(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final s = raw.trim();
    final lower = s.toLowerCase();

    // Metres
    final mMatch = RegExp(r'([\d.]+)\s*m(?:$|\s|eters?)').firstMatch(lower);
    if (mMatch != null) {
      final v = double.tryParse(mMatch.group(1)!);
      if (v != null) {
        final km = v / 1000;
        if (km < 1.0) {
          return '${v.round()} m from campus';
        }
        return '${km.toStringAsFixed(1)} km from campus';
      }
    }

    // Kilometres
    final kmMatch = RegExp(r'([\d.]+)\s*km').firstMatch(lower);
    if (kmMatch != null) {
      final v = double.tryParse(kmMatch.group(1)!);
      if (v != null) {
        if (v < 1.0) {
          return '${(v * 1000).round()} m from campus';
        }
        final bool hasDecimal = (v - v.truncateToDouble()).abs() >= 0.05;
        return '${hasDecimal ? v.toStringAsFixed(1) : v.round()} km from campus';
      }
    }

    // Bare number — assume kilometres
    final bare = double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (bare != null && bare > 0) {
      final bool hasDecimal = (bare - bare.truncateToDouble()).abs() >= 0.05;
      return '${hasDecimal ? bare.toStringAsFixed(1) : bare.round()} km from campus';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String singleK  = _formatPrice(singlePrice);
    final String doubleK  = _formatPrice(doublePrice);
    final String? campusDist = _formatCampusDistance(distanceFromCampus);

    // Build a compact price label:
    //   "700K · 500K"          when both exist
    //   "Single 700K"          when only single exists
    //   "Double 500K"          when only double exists
    //   ""                     when neither exists
    String priceLabel = '';
    if (singleK.isNotEmpty && doubleK.isNotEmpty) {
      priceLabel = 'S $singleK  ·  D $doubleK';
    } else if (singleK.isNotEmpty) {
      priceLabel = 'Single $singleK';
    } else if (doubleK.isNotEmpty) {
      priceLabel = 'Double $doubleK';
    }

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
            // ── Image thumbnail ──────────────────────────────────────────
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
                    child: const Icon(
                      Icons.favorite_border,
                      size: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Name + rating ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 13, color: Colors.black87),
                const SizedBox(width: 2),
                Text(
                  rating,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 2),

            // ── Area / neighbourhood ─────────────────────────────────────
            Text(
              distance,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            const SizedBox(height: 2),

            // ── Distance from campus (optional) ──────────────────────────
            if (campusDist != null)
              Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 11,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      campusDist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 3),

            // ── Prices (single · double) ─────────────────────────────────
            if (priceLabel.isNotEmpty)
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
        ),
      ),
    );
  }
}
