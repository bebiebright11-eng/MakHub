import 'package:flutter/material.dart';

class AdminHostelsScreen extends StatelessWidget {
  const AdminHostelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hostel Management"),
        centerTitle: true,
      ),

      body: const Center(
        child: Text(
          "Admin Hostels Screen",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}