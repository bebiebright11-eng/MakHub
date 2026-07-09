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

const SizedBox(height: 20),

Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      "14 Hostels Found",
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),

    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.sort,
            size: 18,
          ),
          SizedBox(width: 5),
          Text("Sort"),
        ],
      ),
    ),
  ],
),

const SizedBox(height: 20),

Card(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  elevation: 3,
  child: Padding(
    padding: const EdgeInsets.all(15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(
            child: Icon(
              Icons.apartment,
              size: 70,
              color: Colors.grey,
            ),
          ),
        ),

        const SizedBox(height: 15),

        const Text(
          "Dream World Hostel",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Row(
          children: [
            Icon(
              Icons.location_on,
              size: 18,
              color: Colors.red,
            ),
            SizedBox(width: 5),
            Text("500m from campus"),
          ],
        ),

        const SizedBox(height: 10),

        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Available Rooms: 45"),
            Text(
              "UGX 450,000",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [

            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.visibility),
              label: const Text("View"),
            ),

            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit),
              label: const Text("Edit"),
            ),

            ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              icon: const Icon(Icons.delete),
              label: const Text("Delete"),
            ),
          ],
        ),
      ],
    ),
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