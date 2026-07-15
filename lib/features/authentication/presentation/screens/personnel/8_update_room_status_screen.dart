import 'package:flutter/material.dart';

class UpdateRoomStatusScreen extends StatefulWidget {
  final String roomNumber;
  const UpdateRoomStatusScreen({super.key, required this.roomNumber});

  @override
  State<UpdateRoomStatusScreen> createState() => _UpdateRoomStatusScreenState();
}

class _UpdateRoomStatusScreenState extends State<UpdateRoomStatusScreen> {
  String _availability = 'Occupied';
  String _occupancy = '1/1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Room ${widget.roomNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
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
            _buildChoiceChipGroup(['0/1', '1/1'], _occupancy, (val) => setState(() => _occupancy = val)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room status updated in real-time!')));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: BorderRadius.circular(12),
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
