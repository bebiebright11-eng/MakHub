import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminEditRoomScreen extends StatefulWidget {
  final String hostelId;
  final String floorId;
  final String roomId;
  final String roomNumber;

  const AdminEditRoomScreen({
    super.key,
    required this.hostelId,
    required this.floorId,
    required this.roomId,
    required this.roomNumber,
  });

  @override
  State<AdminEditRoomScreen> createState() => _AdminEditRoomScreenState();
}

class _AdminEditRoomScreenState extends State<AdminEditRoomScreen> {
  String _availability = "Available";
  String _roomType = "Double";
  int _occupied = 0;
  int _capacity = 1;

  final Set<String> _selectedFeatures = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _descriptionController =
    TextEditingController();
bool _loading = true;

String _singlePrice = "";
String _doublePrice = "";

String _singleRoomSize = "";
String _doubleRoomSize = "";

  final List<String> _features = [
    "Near Balcony",
    "Self-contained",
    "Bathroom Distance",
    "Window View",
  ];


Future<void> _loadRoom() async {
  try {
    final hostelDoc = await _firestore
    .collection("hostels")
    .doc(widget.hostelId)
    .get();

if (hostelDoc.exists) {
  final hostel = hostelDoc.data()!;

  _singlePrice = hostel["singlePrice"] ?? "";
  _doublePrice = hostel["doublePrice"] ?? "";

  _singleRoomSize = hostel["singleRoomSize"] ?? "";
  _doubleRoomSize = hostel["doubleRoomSize"] ?? "";
}

    final doc = await _firestore
        .collection("hostels")
        .doc(widget.hostelId)
        .collection("floors")
        .doc(widget.floorId)
        .collection("rooms")
        .doc(widget.roomId)
        .get();

    if (!doc.exists) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final data = doc.data()!;

    setState(() {
      _availability = data["status"] ?? "Available";
      _roomType = data["roomType"] ?? "Single";
      _descriptionController.text =
          data["description"] ?? "";
      _occupied = data["occupied"] ?? 0;
      if (data["capacity"] != null) {
        _capacity = data["capacity"];
      } else {
        _capacity = _roomType == "Double" ? 2 : 1;
      }

      _selectedFeatures.clear();

      if (data["features"] != null &&
          data["features"] is Map<String, dynamic>) {

        final features =
            Map<String, dynamic>.from(data["features"]);

        features.forEach((key, value) {
          if (value is bool && value) {
            _selectedFeatures.add(key);
          }
        });
      }

      _loading = false;
    });

  } catch (e) {


    setState(() {
      _loading = false;
    });
  }
}


@override
void initState() {
  super.initState();
  _loadRoom();
}


@override
void dispose() {
  _descriptionController.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Room ${widget.roomNumber}"),
        centerTitle: true,
      ),
      body: _loading
    ? const Center(
        child: CircularProgressIndicator(),
      )
    : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Room photo
            const Text(
              "Room Photo",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
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
                    onPressed: () async {
                      // File picker logic goes here later
                    },
                    child: const Text("Choose File"),
                  ),
                ],
              ),
            ),

const SizedBox(height: 28),

           const Text(
  "Description",
  style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  ),
),

const SizedBox(height: 8),

TextField(
  controller: _descriptionController,
  maxLines: 4,
  decoration: InputDecoration(
    hintText: "Describe this room...",
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
),

const SizedBox(height: 28),
  const Text(
  "Current Occupants",
 style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  ),
),

const SizedBox(height: 4),

const Text(
  "Update how many students currently occupy this room.",
  style: TextStyle(
    color: Colors.grey,
    fontSize: 12,
  ),
),

const SizedBox(height: 12),

Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  ),
  decoration: BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    children: [

      IconButton(
        onPressed: () {
  if (_occupied > 0) {
    setState(() {
      _occupied--;

      if (_occupied == _capacity) {
        _availability = "Occupied";
      } else {
        _availability = "Available";
      }
    });
  }
},
        icon: const Icon(Icons.remove_circle),
        color: Colors.red,
      ),

      Expanded(
        child: Center(
          child: Text(
            "$_occupied / $_capacity",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      IconButton(
        onPressed: () {
  if (_occupied < _capacity) {
    setState(() {
      _occupied++;

      if (_occupied == _capacity) {
        _availability = "Occupied";
      } else {
        _availability = "Available";
      }
    });
  }
},
        icon: const Icon(Icons.add_circle),
        color: Colors.green,
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

            const SizedBox(height: 20),

Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Text(
        "Room Information",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),

      const SizedBox(height: 12),

      Row(
        children: [
          const Icon(
            Icons.straighten,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Room Size (ft): ${_roomType == "Single" ? _singleRoomSize : _doubleRoomSize}",
            ),
          ),
        ],
      ),

      const SizedBox(height: 12),

      Row(
        children: [
          const Icon(
            Icons.payments,
            color: Colors.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Price per Semester: UGX ${_roomType == "Single" ? _singlePrice : _doublePrice}",
            ),
          ),
        ],
      ),

    ],
  ),
),

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
                onPressed: () async {

  await _firestore
      .collection("hostels")
      .doc(widget.hostelId)
      .collection("floors")
      .doc(widget.floorId)
      .collection("rooms")
      .doc(widget.roomId)
      .update({

    "status": _availability,

    "roomType": _roomType,

    "occupied": _occupied,

    "capacity": _capacity,

    "description": _descriptionController.text.trim(),

    "features": {
      "Near Balcony":
          _selectedFeatures.contains("Near Balcony"),

      "Self-contained":
          _selectedFeatures.contains("Self-contained"),

      "Bathroom Distance":
          _selectedFeatures.contains("Bathroom Distance"),

      "Window View":
          _selectedFeatures.contains("Window View"),
    },

  });

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Room updated successfully"),
    ),
  );

  Navigator.pop(context);
  },


                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
        onTap: () {
  setState(() {
    _roomType = label;

    if (label == "Single") {
      _capacity = 1;
    } else {
      _capacity = 2;
    }

    // Prevent occupied from exceeding capacity
    if (_occupied > _capacity) {
      _occupied = _capacity;
    }

    // Automatically update status
    if (_occupied == _capacity) {
      _availability = "Occupied";
    } else {
      _availability = "Available";
    }
  });
},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.grey.shade100,
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
