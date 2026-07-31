import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/constants/app_colors.dart';
import '/algorithms/hostel_rating_algorithm.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StudentReviewsScreen
//
// Displays the full review experience for a verified student:
//   • Hostel header with average rating + review count
//   • Check-in / reviewing-on dates
//   • Own review section (write / read-only / edit)
//   • Other student reviews with "Verified Resident" badge
// ─────────────────────────────────────────────────────────────────────────────

class StudentReviewsScreen extends StatefulWidget {
  final String hostelId;
  final String hostelName;
  final DateTime? checkInDate; // from the student's confirmed booking

  const StudentReviewsScreen({
    super.key,
    required this.hostelId,
    required this.hostelName,
    this.checkInDate,
  });

  @override
  State<StudentReviewsScreen> createState() => _StudentReviewsScreenState();
}

class _StudentReviewsScreenState extends State<StudentReviewsScreen> {
  // ── Own-review state ──────────────────────────────────────────────────────
  bool _isEditMode = false;   // true  → show text field + save button
  bool _isSubmitting = false;
  int _selectedRating = 0;
  final _reviewController = TextEditingController();

  // Firestore doc ID of the student's existing review (null if none yet)
  String? _existingReviewId;

  // ── Streams ───────────────────────────────────────────────────────────────
  late final Stream<QuerySnapshot> _allReviewsStream =
      FirebaseFirestore.instance
          .collection('reviews')
          .where('hostelId', isEqualTo: widget.hostelId)
          .orderBy('createdAt', descending: true)
          .snapshots();

