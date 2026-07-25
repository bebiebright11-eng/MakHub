import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateRoomStatusScreen extends StatefulWidget {
  final String hostelId;
  final String floorId;
  final String roomId;

  const UpdateRoomStatusScreen({
    super.key,
    required this.hostelId,
    required this.floorId,
    required this.roomId,
  });

  @override
  State<UpdateRoomStatusScreen> createState() => _UpdateRoomStatusScreenState();
}

class _UpdateRoomStatusScreenState extends State<UpdateRoomStatusScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _descriptionController = TextEditingController();

  bool _loading = true;
  String _roomNumber = '';
  String _availability = "Available";
  String _roomType = "Single";
  int _occupied = 0;
  int _capacity = 1;

  String _singlePrice = '';
  String _doublePrice = '';
  String _singleRoomSize = '';
  String _doubleRoomSize = '';

  final Set<String> _selectedFeatures = {};
  final List<String> _features = [
    "Near Balcony",
    "Self-contained",
    "Bathroom Distance",
    "Window View",
  ];

  Future<void> _loadRoom() async {
    try {
      final hostelDoc = await _firestore.collection('hostels').doc(widget.hostelId).get();
      if (hostelDoc.exists) {
        final hostel = hostelDoc.data()!;
        _singlePrice = hostel['singlePrice']?.toString() ?? '';
        _doublePrice = hostel['doublePrice']?.toString() ?? '';
        _singleRoomSize = hostel['singleRoomSize']?.toString() ?? '';
        _doubleRoomSize = hostel['doubleRoomSize']?.toString() ?? '';
      }

      final doc = await _firestore
          .collection('hostels')
          .doc(widget.hostelId)
          .collection('floors')
          .doc(widget.floorId)
          .collection('rooms')
          .doc(widget.roomId)
          .get();

      if (!doc.exists) {
        setState(() => _loading = false);
        return;
      }

      final data = doc.data()!;

      setState(() {
        _roomNumber = data['roomNumber']?.toString() ?? '';
        _availability = data['status'] ?? 'Available';
        _roomType = data['roomType'] ?? 'Single';
        _descriptionController.text = data['description'] ?? '';
        _occupied = data['occupied'] ?? 0;
        _capacity = data['capacity'] ?? (_roomType == 'Double' ? 2 : 1);

        _selectedFeatures.clear();
        if (data['features'] is Map<String, dynamic>) {
          final features = Map<String, dynamic>.from(data['features']);
          features.forEach((key, value) {
            if (value is bool && value) _selectedFeatures.add(key);
          });
        }

        _loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() => _loading = false);
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
        title: Text('Update Room $_roomNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Describe this room...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text('Current Occupants', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text(
                    'Update how many students currently occupy this room.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_occupied > 0) {
                              setState(() {
                                _occupied--;
                                _availability = _occupied == _capacity ? "Occupied" : "Available";
                              });
                            }
                          },
                          icon: const Icon(Icons.remove_circle),
                          color: Colors.red,
                        ),
                        Expanded(
                          child: Center(
                            child: Text('$_occupied / $_capacity', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (_occupied < _capacity) {
                              setState(() {
                                _occupied++;
                                _availability = _occupied == _capacity ? "Occupied" : "Available";
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

                  const Text('Occupancy Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Choose the current room status.', style: TextStyle(fontSize: 12, color: Colors.grey)),
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

                  const Text('Room Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _typeButton("Single"),
                      const SizedBox(width: 8),
                      _typeButton("Double"),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Room Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.straighten, color: Colors.blue),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('Room Size (ft): ${_roomType == "Single" ? _singleRoomSize : _doubleRoomSize}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.payments, color: Colors.green),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('Price per Semester: UGX ${_roomType == "Single" ? _singlePrice : _doublePrice}'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text('Room Features', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Select all features that apply.', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                            .collection('hostels')
                            .doc(widget.hostelId)
                            .collection('floors')
                            .doc(widget.floorId)
                            .collection('rooms')
                            .doc(widget.roomId)
                            .update({
                          'status': _availability,
                          'roomType': _roomType,
                          'occupied': _occupied,
                          'capacity': _capacity,
                          'description': _descriptionController.text.trim(),
                          'features': {
                            for (var f in _features) f: _selectedFeatures.contains(f),
                          },
                        });

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Room status updated instantly across all platforms!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
            style: TextStyle(color: selected ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 13),
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
            _capacity = label == "Single" ? 1 : 2;
            if (_occupied > _capacity) _occupied = _capacity;
            _availability = _occupied == _capacity ? "Occupied" : "Available";
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.blue : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: selected ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
    );
  }
}