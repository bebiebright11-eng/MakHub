import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/hostel_details_screen.dart';
import '../services/wishlist_service.dart';

class HostelCard extends StatefulWidget {
  final String hostelId;
  /// Area / neighbourhood label, e.g. "Kikoni".
  final String distance;
  final String name;
  final String singlePrice;
  final String doublePrice;
  final String rating;
  /// Number of reviews for this hostel. Used to render "(41)" next to the
  /// star rating. Pass 0 (default) when not yet known.
  final int reviewCount;
  /// Raw distance-from-campus string from Firestore, e.g. "0.8 km" or "800m".
  /// Optional — if absent the distance badge is omitted.
  final String? distanceFromCampus;

  /// Number of available rooms remaining on this hostel.
  /// When non-null and below 15, a small availability indicator is shown.
  /// Pass null (default) to hide the indicator entirely.
  final int? availableRooms;

  const HostelCard({
    super.key,
    required this.hostelId,
    required this.name,
    required this.distance,
    required this.singlePrice,
    required this.doublePrice,
    required this.rating,
    this.reviewCount = 0,
    this.distanceFromCampus,
    this.availableRooms,
  });

  // ── Public static helpers so other widgets (e.g. WishlistScreen) can
  //    reuse the same formatting logic without duplicating it.

  /// Converts a raw price string (e.g. "700000", "700,000") to a compact
  /// "K" label like "700K".  Returns "" when unparseable.
  static String staticFormatPrice(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return '';
    final double? value = double.tryParse(cleaned);
    if (value == null || value == 0) return '';
    final double thousands = value < 1000 ? value : value / 1000;
    final bool hasDecimal =
        (thousands - thousands.truncateToDouble()).abs() >= 0.05;
    final String formatted =
        hasDecimal ? thousands.toStringAsFixed(1) : thousands.round().toString();
    return '${formatted}K';
  }

  /// Formats a raw distance string to "X km from campus" / "X m from campus".
  /// Returns null when blank or unparseable.
  static String? staticFormatCampusDistance(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final s = raw.trim();
    final lower = s.toLowerCase();

    final mMatch = RegExp(r'([\d.]+)\s*m(?:$|\s|eters?)').firstMatch(lower);
    if (mMatch != null) {
      final v = double.tryParse(mMatch.group(1)!);
      if (v != null) {
        final km = v / 1000;
        if (km < 1.0) return '${v.round()} m from campus';
        return '${km.toStringAsFixed(1)} km from campus';
      }
    }

    final kmMatch = RegExp(r'([\d.]+)\s*km').firstMatch(lower);
    if (kmMatch != null) {
      final v = double.tryParse(kmMatch.group(1)!);
      if (v != null) {
        if (v < 1.0) return '${(v * 1000).round()} m from campus';
        final bool hasDecimal = (v - v.truncateToDouble()).abs() >= 0.05;
        return '${hasDecimal ? v.toStringAsFixed(1) : v.round()} km from campus';
      }
    }

    final bare =
        double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (bare != null && bare > 0) {
      final bool hasDecimal = (bare - bare.truncateToDouble()).abs() >= 0.05;
      return '${hasDecimal ? bare.toStringAsFixed(1) : bare.round()} km from campus';
    }

    return null;
  }

  @override
  State<HostelCard> createState() => _HostelCardState();
}

