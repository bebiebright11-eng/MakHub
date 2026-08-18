import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_dashboard_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_notification_screen.dart';
import 'admin_profile_screen.dart';
import 'hostel_media_mixin.dart';

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

class _AdminEditHostelScreenState extends State<AdminEditHostelScreen>
    with HostelMediaMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _hostelCodeController = TextEditingController();
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
  bool _isSaving = false;
  bool _isUploadingPhotos = false;

  // URLs of photos already stored in Firestore for this hostel
  List<String> _existingPhotos = [];

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

  // Tell the mixin how many photos already exist so combined limit is respected.
  @override
  int get existingPhotosCount => _existingPhotos.length;

  @override
  void initState() {
  super.initState();

  _nameController.text =
      widget.hostelData['hostelName'] ?? '';

  _hostelCodeController.text =
      (widget.hostelData['hostelCode'] ?? '').toString().toUpperCase();

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

  _existingPhotos = List<String>.from(
    (widget.hostelData['photos'] ?? const <String>[]).whereType<String>(),
  );
}

  @override
  void dispose() {
    _nameController.dispose();
    _hostelCodeController.dispose();
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

  /// Returns true when [code] is already used by a *different* hostel.
  Future<bool> _hostelCodeTaken(String code) async {
    final snap = await _firestore
        .collection('hostels')
        .where('hostelCode', isEqualTo: code)
        .limit(2)
        .get();
    // Allow the code if the only match is this hostel itself.
    return snap.docs.any((doc) => doc.id != widget.hostelId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Hostel"),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            Navigator.pop(context);
            return;
          }
          switch (index) {
            case 0:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminDashboardScreen()),
                (route) => false,
              );
              break;
            case 2:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminBookingsScreen()),
                (route) => false,
              );
              break;
            case 3:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminNotificationsScreen()),
                (route) => false,
              );
              break;
            case 4:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminProfileScreen()),
                (route) => false,
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.apartment), label: 'Hostels'),
          BottomNavigationBarItem(
              icon: Icon(Icons.book), label: 'Bookings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
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

                _fieldLabel("Hostel Code"),
                TextFormField(
                  controller: _hostelCodeController,
                  decoration: _decoration("e.g. DW, OL, DC  (2–3 letters)"),
                  // Force uppercase as the user types
                  onChanged: (v) {
                    final upper = v.toUpperCase();
                    if (v != upper) {
                      _hostelCodeController.value =
                          _hostelCodeController.value.copyWith(
                        text: upper,
                        selection:
                            TextSelection.collapsed(offset: upper.length),
                      );
                    }
                  },
                  validator: (v) {
                    // Existing listings created before hostel codes were
                    // introduced may not have one. Keep those editable.
                    if (v == null || v.trim().isEmpty) return null;
                    final code = v.trim().toUpperCase();
                    if (code.length < 2 || code.length > 3) {
                      return 'Code must be 2 or 3 letters';
                    }
                    if (!RegExp(r'^[A-Z]+$').hasMatch(code)) {
                      return 'Only letters A–Z are allowed (no numbers or symbols)';
                    }
                    return null;
                  },
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

                _sectionTitle("Media Uploads", "Add up to 30 photos for better visibility."),

                // ── Existing photos (already uploaded to Firebase Storage) ──
                if (_existingPhotos.isNotEmpty) ...[
                  const Text(
                    "Current Photos",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _existingPhotos.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                _existingPhotos[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.grey),
                                ),
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _existingPhotos.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Pick new photos ──────────────────────────────────────────
                buildPhotosTile(
                  isSaving: _isUploadingPhotos,
                  onSave: () async {
                    setState(() => _isUploadingPhotos = true);
                    try {
                      final uploaded = await uploadNewMedia(widget.hostelId);
                      clearPickedPhotos();
                      setState(() {
                        _existingPhotos.addAll(uploaded);
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${uploaded.length} photo(s) saved. Press "Update Hostel" to apply all changes.'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Photo upload failed: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isUploadingPhotos = false);
                    }
                  },
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
                    onPressed: (_isSaving || _isUploadingPhotos)
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please correct the highlighted fields before updating.'),
                                ),
                              );
                              return;
                            }

                            // Warn if there are unsaved picked photos
                            if (hasPickedMedia) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'You have unsaved photos. Press "Save Photos" first, then update.'),
                                ),
                              );
                              return;
                            }

                            setState(() => _isSaving = true);
                            try {
                              final code =
                                  _hostelCodeController.text.trim().toUpperCase();

                              // Uniqueness check — reject if another hostel already uses this code
                              final codeTaken = await _hostelCodeTaken(code);
                              if (codeTaken) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Hostel Code "$code" is already used by another hostel. Please choose a different code.'),
                                  ),
                                );
                                setState(() => _isSaving = false);
                                return;
                              }

                              // Upload newly picked photos (if any) and merge with existing URLs
                              List<String> finalPhotos = List.from(_existingPhotos);

                              if (hasPickedMedia) {
                                final newUrls =
                                    await uploadNewMedia(widget.hostelId);
                                finalPhotos.addAll(newUrls);
                              }

                              await _firestore
                                  .collection('hostels')
                                  .doc(widget.hostelId)
                                  .update({
                                'hostelName': _nameController.text.trim(),
                                'hostelCode': code,
                                'location': _locationController.text.trim(),
                                'description':
                                    _descriptionController.text.trim(),
                                'type': _selectedType,
                                'distance': _distanceController.text.trim(),
                                'walkingTime':
                                    _walkingTimeController.text.trim(),
                                'mapsLink': _mapsLinkController.text.trim(),
                                'singlePrice':
                                    _singlePriceController.text.trim(),
                                'doublePrice':
                                    _doublePriceController.text.trim(),
                                'singleRoomSize':
                                    _singleRoomSizeController.text.trim(),
                                'doubleRoomSize':
                                    _doubleRoomSizeController.text.trim(),
                                'facilities': _selectedFacilities.toList(),
                                'shops': _shopsController.text.trim(),
                                'hospital': _hospitalController.text.trim(),
                                'atm': _atmController.text.trim(),
                                'photos': finalPhotos,
                                'updatedAt': FieldValue.serverTimestamp(),
                              });

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Hostel updated successfully'),
                                ),
                              );
                              Navigator.pop(context);
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            } finally {
                              if (mounted) setState(() => _isSaving = false);
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
}