  late final Stream<DocumentSnapshot> _hostelStream =
      FirebaseFirestore.instance
          .collection('hostels')
          .doc(widget.hostelId)
          .snapshots();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _relativeDate(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7} week${diff.inDays ~/ 7 == 1 ? '' : 's'} ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  // First name only — never expose full name, email or student number
  String _displayName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'Student';
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) return parts[0];
    // "John Smith" → "John S."
    return '${parts[0]} ${parts[1][0]}.';
  }

  // ── Submit / update review ────────────────────────────────────────────────

  Future<void> _saveReview() async {
    final text = _reviewController.text.trim();
    if (_selectedRating == 0) {
      _showSnack('Please select a star rating.');
      return;
    }
    if (text.length < 20) {
      _showSnack('Review must be at least 20 characters.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      final db = FirebaseFirestore.instance;

      // Resolve the current user's display name once so it's stored
      // in the review document — avoids a per-card user lookup later.
      String studentName = 'Student';
      try {
        final userDoc =
            await db.collection('users').doc(user.uid).get();
        studentName = (userDoc.data()?['fullName'] ??
                userDoc.data()?['name'] ??
                'Student')
            .toString();
      } catch (_) {}

      if (_existingReviewId == null) {
        // First review — create new doc
        await db.collection('reviews').add({
          'hostelId': widget.hostelId,
          'userId': user.uid,
          'studentName': studentName,
          'rating': _selectedRating,
          'review': text,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Edit — update existing doc, do NOT create a duplicate
        await db.collection('reviews').doc(_existingReviewId).update({
          'studentName': studentName, // keep name fresh in case it changed
          'rating': _selectedRating,
          'review': text,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Recalculate hostel average rating
      await HostelRatingAlgorithm.computeAndSave(widget.hostelId);

      if (!mounted) return;
      setState(() => _isEditMode = false);
      _showSnack(
        _existingReviewId == null
            ? 'Review submitted. Thank you!'
            : 'Review updated.',
        color: Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to save review: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
      ),
    );
  }

  // ── Star row widget ───────────────────────────────────────────────────────

  Widget _starRow(int rating, {double size = 22, bool interactive = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = star <= rating;
        final icon =
            interactive ? (filled ? Icons.star : Icons.star_border) : Icons.star;
        return GestureDetector(
          onTap: interactive
              ? () => setState(() => _selectedRating = star)
              : null,
          child: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Icon(icon,
                color: filled ? Colors.amber : Colors.grey.shade300,
                size: size),
          ),
        );
      }),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Reviews & Ratings',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _hostelStream,
        builder: (context, hostelSnap) {
          final hostelData =
              hostelSnap.data?.data() as Map<String, dynamic>? ?? {};
          final double avgRating =
              (hostelData['averageRating'] as num?)?.toDouble() ?? 0.0;
          final int reviewCount =
              (hostelData['reviewCount'] as num?)?.toInt() ?? 0;

          return StreamBuilder<QuerySnapshot>(
            stream: _allReviewsStream,
            builder: (context, reviewsSnap) {
              final allDocs = reviewsSnap.data?.docs ?? [];

              // Split own review from others
              QueryDocumentSnapshot? ownDoc;
              final List<QueryDocumentSnapshot> otherDocs = [];

              for (final doc in allDocs) {
                final data = doc.data() as Map<String, dynamic>;
                if ((data['userId'] ?? '') == uid) {
                  ownDoc = doc;
                } else {
                  otherDocs.add(doc);
                }
              }

              // Sync own-review state into controllers when first loaded
              if (ownDoc != null && _existingReviewId == null) {
                final d = ownDoc.data() as Map<String, dynamic>;
                _existingReviewId = ownDoc.id;
                _selectedRating = (d['rating'] as num?)?.toInt() ?? 0;
                _reviewController.text =
                    (d['review'] ?? d['comment'] ?? '').toString();
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(avgRating, reviewCount),
                  const SizedBox(height: 20),
                  _buildOwnReviewSection(ownDoc),
                  const SizedBox(height: 24),
                  _buildOtherReviews(otherDocs),
                  const SizedBox(height: 24),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ── Header card ───────────────────────────────────────────────────────────

  Widget _buildHeader(double avgRating, int reviewCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hostel name
          Text(
            widget.hostelName,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 6),

          // Average stars + numeric rating
          Row(
            children: [
              _starRow(avgRating.round(), size: 18),
              const SizedBox(width: 8),
              Text(
                avgRating > 0 ? avgRating.toStringAsFixed(1) : '—',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87),
              ),
              const SizedBox(width: 6),
              Text(
                'Based on $reviewCount review${reviewCount == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),

          // Stay details
          Row(
            children: [
              const Icon(Icons.hotel_outlined,
                  size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'You stayed here',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _dateLine('Check-in:', _formatDate(widget.checkInDate)),
          const SizedBox(height: 4),
          _dateLine('Reviewing on:', _formatDate(DateTime.now())),
        ],
      ),
    );
  }

  Widget _dateLine(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── Own review section ────────────────────────────────────────────────────

  Widget _buildOwnReviewSection(QueryDocumentSnapshot? ownDoc) {
    final hasReview = ownDoc != null;
    final ownData =
        hasReview ? (ownDoc.data() as Map<String, dynamic>) : null;
    final updatedAt =
        ownData?['updatedAt'] as Timestamp? ?? ownData?['createdAt'] as Timestamp?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Row(
            children: [
              const Icon(Icons.rate_review_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'YOUR REVIEW',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Edit / write mode ──────────────────────────────────────
          if (!hasReview || _isEditMode) ...[
            const Text(
              'Star Rating',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            _starRow(_selectedRating, size: 36, interactive: true),
            const SizedBox(height: 16),
            const Text(
              'Write your review',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience… (min. 20 characters)',
                hintStyle:
                    TextStyle(fontSize: 13, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Minimum 20 characters',
              style:
                  TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _saveReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        hasReview ? 'Save Changes' : 'Submit Review',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ]

          // ── Read-only mode ─────────────────────────────────────────
          else ...[
            _starRow((ownData?['rating'] as num?)?.toInt() ?? 0, size: 26),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                (ownData?['review'] ?? ownData?['comment'] ?? '').toString(),
                style: const TextStyle(
                    fontSize: 14, color: Colors.black87, height: 1.5),
              ),
            ),
            const SizedBox(height: 10),
            if (updatedAt != null)
              Text(
                'Last updated: ${_formatDate(updatedAt.toDate())}',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade400),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _isEditMode = true),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit Review',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Other reviews ─────────────────────────────────────────────────────────

  Widget _buildOtherReviews(List<QueryDocumentSnapshot> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OTHER STUDENT REVIEWS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),

        if (docs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                const Text(
                  'No reviews yet.',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first verified resident to review this hostel.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        else
          ...docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Prefer stored studentName; fall back to userId-based lookup
            final storedName = (data['studentName'] ?? data['userName'] ?? '')
                .toString();
            final displayName = _displayName(
                storedName.isNotEmpty ? storedName : null);
            return _OtherReviewCard(
              doc: doc,
              hostelId: widget.hostelId,
              relativeDate: _relativeDate(data['createdAt'] as Timestamp?),
              displayName: displayName,
            );
          }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual "other student" review card
// ─────────────────────────────────────────────────────────────────────────────

class _OtherReviewCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final String hostelId;
  final String relativeDate;
  final String displayName;

  const _OtherReviewCard({
    required this.doc,
    required this.hostelId,
    required this.relativeDate,
    required this.displayName,
  });

  @override
  State<_OtherReviewCard> createState() => _OtherReviewCardState();
}

class _OtherReviewCardState extends State<_OtherReviewCard> {
  /// null = still loading, true/false = resolved
  bool? _isVerified;

  @override
  void initState() {
    super.initState();
    _checkVerified();
  }

  Future<void> _checkVerified() async {
    final data = widget.doc.data() as Map<String, dynamic>;
    final userId = (data['userId'] ?? '').toString();
    if (userId.isEmpty) {
      if (mounted) setState(() => _isVerified = false);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('studentId', isEqualTo: userId)
          .where('hostelId', isEqualTo: widget.hostelId)
          .where('bookingStatus', isEqualTo: 'confirmed')
          .limit(1)
          .get();
      if (mounted) setState(() => _isVerified = snap.docs.isNotEmpty);
    } catch (_) {
      if (mounted) setState(() => _isVerified = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final int rating = (data['rating'] as num?)?.toInt() ?? 0;
    final String comment =
        (data['review'] ?? data['comment'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer name + verified badge
          Row(
            children: [
              Text(
                widget.displayName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87),
              ),
              if (_isVerified == true) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified,
                          size: 11, color: Colors.green.shade600),
                      const SizedBox(width: 3),
                      Text(
                        'Verified Resident',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // Relative date on the right
              Text(
                widget.relativeDate,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Star rating
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                Icons.star,
                size: 15,
                color: i < rating ? Colors.amber : Colors.grey.shade300,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Review text
          Text(
            comment,
            style: const TextStyle(
                fontSize: 13, color: Colors.black87, height: 1.5),
          ),
        ],
      ),
    );
  }
}
