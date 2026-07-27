import 'package:cloud_firestore/cloud_firestore.dart';

/// Computes and persists the average rating for a hostel.
///
/// Reviews are stored at:
///   hostels/{hostelId}/reviews/{reviewId}
///   Fields: { rating: num (1–5), userId: string, comment: string, createdAt: Timestamp }
///
/// After computing, the average is written back to the hostel document as
///   { averageRating: double, reviewCount: int }
/// so the UI can read it without recalculating each time.
class HostelRatingAlgorithm {
  const HostelRatingAlgorithm._();

  /// Returns the computed [RatingResult] and saves it to Firestore.
  static Future<RatingResult> computeAndSave(String hostelId) async {
    final result = await compute(hostelId);

    // Persist back to the hostel doc so cards can read it cheaply
    await FirebaseFirestore.instance
        .collection('hostels')
        .doc(hostelId)
        .update({
      'averageRating': result.average,
      'reviewCount': result.count,
    });

    return result;
  }

  /// Computes the average without writing to Firestore.
  static Future<RatingResult> compute(String hostelId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('hostels')
        .doc(hostelId)
        .collection('reviews')
        .get();

    if (snapshot.docs.isEmpty) {
      return const RatingResult(average: 0.0, count: 0);
    }

    double total = 0;
    int validCount = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final raw = data['rating'];
      final double? rating = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
      if (rating != null && rating >= 1 && rating <= 5) {
        total += rating;
        validCount++;
      }
    }

    if (validCount == 0) return const RatingResult(average: 0.0, count: 0);

    final double avg = double.parse((total / validCount).toStringAsFixed(1));
    return RatingResult(average: avg, count: validCount);
  }

  /// Adds a new review and recomputes the average immediately.
  /// Returns the updated [RatingResult].
  static Future<RatingResult> addReview({
    required String hostelId,
    required String userId,
    required double rating,
    String comment = '',
  }) async {
    assert(rating >= 1 && rating <= 5, 'Rating must be between 1 and 5');

    await FirebaseFirestore.instance
        .collection('hostels')
        .doc(hostelId)
        .collection('reviews')
        .add({
      'userId': userId,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return computeAndSave(hostelId);
  }
}

class RatingResult {
  /// Average rating rounded to 1 decimal place, e.g. 4.6.
  final double average;

  /// Total number of reviews counted.
  final int count;

  const RatingResult({required this.average, required this.count});

  /// Display string, e.g. "4.6 (23 reviews)".
  String get displayString =>
      count == 0 ? 'No ratings yet' : '$average ($count review${count == 1 ? '' : 's'})';
}
