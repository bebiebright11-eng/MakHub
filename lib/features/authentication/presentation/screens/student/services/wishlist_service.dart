import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Manages two sub-collections on the student's user document:
///
///   users/{uid}/wishlist          – hostels the student has favourited
///   users/{uid}/recentlyViewed    – hostels the student has opened, capped at 20
///
/// Both collections store lightweight snapshots of hostel data so the
/// Wishlist screen can render cards without an extra Firestore fetch.
class WishlistService {
  WishlistService._();

  static final WishlistService instance = WishlistService._();

  static const int _recentlyViewedLimit = 20;

  // ── Helpers ──────────────────────────────────────────────────────────────

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _wishlistRef {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('wishlist');
  }

  CollectionReference<Map<String, dynamic>>? get _recentRef {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('recentlyViewed');
  }

  // ── Favourites ───────────────────────────────────────────────────────────

  /// Adds [hostelId] to favourites, storing a snapshot of [hostelData].
  /// No-op if already favourited (idempotent).
  Future<void> addFavourite(
    String hostelId,
    Map<String, dynamic> hostelData,
  ) async {
    final ref = _wishlistRef;
    if (ref == null) return;
    await ref.doc(hostelId).set({
      'hostelId': hostelId,
      'hostelName': hostelData['hostelName'] ?? '',
      'location': hostelData['location'] ?? '',
      'distance': hostelData['distance'] ?? '',
      'singlePrice': hostelData['singlePrice'] ?? '',
      'doublePrice': hostelData['doublePrice'] ?? '',
      'photos': hostelData['photos'] ?? [],
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes [hostelId] from favourites.
  Future<void> removeFavourite(String hostelId) async {
    final ref = _wishlistRef;
    if (ref == null) return;
    await ref.doc(hostelId).delete();
  }

  /// Toggles the favourite state for [hostelId].
  /// Returns `true` if the hostel is now a favourite, `false` if removed.
  Future<bool> toggleFavourite(
    String hostelId,
    Map<String, dynamic> hostelData,
  ) async {
    final ref = _wishlistRef;
    if (ref == null) return false;
    final doc = await ref.doc(hostelId).get();
    if (doc.exists) {
      await removeFavourite(hostelId);
      return false;
    } else {
      await addFavourite(hostelId, hostelData);
      return true;
    }
  }

  /// Returns `true` if [hostelId] is currently favourited.
  Future<bool> isFavourite(String hostelId) async {
    final ref = _wishlistRef;
    if (ref == null) return false;
    final doc = await ref.doc(hostelId).get();
    return doc.exists;
  }

  /// Live stream of all favourited hostels, ordered newest first.
  Stream<QuerySnapshot<Map<String, dynamic>>> favouritesStream() {
    final ref = _wishlistRef;
    if (ref == null) return const Stream.empty();
    return ref.orderBy('addedAt', descending: true).snapshots();
  }

  // ── Recently Viewed ──────────────────────────────────────────────────────

  /// Records [hostelId] as recently viewed.
  ///
  /// Behaviour:
  ///   - If the hostel is already in the list, its `viewedAt` is refreshed
  ///     (moves to the top) — no duplicate entry is created.
  ///   - After writing, if the list exceeds [_recentlyViewedLimit] entries
  ///     the oldest entry is deleted.
  Future<void> addRecentlyViewed(
    String hostelId,
    Map<String, dynamic> hostelData,
  ) async {
    final ref = _recentRef;
    if (ref == null) return;

    // Upsert — using hostelId as the doc ID prevents duplicates naturally.
    await ref.doc(hostelId).set({
      'hostelId': hostelId,
      'hostelName': hostelData['hostelName'] ?? '',
      'location': hostelData['location'] ?? '',
      'distance': hostelData['distance'] ?? '',
      'singlePrice': hostelData['singlePrice'] ?? '',
      'doublePrice': hostelData['doublePrice'] ?? '',
      'photos': hostelData['photos'] ?? [],
      'viewedAt': FieldValue.serverTimestamp(),
    });

    // Enforce cap: delete oldest entry when list exceeds the limit.
    final all = await ref.orderBy('viewedAt', descending: false).get();
    if (all.docs.length > _recentlyViewedLimit) {
      await all.docs.first.reference.delete();
    }
  }

  /// Live stream of recently viewed hostels, most recent first.
  Stream<QuerySnapshot<Map<String, dynamic>>> recentlyViewedStream() {
    final ref = _recentRef;
    if (ref == null) return const Stream.empty();
    return ref.orderBy('viewedAt', descending: true).snapshots();
  }
}
