import 'package:flutter/material.dart';

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
                onPressed: () {
                  debugPrint("Floor Name: ${_floorNameController.text}");
                  debugPrint("Room Range: ${_roomRangeController.text}");
                  Navigator.pop(context);
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

