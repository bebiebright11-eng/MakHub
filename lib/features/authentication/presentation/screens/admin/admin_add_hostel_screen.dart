import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAddHostelScreen extends StatefulWidget {
  const AdminAddHostelScreen({super.key});

  @override
  State<AdminAddHostelScreen> createState() => _AdminAddHostelScreenState();
}

class _AdminAddHostelScreenState extends State<AdminAddHostelScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _distanceController = TextEditingController();
  final _walkingTimeController = TextEditingController();
  final _mapsLinkController = TextEditingController();
  final _singlePriceController = TextEditingController();
  final _doublePriceController = TextEditingController();
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
                      selectedColor: Colors.blue,
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
                      selectedColor: Colors.blue.shade50,
                      checkmarkColor: Colors.blue,
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
        await _firestore.collection('hostels').add({
          'hostelName': _nameController.text.trim(),
          'location': _locationController.text.trim(),
          'description': _descriptionController.text.trim(),
          'type': _selectedType,
          'distance': _distanceController.text.trim(),
          'walkingTime': _walkingTimeController.text.trim(),
          'mapsLink': _mapsLinkController.text.trim(),
          'singlePrice': _singlePriceController.text.trim(),
          'doublePrice': _doublePriceController.text.trim(),
          'facilities': _selectedFacilities.toList(),
          'shops': _shopsController.text.trim(),
          'hospital': _hospitalController.text.trim(),
          'atm': _atmController.text.trim(),
          'createdBy': _auth.currentUser!.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hostel added successfully'),
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
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),

  child: const Text(
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
          Icon(icon, color: Colors.blue),
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