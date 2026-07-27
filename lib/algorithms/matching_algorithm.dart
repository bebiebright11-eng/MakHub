import 'package:cloud_firestore/cloud_firestore.dart';

/// Verifies a friend's details for a "Me & Friend" booking and optionally
/// matches students with compatible profiles for future roommate suggestions.
///
/// Phase 1 (implemented): friend verification — confirms the friend's name
/// and phone number exist in the users collection before allowing a joint booking.
///
/// Phase 2 (scaffold): compatibility scoring — matches students by university,
/// gender, course, and year for future roommate suggestions.
class StudentMatchingAlgorithm {
  const StudentMatchingAlgorithm._();

  // ── Phase 1: Friend verification ─────────────────────────────────────────

  /// Verifies that [friendPhone] belongs to a registered user whose name
  /// matches [friendName] (case-insensitive, partial match allowed).
  ///
  /// Returns a [MatchResult] indicating whether the friend was found.
  static Future<MatchResult> verifyFriend({
    required String friendName,
    required String friendPhone,
  }) async {
    if (friendName.trim().isEmpty || friendPhone.trim().isEmpty) {
      return const MatchResult.failed("Friend's name and phone are required.");
    }

    // Look up by phone number
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: friendPhone.trim())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return const MatchResult.failed(
        'No registered student found with that phone number. '
        'Ask your friend to register on MakHub first.',
      );
    }

    final userData = query.docs.first.data();
    final String registeredName =
        (userData['fullName'] ?? userData['name'] ?? '').toString().toLowerCase();
    final String inputName = friendName.trim().toLowerCase();

    // Partial name match — accepts "John" matching "John Doe"
    if (!registeredName.contains(inputName) && !inputName.contains(registeredName)) {
      return const MatchResult.failed(
        "The phone number was found but the name doesn't match. "
       "Please double-check your friend's details.",
      );
    }

    return MatchResult.found(
      userId: query.docs.first.id,
      verifiedName: (userData['fullName'] ?? userData['name'] ?? friendName).toString(),
    );
  }

  // ── Phase 2: Compatibility scoring (scaffold) ────────────────────────────

  /// Scores how compatible two students are as roommates.
  /// Returns a score 0–100.
  ///
  /// Scoring:
  ///   +40  Same university
  ///   +30  Same gender
  ///   +20  Same course / faculty
  ///   +10  Same year of study
  static Future<int> compatibilityScore({
    required String studentAId,
    required String studentBId,
  }) async {
    final results = await Future.wait([
      FirebaseFirestore.instance.collection('users').doc(studentAId).get(),
      FirebaseFirestore.instance.collection('users').doc(studentBId).get(),
    ]);

    if (!results[0].exists || !results[1].exists) return 0;

    final a = results[0].data()!;
    final b = results[1].data()!;
    int score = 0;

    final String uniA = (a['university'] ?? '').toString().toLowerCase();
    final String uniB = (b['university'] ?? '').toString().toLowerCase();
    if (uniA.isNotEmpty && uniA == uniB) score += 40;

    final String genA = (a['gender'] ?? '').toString().toLowerCase();
    final String genB = (b['gender'] ?? '').toString().toLowerCase();
    if (genA.isNotEmpty && genA == genB) score += 30;

    final String courseA = (a['course'] ?? '').toString().toLowerCase();
    final String courseB = (b['course'] ?? '').toString().toLowerCase();
    if (courseA.isNotEmpty && courseA == courseB) score += 20;

    final String yearA = (a['yearOfStudy'] ?? '').toString();
    final String yearB = (b['yearOfStudy'] ?? '').toString();
    if (yearA.isNotEmpty && yearA == yearB) score += 10;

    return score;
  }
}

class MatchResult {
  final bool found;
  final String? userId;
  final String? verifiedName;
  final String? errorMessage;

  const MatchResult.found({required this.userId, required this.verifiedName})
      : found = true,
        errorMessage = null;

  const MatchResult.failed(this.errorMessage)
      : found = false,
        userId = null,
        verifiedName = null;
}
