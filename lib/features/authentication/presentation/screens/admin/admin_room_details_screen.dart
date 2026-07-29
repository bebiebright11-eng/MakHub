import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_edit_room_screen.dart';

class AdminRoomDetailsScreen extends StatefulWidget {
  final String hostelId;
  final String floorId;
  final String roomId;
  final String roomNumber;

  const AdminRoomDetailsScreen({
    super.key,
    required this.hostelId,
    required this.floorId,
    required this.roomId,
    required this.roomNumber,
  });

  @override
  State<AdminRoomDetailsScreen> createState() =>
      _AdminRoomDetailsScreenState();
}

class _AdminRoomDetailsScreenState
    extends State<AdminRoomDetailsScreen> {

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

bool _loading = true;

String _availability = "";
String _roomType = "";
String _description = "";

int _occupied = 0;
int _capacity = 0;

String _singlePrice = "";
String _doublePrice = "";

String _singleRoomSize = "";
String _doubleRoomSize = "";

final Set<String> _selectedFeatures = {};

Future<void> _loadRoom() async {
  try {
    // Load hostel information
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

    // Load room information
    final roomDoc = await _firestore
        .collection("hostels")
        .doc(widget.hostelId)
        .collection("floors")
        .doc(widget.floorId)
        .collection("rooms")
        .doc(widget.roomId)
        .get();

    if (!roomDoc.exists) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final data = roomDoc.data()!;

    setState(() {
      _availability = data["status"] ?? "Available";
      _roomType = data["roomType"] ?? "Single";
      _description = data["description"] ?? "";

      _occupied = data["occupied"] ?? 0;
      _capacity = data["capacity"] ?? 1;

      _selectedFeatures.clear();

      if (data["features"] != null &&
          data["features"] is Map<String, dynamic>) {

        final features =
            Map<String, dynamic>.from(data["features"]);

        features.forEach((key, value) {
          if (value == true) {
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
void didChangeDependencies() {
  super.didChangeDependencies();
  _loadRoom();
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


                Container(
  width: double.infinity,
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: AppColors.primary.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(15),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      Text(
        "Room ${widget.roomNumber}",
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 8),

      Text(
        "$_roomType Room",
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),

      const SizedBox(height: 12),

      Row(
        children: [

          Icon(
            _availability == "Available"
                ? Icons.check_circle
                : _availability == "Occupied"
                    ? Icons.cancel
                    : Icons.schedule,
            color: _availability == "Available"
                ? Colors.green
                : _availability == "Occupied"
                    ? Colors.red
                    : Colors.orange,
          ),

          const SizedBox(width: 8),

          Text(
            _availability,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _availability == "Available"
                  ? Colors.green
                  : _availability == "Occupied"
                      ? Colors.red
                      : Colors.orange,
            ),
          ),

          const Spacer(),

          const Icon(
            Icons.people,
            color: AppColors.primary,
          ),

          const SizedBox(width: 6),

          Text(
            "$_occupied/$_capacity",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

        ],
      ),

    ],
  ),
),

const SizedBox(height: 30),

                // Room Photo
const Text(
  "Room Photo",
  style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  ),
),

const SizedBox(height: 4),

const Text(
  "View the current room image.",
  style: TextStyle(
    fontSize: 12,
    color: Colors.grey,
  ),
),

const SizedBox(height: 12),

Container(
  height: 200,
  width: double.infinity,
  decoration: BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(12),
  ),
  child: const Center(
    child: Icon(
      Icons.image,
      size: 80,
      color: Colors.grey,
    ),
  ),
),

const SizedBox(height: 28),

// Description
const Text(
  "Description",
  style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  ),
),

const SizedBox(height: 8),

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text(
    _description.isEmpty
        ? "No description provided."
        : _description,
    style: const TextStyle(
      fontSize: 15,
      color: Colors.black87,
    ),
  ),
),

const SizedBox(height: 28),

// Current Occupants
const Text(
  "Current Occupants",
  style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  ),
),

const SizedBox(height: 8),

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    children: [

      const Icon(
        Icons.people,
        color: AppColors.primary,
      ),

      const SizedBox(width: 12),

      Expanded(
        child: Text(
          "$_occupied of $_capacity student${_capacity > 1 ? "s" : ""} occupying this room",
          style: const TextStyle(
            fontSize: 15,
          ),
        ),
      ),

    ],
  ),
),

const SizedBox(height: 28),

// Occupancy Status
const Text(
  "Occupancy Status",
  style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  ),
),

const SizedBox(height: 8),

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: _availability == "Available"
        ? Colors.green.shade50
        : _availability == "Occupied"
            ? Colors.red.shade50
            : Colors.orange.shade50,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    children: [

      Icon(
        _availability == "Available"
            ? Icons.check_circle
            : _availability == "Occupied"
                ? Icons.cancel
                : Icons.schedule,
        color: _availability == "Available"
            ? Colors.green
            : _availability == "Occupied"
                ? Colors.red
                : Colors.orange,
      ),

      const SizedBox(width: 12),

      Expanded(
        child: Text(
          _availability,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _availability == "Available"
                ? Colors.green
                : _availability == "Occupied"
                    ? Colors.red
                    : Colors.orange,
          ),
        ),
      ),

    ],
  ),
),

const SizedBox(height: 28),

// Room Type
const Text(
  "Room Type",
  style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  ),
),

const SizedBox(height: 8),

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    children: [

      const Icon(
        Icons.hotel,
        color: AppColors.primary,
      ),

      const SizedBox(width: 12),

      Expanded(
        child: Text(
          "$_roomType Room",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

    ],
  ),
),

const SizedBox(height: 28),


// Room Information
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

    Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [

            const Icon(
              Icons.straighten,
              color: AppColors.primary,
            ),

            const SizedBox(height: 10),

            const Text(
              "Room Size (ft)",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _roomType == "Single"
                  ? _singleRoomSize
                  : _doubleRoomSize,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

          ],
        ),
      ),
    ),

    const SizedBox(width: 12),

    Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [

            const Icon(
              Icons.payments,
              color: Colors.green,
            ),

            const SizedBox(height: 10),

            const Text(
              "Price / Semester",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "UGX ${_roomType == "Single" ? _singlePrice : _doublePrice}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

          ],
        ),
      ),
    ),

  ],
),

const SizedBox(height: 28),

// Room Features
const Text(
  "Room Features",
  style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  ),
),

const SizedBox(height: 12),

_selectedFeatures.isEmpty
    ? Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          "No room features have been added.",
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      )
    : Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _selectedFeatures.map((feature) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(feature),
              ],
            ),
          );
        }).toList(),
      ),

const SizedBox(height: 32),

SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: () async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminEditRoomScreen(
            hostelId: widget.hostelId,
            floorId: widget.floorId,
            roomId: widget.roomId,
            roomNumber: widget.roomNumber,
          ),
        ),
      );

      // Refresh when returning from edit screen
      _loadRoom();
    },
    icon: const Icon(Icons.edit),
    label: const Text("Edit Room"),
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),

const SizedBox(height: 20),
                // We'll add the sections here one by one.

              ],
            ),
          ),
  );
}
}

