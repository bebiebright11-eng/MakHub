import 'popularity_service.dart';

/// Popularity signals needed by the Budget Friendly scoring algorithm.
///
/// All counts default to zero so the algorithm never needs to guard against
/// null — missing Firestore data is treated as zero.
class HostelBudgetData {
  /// Firestore document ID of the hostel.
  final String hostelId;

  /// Number of confirmed bookings (all-time).
  final int confirmedBookings;

  /// Number of distinct users who have wishlisted this hostel (all-time).
  final int wishlistCount;

  /// Number of distinct users who have viewed this hostel (all-time).
  final int viewCount;

  const HostelBudgetData({
    required this.hostelId,
    this.confirmedBookings = 0,
    this.wishlistCount = 0,
    this.viewCount = 0,
  });
}

/// Provides popularity signals for the "Budget Friendly" scoring algorithm.
///
/// The Budget Friendly section needs the same three signals as the
/// "Recommended For You" section (confirmed bookings, wishlist count, view
/// count).  Rather than issuing duplicate Firestore queries, this service
/// delegates directly to [PopularityService] and converts the result into
/// [HostelBudgetData] objects.
///
/// Benefits:
///   • Zero additional Firestore reads when both sections are rendered on
///     the same screen build — the home screen can share the cached
///     [PopularityService] future and pass it straight through here.
///   • [BudgetRecommendationAlgorithm] works with its own typed model
///     ([HostelBudgetData]) so it stays decoupled from [PopularityService]
///     and can evolve independently (e.g. add a price-tier signal later).
class BudgetService {
  BudgetService._();

  static final BudgetService instance = BudgetService._();

  /// Converts a pre-fetched [popularityMap] (from [PopularityService]) into
  /// a map of hostelId → [HostelBudgetData].
  ///
  /// Call this inside a [FutureBuilder] that already holds the popularity
  /// future so no extra network round-trip is needed.
  Map<String, HostelBudgetData> fromPopularityData(
    Map<String, HostelPopularityData> popularityMap,
  ) {
    return {
      for (final entry in popularityMap.entries)
        entry.key: HostelBudgetData(
          hostelId:          entry.key,
          confirmedBookings: entry.value.confirmedBookings,
          wishlistCount:     entry.value.wishlistCount,
          viewCount:         entry.value.viewCount,
        ),
    };
  }

  /// Fetches popularity signals independently when no pre-fetched data is
  /// available (e.g. if the popularity future has not been initialised yet).
  ///
  /// Prefer [fromPopularityData] to avoid duplicate Firestore reads whenever
  /// the home screen has already fetched the popularity data.
  Future<Map<String, HostelBudgetData>> fetchBudgetData(
    List<String> hostelIds,
  ) async {
    if (hostelIds.isEmpty) return {};
    final popularityMap =
        await PopularityService.instance.fetchPopularityData(hostelIds);
    return fromPopularityData(popularityMap);
  }
}
