import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Create or edit a hostel personnel account.
///
/// **Create mode** (default): [personnelId] is null.
///   – Calls `collection('personnel').add(...)`.
///   – Writes `status: 'Active'`.
///
/// **Edit mode**: [personnelId] and [existingData] are provided.
///   – Pre-fills every field from [existingData].
///   – Calls `doc(personnelId).update(...)`.
///   – Button label changes to "Update Personnel".
class AdminAddPersonnelScreen extends StatefulWidget {
  final String hostelId;
  final String hostelName;

  /// Non-null only in edit mode — the Firestore document ID of the personnel.
  final String? personnelId;

  /// Non-null only in edit mode — the existing personnel data to pre-fill.
  final Map<String, dynamic>? existingData;

  const AdminAddPersonnelScreen({
    super.key,
    required this.hostelId,
    required this.hostelName,
    this.personnelId,
    this.existingData,
  });

  bool get isEditMode => personnelId != null && existingData != null;

  @override
  State<AdminAddPersonnelScreen> createState() =>
      _AdminAddPersonnelScreenState();
}

class _AdminAddPersonnelScreenState
    extends State<AdminAddPersonnelScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      final d = widget.existingData!;
      _fullNameController.text = (d['fullName'] ?? '').toString();
      _emailController.text = (d['email'] ?? '').toString();
      _phoneController.text = (d['phoneNumber'] ?? '').toString();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_fullNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.isEditMode) {
        // ── Edit mode: update existing document ────────────────────────
        await FirebaseFirestore.instance
            .collection('personnel')
            .doc(widget.personnelId)
            .update({
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personnel updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // ── Create mode: add new document ──────────────────────────────
        await FirebaseFirestore.instance
            .collection('personnel')
            .add({
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'hostelId': widget.hostelId,
          'hostelName': widget.hostelName,
          'role': 'hostelPersonnel',
          'activated': false,
          'status': 'Active',
          'firebaseUid': '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personnel created successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEditMode;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isEdit ? 'Edit Personnel' : 'Add Personnel',
          style: const TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isEdit ? Icons.manage_accounts : Icons.person_add,
                color: Colors.white,
                size: 45,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              isEdit ? 'Edit Hostel Personnel' : 'Create Hostel Personnel',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isEdit
                  ? 'Update the personnel information for this hostel.'
                  : 'Create an account for personnel who will manage this hostel.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 30),

            _buildField(
              'Full Name',
              'Enter full name',
              Icons.person_outline,
              _fullNameController,
            ),

            const SizedBox(height: 18),

            _buildField(
              'Email Address',
              'Enter email',
              Icons.email_outlined,
              _emailController,
              // Disable email editing in edit mode — it ties to the Firebase
              // Auth account and cannot be changed here without re-authentication.
              readOnly: isEdit,
            ),

            const SizedBox(height: 18),

            _buildField(
              'Phone Number',
              'Enter phone number',
              Icons.phone_outlined,
              _phoneController,
            ),

            const SizedBox(height: 18),

            _buildReadOnlyField(
              'Hostel',
              widget.hostelName,
              Icons.apartment,
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isEdit ? Icons.save : Icons.save,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isEdit
                                ? 'Update Personnel'
                                : 'Create Personnel',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            filled: readOnly,
            fillColor: readOnly ? Colors.grey.shade100 : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(
      String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          readOnly: true,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            hintText: value,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}
