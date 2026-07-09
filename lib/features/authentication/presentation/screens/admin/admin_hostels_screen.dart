import 'package:flutter/material.dart';

class AdminHostelsScreen extends StatelessWidget {
  const AdminHostelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hostel Management"),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 15),
            child: Icon(Icons.more_vert),
          )
        ],
      ),

      body: Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    children: [

      TextField(
        decoration: InputDecoration(
          hintText: "Search hostels...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),

      const SizedBox(height: 15),

SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      _filterChip("All", true),

      const SizedBox(width: 8),

      _filterChip("Available", false),

      const SizedBox(width: 8),

      _filterChip("Full", false),

      const SizedBox(width: 8),

      _filterChip("Boys", false),

      const SizedBox(width: 8),

      _filterChip("Girls", false),

      const SizedBox(width: 8),

      _filterChip("Mixed", false),
    ],
  ),
),

    ],
  ),
),
    );
  }

  Widget _filterChip(String text, bool selected) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),
    decoration: BoxDecoration(
      color: selected
          ? Colors.blue
          : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: selected
            ? Colors.white
            : Colors.grey,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

}