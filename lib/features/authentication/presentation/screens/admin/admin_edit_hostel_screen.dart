import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminEditHostelScreen extends StatefulWidget {
  final String hostelId;
  final Map<String, dynamic> hostelData;

  const AdminEditHostelScreen({
    super.key,
    required this.hostelId,
    required this.hostelData,
  });

  @override
  State<AdminEditHostelScreen> createState() =>
      _AdminEditHostelScreenState();
}

class _AdminEditHostelScreenState extends State<AdminEditHostelScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _distanceController = TextEditingController();
  final _walkingTimeController = TextEditingController();
  final _mapsLinkController = TextEditingController();
  final _singlePriceController = TextEditingController();
  final _doublePriceController = TextEditingController();
  final _singleRoomSizeController = TextEditingController();
  final _doubleRoomSizeController = TextEditingController();
  final _shopsController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _atmController = TextEditingController();

  String _selectedType = "Mixed";
  final Set<String> _selectedFacilities = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> _facilities = [
    "WiFi",
    "Kitchen",
    "DSTV",
    "Laundry",
    "Reading Room",
    "Swimming Pool",
    "Pool Table",
    "Shuttle",
    "Security",
  ];

@override
void initState() {
  super.initState();

  _nameController.text =
      widget.hostelData['hostelName'] ?? '';

  _locationController.text =
      widget.hostelData['location'] ?? '';

  _descriptionController.text =
      widget.hostelData['description'] ?? '';

  _distanceController.text =
      widget.hostelData['distance'] ?? '';

  _walkingTimeController.text =
      widget.hostelData['walkingTime'] ?? '';

  _mapsLinkController.text =
      widget.hostelData['mapsLink'] ?? '';

  _singlePriceController.text =
      widget.hostelData['singlePrice'] ?? '';

  _doublePriceController.text =
      widget.hostelData['doublePrice'] ?? '';

  _shopsController.text =
      widget.hostelData['shops'] ?? '';

  _hospitalController.text =
      widget.hostelData['hospital'] ?? '';

  _atmController.text =
      widget.hostelData['atm'] ?? '';

  _singleRoomSizeController.text =
      widget.hostelData['singleRoomSize'] ?? '';

  _doubleRoomSizeController.text =
      widget.hostelData['doubleRoomSize'] ?? '';

  _selectedType =
      widget.hostelData['type'] ?? 'Mixed';

  _selectedFacilities.addAll(
    List<String>.from(
      widget.hostelData['facilities'] ?? [],
    ),
  );
}

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _distanceController.dispose();
    _walkingTimeController.dispose();
    _mapsLinkController.dispose();
    _singlePriceController.dispose();
    _doublePriceController.dispose();
    _shopsController.dispose();
    _hospitalController.dispose();
    _atmController.dispose();
    _singleRoomSizeController.dispose();
    _doubleRoomSizeController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Hostel"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Create a new hostel listing with details, pricing, and amenities.",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),

                _sectionTitle("Hostel Information", "Enter the core hostel details."),

                _fieldLabel("Hostel Name"),
                TextFormField(
                  controller: _nameController,
                  decoration: _decoration("e.g. Green Valley Hostel"),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Please enter hostel name" : null,
                ),

                _fieldLabel("Location"),
                TextFormField(
                  controller: _locationController,
                  decoration: _decoration("e.g. Near Main Gate"),
                ),

                _fieldLabel("Description"),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: _decoration(
                      "Describe the hostel, atmosphere, and key highlights."),
                ),

                _fieldLabel("Hostel Type"),
                Wrap(
                  spacing: 10,
                  children: ["Girls", "Boys", "Mixed"].map((type) {
                    final selected = _selectedType == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedType = type);
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black,
                      ),
                    );
                  }).toList(),
                ),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel("Distance to Campus"),
                          TextFormField(
                            controller: _distanceController,
                            decoration: _decoration("e.g. 1.2 km"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel("Walking Time"),
                          TextFormField(
                            controller: _walkingTimeController,
                            decoration: _decoration("e.g. 15 mins"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                _fieldLabel("Google Maps Location"),
                TextFormField(
                  controller: _mapsLinkController,
                  decoration: _decoration("Paste Google Maps link"),
                ),

                const SizedBox(height: 10),

Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel("Single Room Size (ft)"),
          TextFormField(
            controller: _singleRoomSizeController,
            decoration: _decoration("e.g. 8 × 10"),
          ),
        ],
      ),
    ),

    const SizedBox(width: 12),

    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel("Double Room Size (ft)"),
          TextFormField(
            controller: _doubleRoomSizeController,
            decoration: _decoration("e.g. 10 × 12"),
          ),
        ],
      ),
    ),
  ],
),

const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel("Single Room Price"),
                          TextFormField(
                            controller: _singlePriceController,
                            keyboardType: TextInputType.number,
                            decoration: _decoration("e.g. 2500"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel("Double Room Price"),
                          TextFormField(
                            controller: _doublePriceController,
                            keyboardType: TextInputType.number,
                            decoration: _decoration("e.g. 1800"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                _sectionTitle("Media Uploads", "Add photos and a tour video for better visibility."),

                _uploadTile(
                  icon: Icons.photo,
                  title: "Upload Photos",
                  subtitle: "PNG, JPG up to 10MB each",
                ),
                const SizedBox(height: 10),
                _uploadTile(
                  icon: Icons.videocam,
                  title: "Upload Tour Video",
                  subtitle: "MP4, MOV up to 100MB",
                ),

                _sectionTitle("Facilities", "Select the amenities available at this hostel."),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _facilities.map((facility) {
                    final selected = _selectedFacilities.contains(facility);
                    return FilterChip(
                      label: Text(facility),
                      selected: selected,
                      onSelected: (isSelected) {
                        setState(() {
                          if (isSelected) {
                            _selectedFacilities.add(facility);
                          } else {
                            _selectedFacilities.remove(facility);
                          }
                        });
                      },
                      selectedColor: AppColors.primary.withOpacity(0.08),
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                ),

                _sectionTitle("Nearby Places", "Add nearby conveniences around the hostel."),

                _fieldLabel("Shops"),
                TextFormField(
                  controller: _shopsController,
                  decoration: _decoration("e.g. 2 min walk"),
                ),

                _fieldLabel("Hospital"),
                TextFormField(
                  controller: _hospitalController,
                  decoration: _decoration("e.g. 10 min drive"),
                ),

                _fieldLabel("ATM"),
                TextFormField(
                  controller: _atmController,
                  decoration: _decoration("e.g. 5 min walk"),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
child: ElevatedButton(
  onPressed: () async {
    if (_formKey.currentState!.validate()) {
      try {
        await _firestore
    .collection('hostels')
    .doc(widget.hostelId)
    .update({
          'hostelName': _nameController.text.trim(),
          'location': _locationController.text.trim(),
          'description': _descriptionController.text.trim(),
          'type': _selectedType,
          'distance': _distanceController.text.trim(),
          'walkingTime': _walkingTimeController.text.trim(),
          'mapsLink': _mapsLinkController.text.trim(),
          'singlePrice': _singlePriceController.text.trim(),
          'doublePrice': _doublePriceController.text.trim(),
          'singleRoomSize': _singleRoomSizeController.text.trim(),
          'doubleRoomSize': _doubleRoomSizeController.text.trim(),
          'facilities': _selectedFacilities.toList(),
          'shops': _shopsController.text.trim(),
          'hospital': _hospitalController.text.trim(),
          'atm': _atmController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hostel updated successfully'),
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    }
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
    "Update Hostel",
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  ),
),


                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _uploadTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
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
    );
  }
}

