import 'popularity_service.dart';

/// Popularity signals needed by the Location ranking algorithm.
///
/// All counts default to zero so the algorithm never needs to guard against
/// null — missing Firestore data is treated as zero.
class HostelLocationData {
  /// Firestore document ID of the hostel.
  final String hostelId;

  /// Total confirmed bookings (all-time).
  final int confirmedBookings;

  /// Number of distinct users who have wishlisted this hostel (all-time).
  final int wishlistCount;

  /// Number of distinct users who have viewed this hostel (all-time).
  final int viewCount;

  const HostelLocationData({
    required this.hostelId,
    this.confirmedBookings = 0,
    this.wishlistCount = 0,
    this.viewCount = 0,
  });
}

/// Provides popularity signals for the location-based ranking algorithm.
///
/// The three location sections (Kikumi, Main Gate, Kikoni) need the same
/// signals as "Recommended For You" (confirmed bookings, wishlist count, view
/// count).  Rather than issuing duplicate Firestore queries, this service
/// delegates directly to [PopularityService] and converts the result into
/// [HostelLocationData] objects.
///
/// Usage in the home screen:
///   • Pass the already-fetched [_popularityFuture] into [fromPopularityData].
///   • Zero additional Firestore round-trips.
///   • [LocationRecommendationAlgorithm] operates on [HostelLocationData] so
///     it stays decoupled from [PopularityService] internals.
class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  /// Converts a pre-fetched [popularityMap] into a map of
  /// hostelId → [HostelLocationData].  No Firestore reads are issued.
  Map<String, HostelLocationData> fromPopularityData(
    Map<String, HostelPopularityData> popularityMap,
  ) {
    return {
      for (final entry in popularityMap.entries)
        entry.key: HostelLocationData(
          hostelId:          entry.key,
          confirmedBookings: entry.value.confirmedBookings,
          wishlistCount:     entry.value.wishlistCount,
          viewCount:         entry.value.viewCount,
        ),
    };
  }

  /// Fetches location signals independently when no pre-fetched popularity
  /// data is available.  Prefer [fromPopularityData] to avoid duplicate reads.
  Future<Map<String, HostelLocationData>> fetchLocationData(
    List<String> hostelIds,
  ) async {
    if (hostelIds.isEmpty) return {};
    final popularityMap =
        await PopularityService.instance.fetchPopularityData(hostelIds);
    return fromPopularityData(popularityMap);
  }
}
