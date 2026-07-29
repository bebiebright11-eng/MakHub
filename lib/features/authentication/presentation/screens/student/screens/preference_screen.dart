import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/constants/app_colors.dart';

class StudentPreferenceScreen extends StatefulWidget {
  const StudentPreferenceScreen({super.key});

  @override
  State<StudentPreferenceScreen> createState() =>
      _StudentPreferenceScreenState();
}

class _StudentPreferenceScreenState extends State<StudentPreferenceScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  String _budget = "";
  String _roomType = "";
  String _hostelType = "";
  String _location = "";

  final List<String> _selectedFacilities = [];

  final TextEditingController _locationController = TextEditingController();

  final List<String> _facilities = [
    "Wi-Fi",
    "Laundry",
    "Kitchen",
    "Reading Room",
    "Shuttle",
    "Swimming Pool",
    "Security",
    "DSTV",
    "Pool Table",
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _loadSavedPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final prefs =
            Map<String, dynamic>.from(doc.data()?['preferences'] ?? {});

        final savedFacilities =
            List<String>.from(prefs['facilities'] ?? []);

        setState(() {
          _budget = prefs['maxBudget'] ?? '';
          _roomType = prefs['roomType'] ?? '';
          _hostelType = prefs['preferredType'] ?? '';
          _location = prefs['preferredLocation'] ?? '';
          _locationController.text = _location;
          _selectedFacilities
            ..clear()
            ..addAll(savedFacilities);
        });
      }
    } catch (_) {
      // If loading fails just show empty — user can re-enter
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'preferences': {
          'preferredType': _hostelType,
          'roomType': _roomType,
          'maxBudget': _budget,
          'preferredLocation': _locationController.text.trim(),
          'facilities': _selectedFacilities,
        },
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved. Your home screen will update.'),
          backgroundColor: Colors.green,
        ),
      );

      // Pop back so home screen can refresh
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Hostel Preferences',
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.primary, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'These preferences personalise the hostels '
                            'recommended on your home screen.',
                            style: TextStyle(
                                color: AppColors.primary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Budget ──────────────────────────────────────────────
                  _sectionTitle('Preferred Budget'),
                  RadioGroup<String>(
                    groupValue: _budget,
                    onChanged: (v) => setState(() => _budget = v!),
                    child: Column(
                      children: [
                        _radioTile(
                          label: 'Below UGX 300,000',
                          value: 'below300000',
                        ),
                        _radioTile(
                          label: 'UGX 300,000 – 500,000',
                          value: '300000-500000',
                        ),
                        _radioTile(
                          label: 'Above UGX 500,000',
                          value: 'above500000',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Room type ───────────────────────────────────────────
                  _sectionTitle('Room Type'),
                  RadioGroup<String>(
                    groupValue: _roomType,
                    onChanged: (v) => setState(() => _roomType = v!),
                    child: Column(
                      children: [
                        _radioTile(label: 'Single', value: 'Single'),
                        _radioTile(label: 'Double', value: 'Double'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Hostel type ─────────────────────────────────────────
                  _sectionTitle('Hostel Type'),
                  RadioGroup<String>(
                    groupValue: _hostelType,
                    onChanged: (v) => setState(() => _hostelType = v!),
                    child: Column(
                      children: [
                        _radioTile(label: 'Boys', value: 'boys'),
                        _radioTile(label: 'Girls', value: 'girls'),
                        _radioTile(label: 'Mixed', value: 'mixed'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Location ────────────────────────────────────────────
                  _sectionTitle('Preferred Location'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Wandegeya, Kikoni',
                      prefixIcon: const Icon(Icons.location_on_outlined,
                          color: AppColors.primary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Facilities ──────────────────────────────────────────
                  _sectionTitle('Must-have Facilities'),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: _facilities.map((facility) {
                      final selected = _selectedFacilities.contains(facility);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedFacilities.remove(facility);
                            } else {
                              _selectedFacilities.add(facility);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selected) ...[
                                const Icon(Icons.check,
                                    size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                facility,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // ── Save button ─────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Save Preferences',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

    Widget _radioTile({
    required String label,
    required String value,
  }) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}
