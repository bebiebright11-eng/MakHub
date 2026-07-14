import 'package:flutter/material.dart';

class AdminRoomListScreen extends StatefulWidget {
  const AdminRoomListScreen({super.key});

  @override
  State<AdminRoomListScreen> createState() => _AdminRoomListScreenState();
}

class _AdminRoomListScreenState extends State<AdminRoomListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rooms"),
        centerTitle: true,
      ),
      body: const Center(
        child: Text("Room grid goes here"),
      ),
    );
  }
}