class _HostelCardState extends State<HostelCard> {
  bool _isFavourite = false;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _loadFavouriteState();
  }

  Future<void> _loadFavouriteState() async {
    final result =
        await WishlistService.instance.isFavourite(widget.hostelId);
    if (mounted) setState(() => _isFavourite = result);
  }

  Future<void> _onHeartTap() async {
    if (_toggling) return;
    setState(() => _toggling = true);

    // Fetch the minimal hostel data needed for the wishlist snapshot.
    // We use whatever we already have from the widget params first, and
    // fall back to a single Firestore get only for the fields we don't have.
    Map<String, dynamic> hostelData = {
      'hostelName': widget.name,
      'location': widget.distance,
      'distance': widget.distanceFromCampus ?? '',
      'singlePrice': widget.singlePrice,
      'doublePrice': widget.doublePrice,
      'photos': <String>[],
    };

    try {
      final doc = await FirebaseFirestore.instance
          .collection('hostels')
          .doc(widget.hostelId)
          .get();
      if (doc.exists) {
        hostelData = doc.data()!;
      }
    } catch (_) {
      // Use the widget-param snapshot if Firestore is unreachable.
    }

    final nowFavourite = await WishlistService.instance.toggleFavourite(
      widget.hostelId,
      hostelData,
    );

    if (mounted) {
      setState(() {
        _isFavourite = nowFavourite;
        _toggling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String singleK = HostelCard.staticFormatPrice(widget.singlePrice);
    final String doubleK = HostelCard.staticFormatPrice(widget.doublePrice);
    final String? campusDist =
        HostelCard.staticFormatCampusDistance(widget.distanceFromCampus);

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
          builder: (_) => HostelDetailsScreen(hostelId: widget.hostelId),
        ),
      ),
      child: SizedBox(
        width: 170,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image thumbnail ────────────────────────────────────────────
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
                // Rating badge — top-left
                Positioned(
                  top: 8,
                  left: 8,
                  child: _RatingBadge(
                    rating: widget.rating,
                    reviewCount: widget.reviewCount,
                  ),
                ),
                // Heart / favourite button — top-right
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: _onHeartTap,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _toggling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.red,
                              ),
                            )
                          : Icon(
                              _isFavourite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 16,
                              color: _isFavourite
                                  ? Colors.red
                                  : Colors.black87,
                            ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Name ──────────────────────────────────────────────────────
            Text(
              widget.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),

            const SizedBox(height: 2),

            // ── Area / neighbourhood ───────────────────────────────────────
            Text(
              widget.distance,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            const SizedBox(height: 2),

            // ── Distance from campus (optional) ───────────────────────────
            if (campusDist != null)
              Row(
                children: [
                  Icon(Icons.place_outlined,
                      size: 11, color: Colors.grey.shade500),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      campusDist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11),
                    ),
                  ),
                ],
              ),

            // ── Availability indicator (optional) ─────────────────────────
            // Shown only when availableRooms is non-null and below 15.
            // Orange for 4–14 rooms remaining; red for 3 or fewer.
            if (widget.availableRooms != null &&
                widget.availableRooms! < 15) ...[
              const SizedBox(height: 3),
              _AvailabilityIndicator(rooms: widget.availableRooms!),
            ],

            const SizedBox(height: 3),

            // ── Prices (single · double) ───────────────────────────────────
            if (priceLabel.isNotEmpty)
              Text(
                priceLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable rating badge — ⭐ 4.8 (41) or ⭐ New
// Used on every hostel card image overlay (top-left).
// ─────────────────────────────────────────────────────────────────────────────

class _RatingBadge extends StatelessWidget {
  final String rating;
  final int reviewCount;

  const _RatingBadge({required this.rating, required this.reviewCount});

  @override
  Widget build(BuildContext context) {
    final double parsed = double.tryParse(rating) ?? 0;
    // Always show numeric format: "4.8 (41)" or "0.0 (0)" — never "New"
    final String label = '${parsed.toStringAsFixed(1)} ($reviewCount)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        // Orange badge matching the reference screenshot
        color: const Color(0xFFFF8A00),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Availability indicator — shown when a hostel has fewer than 15 rooms left.
//
// Colour rules:
//   ≤  3 rooms  → red    ("Only 3 rooms remaining")
//   4–14 rooms  → orange ("8 rooms remaining")
//   ≥ 15 rooms  → hidden (caller must gate on availableRooms < 15)
// ─────────────────────────────────────────────────────────────────────────────

class _AvailabilityIndicator extends StatelessWidget {
  final int rooms;

  const _AvailabilityIndicator({required this.rooms});

  @override
  Widget build(BuildContext context) {
    // Colour: red for critically low (≤ 3), orange accent otherwise.
    final Color indicatorColor =
        rooms <= 3 ? const Color(0xFFE53935) : const Color(0xFFFF8A00);

    // Label: highlight urgency when critically low.
    final String label =
        rooms <= 3 ? 'Only $rooms room${rooms == 1 ? '' : 's'} remaining'
                   : '$rooms rooms remaining';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.meeting_room_outlined, size: 11, color: indicatorColor),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: indicatorColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
