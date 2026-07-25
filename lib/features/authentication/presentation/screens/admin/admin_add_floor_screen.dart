import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAddFloorScreen extends StatefulWidget {
  final String hostelId;

  const AdminAddFloorScreen({
    super.key,
    required this.hostelId,
  });

  @override
  State<AdminAddFloorScreen> createState() =>
      _AdminAddFloorScreenState();
}

class _AdminAddFloorScreenState
    extends State<AdminAddFloorScreen> {

  final _floorNameController = TextEditingController();
  final _roomRangeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _floorNameController.dispose();
    _roomRangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Floor"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create a new floor and automatically generate its rooms.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),

            const Text(
              "Floor Name",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _floorNameController,
              decoration: InputDecoration(
                hintText: "First Floor",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Room Range",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _roomRangeController,
              decoration: InputDecoration(
                hintText: "101-130",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Rooms will be created automatically based on the room range.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
  if (_floorNameController.text.isEmpty ||
      _roomRangeController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please fill in all fields"),
      ),
    );
    return;
  }

  final range = _roomRangeController.text.split("-");

if (range.length != 2) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Enter room range like 101-130"),
    ),
  );
  return;
}

final start = int.tryParse(range.first.trim());
final end = int.tryParse(range.last.trim());

if (start == null || end == null || start > end) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Invalid room range"),
    ),
  );
  return;
}

  final totalRooms = end - start + 1;

  // Add the floor document
  final floorRef = await _firestore
      .collection("hostels")
      .doc(widget.hostelId)
      .collection("floors")
      .add({
    "floorName": _floorNameController.text.trim(),
    "roomRange": _roomRangeController.text.trim(),
    "totalRooms": totalRooms,
    "availableRooms": totalRooms,
    "createdAt": FieldValue.serverTimestamp(),
  });

  // Use a batch to create all rooms at once for speed and reliability
  final batch = _firestore.batch();
  for (int roomNumber = start; roomNumber <= end; roomNumber++) {
    int relativeIndex = roomNumber - start;
    String sideCode = (relativeIndex % 2 == 0) ? "L" : "R";
    
    final roomRef = floorRef.collection("rooms").doc(roomNumber.toString());
    batch.set(roomRef, {
      "roomNumber": "$roomNumber$sideCode",
      "baseNumber": roomNumber,
      "side": (sideCode == "L") ? "Left" : "Right",
      "roomType": "Single",
      "capacity": 1,
      "occupied": 0,
      "status": "Available",
      "features": [],
      "imageUrl": "",
      "createdAt": FieldValue.serverTimestamp(),
    });
  }
  
  await batch.commit();

  if (mounted) {
    Navigator.pop(
      context,
      {
        "floorName": _floorNameController.text.trim(),
        "roomRange": _roomRangeController.text.trim(),
      },
    );
  }
},


                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
),
                ),
              ),
            ),
          ],
        ),
      ),
      
    );
  }
}

