import 'package:flutter/material.dart';

class StudentReviewsScreen extends StatefulWidget {
  final String hostelName;

  const StudentReviewsScreen({
    super.key,
    required this.hostelName,
  });

  @override
  State<StudentReviewsScreen> createState() => _StudentReviewsScreenState();
}

class _StudentReviewsScreenState extends State<StudentReviewsScreen> {
  int _selectedRating = 0;
  final _reviewController = TextEditingController();

  final List<Map<String, dynamic>> _reviews = [
    {
      "name": "Ama K.",
      "rating": 5,
      "comment": "Very clean rooms and the security is excellent. The WiFi is stable too.",
      "helpful": 12,
      "markedHelpful": false,
    },
    {
      "name": "Kwesi M.",
      "rating": 5,
      "comment": "Great location near campus and the common areas are well maintained.",
      "helpful": 8,
      "markedHelpful": false,
    },
    {
      "name": "Esi A.",
      "rating": 4,
      "comment": "Good hostel overall, but the water pressure could be better.",
      "helpful": 3,
      "markedHelpful": false,
    },
  ];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reviews & Ratings"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.hostelName,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          const Text(
            "Rate this Hostel",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (index) {
              final starNumber = index + 1;
              return IconButton(
                onPressed: () {
                  setState(() {
                    _selectedRating = starNumber;
                  });
                },
                icon: Icon(
                  starNumber <= _selectedRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          const Text(
            "Write a Review",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reviewController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Share your experience at this hostel...",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_selectedRating == 0 || _reviewController.text.isEmpty) return;
                setState(() {
                  _reviews.insert(0, {
                    "name": "You",
                    "rating": _selectedRating,
                    "comment": _reviewController.text,
                    "helpful": 0,
                    "markedHelpful": false,
                  });
                  _reviewController.clear();
                  _selectedRating = 0;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Submit Review"),
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            "Previous Reviews",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ...List.generate(_reviews.length, (index) {
            final review = _reviews[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(review["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: List.generate(
                          review["rating"] as int,
                          (i) => const Icon(Icons.star, size: 14, color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(review["comment"], style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (!review["markedHelpful"]) {
                          review["helpful"] = review["helpful"] + 1;
                          review["markedHelpful"] = true;
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.thumb_up,
                          size: 16,
                          color: review["markedHelpful"] ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Helpful (${review["helpful"]})",
                          style: TextStyle(
                            fontSize: 12,
                            color: review["markedHelpful"] ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}