import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/constants/app_colors.dart';
import '/algorithms/hostel_rating_algorithm.dart';

class StudentReviewsScreen extends StatefulWidget {
  final String hostelId;
  final String hostelName;

  const StudentReviewsScreen({
    super.key,
    required this.hostelId,
    required this.hostelName,
  });

  @override
  State<StudentReviewsScreen> createState() => _StudentReviewsScreenState();
}

class _StudentReviewsScreenState extends State<StudentReviewsScreen> {
  int _selectedRating = 0;
  bool _isSubmitting = false;
  final _reviewController = TextEditingController();

  // Reviews stored at top-level `reviews` collection with hostelId field
  // (matches how hostel_details_screen.dart reads them)
  late final Stream<QuerySnapshot> _reviewsStream = FirebaseFirestore.instance
      .collection('reviews')
      .where('hostelId', isEqualTo: widget.hostelId)
      .orderBy('createdAt', descending: true)
      .snapshots();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating first.')),
      );
      return;
    }
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a review before submitting.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to leave a review.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Save to top-level reviews collection (matches hostel_details_screen reads)
      await FirebaseFirestore.instance.collection('reviews').add({
        'hostelId': widget.hostelId,
        'userId': user.uid,
        'rating': _selectedRating,
        'review': _reviewController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Also update the hostel's averageRating via the algorithm
      await HostelRatingAlgorithm.computeAndSave(widget.hostelId);

      if (!mounted) return;

      setState(() {
        _reviewController.clear();
        _selectedRating = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted. Thank you!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reviews & Ratings',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Hostel name
          Text(
            widget.hostelName,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // ── Write a review ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rate this Hostel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRating = star),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          star <= _selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 34,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Write a Review',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _reviewController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Share your experience at this hostel...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Submit Review',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Previous reviews (live from Firestore) ───────────────────────
          const Text(
            'Previous Reviews',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: _reviewsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No reviews yet. Be the first to review!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final review = doc.data() as Map<String, dynamic>;
                  final int rating = (review['rating'] ?? 0).toInt();
                  final String comment =
                      (review['review'] ?? review['comment'] ?? '').toString();
                  final Timestamp? ts = review['createdAt'] as Timestamp?;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  Icons.star,
                                  size: 15,
                                  color: i < rating
                                      ? Colors.amber
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ),
                            Text(
                              _formatTimestamp(ts),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          comment,
                          style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                              height: 1.5),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
