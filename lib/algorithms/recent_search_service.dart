import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/search_criteria.dart';

/// Persists and retrieves the student's most recent search criteria.
///
/// Storage: Firestore  →  users/{uid}.recentSearch  (a single map field).
///
/// Design rules:
///   • Only the LATEST search is ever kept.  Each new save overwrites the old.
///   • The home screen reads this once on load; it is never streamed so it
///     does not cause extra Firestore listeners.
///   • If the student is not logged in, save/load are no-ops (return null).
class RecentSearchService {
  RecentSearchService._();
  static final RecentSearchService instance = RecentSearchService._();

  // ── Firestore reference helpers ───────────────────────────────────────────

  DocumentReference<Map<String, dynamic>>? _userDoc() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  /// Persists [criteria] as the student's most recent search.
  ///
  /// Uses merge:true so it never overwrites unrelated fields (e.g. preferences,
  /// profile data) on the user document.
  ///
  /// Silently swallows errors — a failed save must never block navigation to
  /// the search results screen.
  Future<void> save(SearchCriteria criteria) async {
    final ref = _userDoc();
    if (ref == null) return;

    try {
      await ref.set(
        {'recentSearch': criteria.toMap()},
        SetOptions(merge: true),
      );
    } catch (_) {
      // Non-fatal: home screen will simply not show the section this session.
    }
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  /// Loads the student's most recent search criteria from Firestore.
  ///
  /// Returns null when:
  ///   • the student is not logged in, or
  ///   • no search has been saved yet, or
  ///   • the stored data cannot be parsed.
  Future<SearchCriteria?> load() async {
    final ref = _userDoc();
    if (ref == null) return null;

    try {
      final snap = await ref.get();
      if (!snap.exists) return null;

      final raw = snap.data()?['recentSearch'];
      if (raw == null || raw is! Map) return null;

      final criteria =
          SearchCriteria.fromMap(Map<String, dynamic>.from(raw));

      // Return null rather than an empty criteria object so callers can use
      // a simple null-check to decide whether to show the section.
      return criteria.hasAnyCriteria ? criteria : null;
    } catch (_) {
      return null;
    }
  }

  // ── Clear ─────────────────────────────────────────────────────────────────

  /// Removes the stored recent search (e.g. on sign-out).
  /// Silently swallows errors.
  Future<void> clear() async {
    final ref = _userDoc();
    if (ref == null) return;

    try {
      await ref.update({'recentSearch': FieldValue.delete()});
    } catch (_) {}
  }
}
