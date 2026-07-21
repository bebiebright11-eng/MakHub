import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateRoomStatusScreen extends StatefulWidget {
  final String hostelId;
  final String floorId;
  final String roomId;
  const UpdateRoomStatusScreen({super.key, required this.roomId, required this.hostelId, required this.floorId});

  @override
  State<UpdateRoomStatusScreen> createState() => _UpdateRoomStatusScreenState();
}

class _UpdateRoomStatusScreenState extends State<UpdateRoomStatusScreen> {
  String _availability = 'Available';
  int _occupancy = 1;
  int _capacity = 1;
  String _roomNumber = '';
  bool _isloading = true;

  @override
  void initState() {
    super.initState();
    _loadRoomData();
  }

  Future<void> _loadRoomData() async {
    try {
      final roomSnapshot = await FirebaseFirestore.instance
          .collection('hostels')
          .doc(widget.hostelId)
          .collection('floors')
          .doc(widget.floorId)
          .collection('rooms')
          .doc(widget.roomId)
          .get();

      if (roomSnapshot.exists) {
        final data = roomSnapshot.data()!;
        setState(() {
          _availability = data['status'] ?? 'Available';
          _occupancy = data['occupied'] ?? 1;
          _capacity = data['capacity'] ?? 1;
          _roomNumber = data['roomNumber'] ?? '';
          _isloading = false;
        });
      } 
    } catch (e) {  
      setState(() => _isloading = false);
    }
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
      body: _isloading
          ? const Center(child: CircularProgressIndicator())
      : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Availability Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildChoiceChipGroup(['Available', 'Reserved', 'Occupied'], _availability, (val) => setState(() => _availability = val)),
            const SizedBox(height: 24),
            const Text('Occupancy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildChoiceChipGroup(
              List.generate(_capacity+1, (i) => '$i/$_capacity'),
              '$_occupancy/$_capacity',
              (val) => setState(() => _occupancy = int.parse(val.split('/')[0])),

           ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('hostels')
                      .doc(widget.hostelId)
                      .collection('floors')
                      .doc(widget.floorId)
                      .collection('rooms')
                      .doc(widget.roomId)
                      .update({
                    'status': _availability,
                    'occupied': _occupancy,
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
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChipGroup(List<String> options, String selected, Function(String) onSelected) {
    return Wrap(
      spacing: 8,
      children: options.map((option) {
        final isSelected = selected == option;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          selectedColor: const Color(0xFF2563EB),
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
        );
      }).toList(),
    );
  }
}
