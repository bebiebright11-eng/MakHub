import 'package:cloud_firestore/cloud_firestore.dart';
import 'hostel_rating_algorithm.dart';

/// Result summary returned after a full backfill run.
class BackfillResult {
  /// Number of hostels whose ratings were successfully updated.
  final int updated;

  /// Number of hostels that had no reviews (averageRating set to 0.0).
  final int noReviews;

  /// Number of hostels that failed due to a Firestore error.
  final int failed;

  /// Total hostels processed.
  int get total => updated + noReviews + failed;

  const BackfillResult({
    required this.updated,
    required this.noReviews,
    required this.failed,
  });

  @override
  String toString() =>
      'BackfillResult(total=$total, updated=$updated, '
      'noReviews=$noReviews, failed=$failed)';
}

/// One-time utility that recalculates and persists [averageRating] and
/// [reviewCount] for every hostel in Firestore.
///
/// ── Why this is needed ────────────────────────────────────────────────────
/// Previously [HostelRatingAlgorithm.computeAndSave] read from the wrong
/// Firestore path (`hostels/{id}/reviews` sub-collection instead of the
/// top-level `reviews` collection).  As a result, all hostel documents were
/// written with `averageRating: 0.0` and `reviewCount: 0` even though real
/// review documents existed — which caused the "⭐ 0.0 (0)" badge.
///
/// Running this backfill once corrects all stale values.  Going forward,
/// [computeAndSave] is called automatically after every review submit/edit
/// so backfill should never be needed again.
///
/// ── Safety ────────────────────────────────────────────────────────────────
/// Each hostel is processed sequentially to avoid overwhelming Firestore
/// with parallel writes.  Errors on individual hostels are caught and counted
/// so one bad document does not abort the whole run.
///
/// ── Usage ────────────────────────────────────────────────────────────────
///   final result = await RatingBackfillService.instance.runBackfill(
///     onProgress: (done, total) { /* update progress UI */ },
///   );
class RatingBackfillService {
  RatingBackfillService._();

  static final RatingBackfillService instance = RatingBackfillService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Recalculates ratings for every hostel document.
  ///
  /// [onProgress] is called after each hostel is processed with
  /// (completedCount, totalCount) so the UI can show a progress indicator.
  Future<BackfillResult> runBackfill({
    void Function(int completed, int total)? onProgress,
  }) async {
    // ── 1. Fetch all hostel document IDs ──────────────────────────────────
    final hostelsSnap = await _db.collection('hostels').get();
    final hostelIds = hostelsSnap.docs.map((d) => d.id).toList();
    final int total = hostelIds.length;

    int updated   = 0;
    int noReviews = 0;
    int failed    = 0;

    // ── 2. Recompute and save for each hostel ─────────────────────────────
    for (int i = 0; i < hostelIds.length; i++) {
      final hostelId = hostelIds[i];
      try {
        final result =
            await HostelRatingAlgorithm.computeAndSave(hostelId);

        if (result.count == 0) {
          noReviews++;
        } else {
          updated++;
        }
      } catch (_) {
        failed++;
      }

      // Notify caller of progress after each hostel.
      onProgress?.call(i + 1, total);
    }

    return BackfillResult(
      updated:   updated,
      noReviews: noReviews,
      failed:    failed,
    );
  }
}
