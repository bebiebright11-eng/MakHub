import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import '/algorithms/text_preference_extractor.dart';
import 'hostel_results_screen.dart';

class DescribeSearchScreen extends StatefulWidget {
  const DescribeSearchScreen({super.key});

  @override
  State<DescribeSearchScreen> createState() => _DescribeSearchScreenState();
}

class _DescribeSearchScreenState extends State<DescribeSearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final preferences = TextPreferenceExtractor.extract(text);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HostelResultsScreen(preferences: preferences),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Describe Your Hostel"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tell us what you're looking for",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "e.g. \"Girls hostel near Kikoni, single room, budget 400k to 600k, with wifi and shuttle\"",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Describe your ideal hostel...",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _search,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Search",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}