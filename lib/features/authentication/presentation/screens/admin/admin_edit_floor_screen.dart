import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminEditFloorScreen extends StatefulWidget {
  final String hostelId;
  final String floorId;
  final String floorName;
  final String roomRange;

  const AdminEditFloorScreen({
    super.key,
    required this.hostelId,
    required this.floorId,
    required this.floorName,
    required this.roomRange,
  });

  @override
  State<AdminEditFloorScreen> createState() =>
      _AdminEditFloorScreenState();
}

class _AdminEditFloorScreenState
    extends State<AdminEditFloorScreen> {

  late TextEditingController _floorController;
  late TextEditingController _rangeController;

  @override
  void initState() {
    super.initState();

    _floorController =
        TextEditingController(text: widget.floorName);

    _rangeController =
        TextEditingController(text: widget.roomRange);
  }

  @override
  void dispose() {
    _floorController.dispose();
    _rangeController.dispose();
    super.dispose();
  }

  int _countRooms(String range) {
    try {
      final parts = range.split("-");

      final start = int.parse(parts.first);
      final end = int.parse(parts.last);

      return end - start + 1;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _updateFloor() async {

    final totalRooms =
        _countRooms(_rangeController.text);

    await FirebaseFirestore.instance
        .collection("hostels")
        .doc(widget.hostelId)
        .collection("floors")
        .doc(widget.floorId)
        .update({

      "floorName": _floorController.text.trim(),
      "roomRange": _rangeController.text.trim(),
      "totalRooms": totalRooms,
      "availableRooms": totalRooms,

    });

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Floor"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            TextField(
              controller: _floorController,
              decoration: const InputDecoration(
                labelText: "Floor Name",
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _rangeController,
              decoration: const InputDecoration(
                labelText: "Room Range",
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(

                onPressed: _updateFloor,

                child: const Text("Update"),

              ),
            )

          ],
        ),
      ),
    );
  }
}