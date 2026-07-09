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

    ],
  ),
),
    );
  }
}