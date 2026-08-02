import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'hostel_media_mixin.dart';

class AdminAddHostelScreen extends StatefulWidget {
  const AdminAddHostelScreen({super.key});

  @override
  State<AdminAddHostelScreen> createState() => _AdminAddHostelScreenState();
}

class _AdminAddHostelScreenState extends State<AdminAddHostelScreen>
    with HostelMediaMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _distanceController = TextEditingController();
  final _walkingTimeController = TextEditingController();
  final _mapsLinkController = TextEditingController();
  final _singlePriceController = TextEditingController();
  final _doublePriceController = TextEditingController();
  final _shopsController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _atmController = TextEditingController();
  final _singleRoomSizeController = TextEditingController();
  final _doubleRoomSizeController = TextEditingController();


  String _selectedType = "Mixed";

  final List<String> _locations = ["Kikumi", "Near Main Gate", "Kikoni"];
  String? _selectedLocation;
  final Set<String> _selectedFacilities = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSaving = false;

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
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _distanceController.dispose();
    _walkingTimeController.dispose();
    _mapsLinkController.dispose();
    _singlePriceController.dispose();
    _doublePriceController.dispose();
    _singleRoomSizeController.dispose();
    _doubleRoomSizeController.dispose();
    _shopsController.dispose();
    _hospitalController.dispose();
    _atmController.dispose();
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
        title: const Text("Add Hostel"),
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
                DropdownButtonFormField<String>(
                  initialValue: _selectedLocation,
                  decoration: _decoration("Select location"),
                  items: _locations.map((loc) {
                    return DropdownMenuItem(value: loc, child: Text(loc));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedLocation = value);
                  },
                  validator: (value) =>
                      value == null ? "Please select a location" : null,
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

                buildPhotosTile(),
                const SizedBox(height: 10),
                buildVideoTile(),

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
                      selectedColor: AppColors.primary.withValues(alpha: 0.08),
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
                    onPressed: _isSaving
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() => _isSaving = true);
                            try {
                              // 1. Create the hostel document first to get its ID
                              final docRef =
                                  await _firestore.collection('hostels').add({
                                'hostelName': _nameController.text.trim(),
                                'location': _selectedLocation,
                                'description':
                                    _descriptionController.text.trim(),
                                'type': _selectedType,
                                'distance': _distanceController.text.trim(),
                                'walkingTime':
                                    _walkingTimeController.text.trim(),
                                'mapsLink': _mapsLinkController.text.trim(),
                                'singleRoomSize':
                                    _singleRoomSizeController.text.trim(),
                                'doubleRoomSize':
                                    _doubleRoomSizeController.text.trim(),
                                'singlePrice':
                                    _singlePriceController.text.trim(),
                                'doublePrice':
                                    _doublePriceController.text.trim(),
                                'facilities': _selectedFacilities.toList(),
                                'shops': _shopsController.text.trim(),
                                'hospital': _hospitalController.text.trim(),
                                'atm': _atmController.text.trim(),
                                'createdBy': _auth.currentUser!.uid,
                                'createdAt': FieldValue.serverTimestamp(),
                                'photos': <String>[],
                                'videos': <String>[],
                              });

                              // 2. Upload picked media under hostels/{id}/...
                              List<String> photoUrls = const [];
                              List<String> videoUrls = const [];
                              if (hasPickedMedia) {
                                final uploaded =
                                    await uploadNewMedia(docRef.id);
                                photoUrls = uploaded['photos']!;
                                videoUrls = uploaded['videos']!;
                                await docRef.update({
                                  'photos': photoUrls,
                                  'videos': videoUrls,
                                });
                              }

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Hostel added successfully'),
                                ),
                              );
                              Navigator.pop(context);
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _isSaving = false);
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
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Save Hostel",
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
}

