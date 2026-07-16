import 'package:flutter/material.dart';

class AdminEditRoomScreen extends StatefulWidget {
  final String roomNumber;

  const AdminEditRoomScreen({
    super.key,
    required this.roomNumber,
  });

  @override
  State<AdminEditRoomScreen> createState() => _AdminEditRoomScreenState();
}

class _AdminEditRoomScreenState extends State<AdminEditRoomScreen> {
  String _availability = "Available";
  String _roomType = "Double";

  final Set<String> _selectedFeatures = {};

  final List<String> _features = [
    "Near Balcony",
    "Self-contained",
    "Bathroom Distance",
    "Window View",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Room ${widget.roomNumber}"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Room photo
            const Text(
              "Room Photo",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              "Upload or replace the current room image.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "PNG, JPG up to 10MB",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      // File picker logic goes here later
                    },
                    child: const Text("Choose File"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Availability status
            const Text(
              "Occupancy Status",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              "Choose the current room status.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statusButton("Available", Colors.green),
                const SizedBox(width: 8),
                _statusButton("Occupied", Colors.red),
                const SizedBox(width: 8),
                _statusButton("Reserved", Colors.orange),
              ],
            ),

            const SizedBox(height: 28),

            // Room Type
            const Text(
              "Room Type",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _typeButton("Single"),
                const SizedBox(width: 8),
                _typeButton("Double"),
              ],
            ),

            const SizedBox(height: 28),

            // Room Features
            const Text(
              "Room Features",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              "Select all features that apply.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Column(
              children: _features.map((feature) {
                final selected = _selectedFeatures.contains(feature);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (isChecked) {
                    setState(() {
                      if (isChecked == true) {
                        _selectedFeatures.add(feature);
                      } else {
                        _selectedFeatures.remove(feature);
                      }
                    });
                  },
                  title: Text(feature),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  debugPrint("Room: ${widget.roomNumber}");
                  debugPrint("Availability: $_availability");
                  debugPrint("Type: $_roomType");
                  debugPrint("Features: $_selectedFeatures");
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _statusButton(String label, Color color) {
    final selected = _availability == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _availability = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeButton(String label) {
    final selected = _roomType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _roomType = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.blue : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}