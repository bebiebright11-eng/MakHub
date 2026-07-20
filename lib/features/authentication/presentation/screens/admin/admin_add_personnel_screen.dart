import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAddPersonnelScreen extends StatefulWidget {
  final String hostelId;
  final String hostelName;

  const AdminAddPersonnelScreen({
    super.key,
    required this.hostelId,
    required this.hostelName,
  });

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
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Add Personnel",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [

            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.person_add,
                color: Colors.white,
                size: 45,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Create Hostel Personnel",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Create an account for personnel who will manage this hostel.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 30),

            _buildField(
              "Full Name",
              "Enter full name",
              Icons.person_outline,
              _fullNameController,
            ),

            const SizedBox(height: 18),

            _buildField(
              "Email Address",
              "Enter email",
              Icons.email_outlined,
              _emailController,
            ),

            const SizedBox(height: 18),

            _buildField(
              "Phone Number",
              "Enter phone number",
              Icons.phone_outlined,
              _phoneController,
            ),

            const SizedBox(height: 18),

            _buildReadOnlyField(
              "Hostel",
              widget.hostelName,
              Icons.apartment,
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(

                onPressed: () async {

  if (_fullNameController.text.trim().isEmpty ||
      _emailController.text.trim().isEmpty ||
      _phoneController.text.trim().isEmpty) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please fill all fields"),
      ),
    );

    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {

    await FirebaseFirestore.instance
        .collection("personnel")
        .add({

      "fullName": _fullNameController.text.trim(),

      "email": _emailController.text.trim(),

      "phoneNumber": _phoneController.text.trim(),

      "hostelId": widget.hostelId,

      "hostelName": widget.hostelName,

      "role": "hostelPersonnel",

      "activated": false,

      "firebaseUid": "",

      "createdAt": FieldValue.serverTimestamp(),

    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Personnel created successfully."),
      ),
    );

    Navigator.pop(context);

  } catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
      ),
    );

  }

  setState(() {
    _isLoading = false;
  });

},

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),

                child: _isLoading

                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )

                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          Icon(
                            Icons.save,
                            color: Colors.white,
                          ),

                          SizedBox(width: 10),

                          Text(
                            "Create Personnel",
                            style: TextStyle(
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
      TextEditingController controller,
      ) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,

          decoration: InputDecoration(

            hintText: hint,

            prefixIcon: Icon(icon),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),

            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(
      String label,
      String value,
      IconData icon,
      ) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

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