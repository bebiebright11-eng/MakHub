import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentPreferenceScreen extends StatefulWidget {
  const StudentPreferenceScreen({super.key});

  @override
  State<StudentPreferenceScreen> createState() =>
      _StudentPreferenceScreenState();
}

class _StudentPreferenceScreenState
    extends State<StudentPreferenceScreen> {

  String _budget = "";
  String _roomType = "";
  String _hostelType = "";
  String _location = "";

  final List<String> _selectedFacilities = [];

  final List<String> facilities = [
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
  Future<void> _savePreferences() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  print(user.uid);

  final doc = await FirebaseFirestore.instance
      .collection("users")
      .doc(user.uid)
      .get();

  print(doc.exists);

  try {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .set({
      "preferences": {
        "preferredType":_hostelType,
        "roomType": _roomType,
        "maxBudget":_budget,
        "preferredLocation":_location,
        "facilities":_selectedFacilities,
      },
    },SetOptions(merge:true ));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Preferences saved successfully."),
      ),
    );

    Navigator.pop(context);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hostel Preferences"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            const Text(
              "Preferred Budget",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),

            RadioListTile(
              title: const Text("Below UGX 300,000"),
              value: "below300000",
              groupValue: _budget,
              onChanged: (value) {
                setState(() {
                  _budget = value!;
                });
              },
            ),

            RadioListTile(
              title: const Text("UGX 300,000 - 500,000"),
              value: "300000-500000",
              groupValue: _budget,
              onChanged: (value) {
                setState(() {
                  _budget = value!;
                });
              },
            ),

            RadioListTile(
              title: const Text("Above UGX 500,000"),
              value: "above500000",
              groupValue: _budget,
              onChanged: (value) {
                setState(() {
                  _budget = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            const Text(
              "Room Type",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),

            RadioListTile(
              title: const Text("Single"),
              value: "Single",
              groupValue: _roomType,
              onChanged: (value) {
                setState(() {
                  _roomType = value!;
                });
              },
            ),

            RadioListTile(
              title: const Text("Double"),
              value: "Double",
              groupValue: _roomType,
              onChanged: (value) {
                setState(() {
                  _roomType = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            const Text(
              "Hostel Type",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),

            RadioListTile(
              title: const Text("Boys"),
              value: "boys",
              groupValue: _hostelType,
              onChanged: (value) {
                setState(() {
                  _hostelType = value!;
                });
              },
            ),

            RadioListTile(
              title: const Text("Girls"),
              value: "girls",
              groupValue: _hostelType,
              onChanged: (value) {
                setState(() {
                  _hostelType = value!;
                });
              },
            ),

            RadioListTile(
              title: const Text("Mixed"),
              value: "mixed",
              groupValue: _hostelType,
              onChanged: (value) {
                setState(() {
                  _hostelType = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            const Text(
              "Facilities",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),

            ...facilities.map((facility) {
              return CheckboxListTile(
                title: Text(facility),
                value: _selectedFacilities.contains(facility),
                onChanged: (checked) {

                  setState(() {

                    if (checked == true) {
                      _selectedFacilities.add(facility);
                    } else {
                      _selectedFacilities.remove(facility);
                    }

                  });

                },
              );
            }),

            const SizedBox(height: 20),

            const Text(
              "Preferred Location",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),

            const SizedBox(height: 10),

            TextField(
              decoration: const InputDecoration(
                hintText: "e.g. Wandegeya",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _location = value;
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _savePreferences();

                },
                child: const Text("Save Preferences"),
              ),
            ),
          ],
        ),
      ),
      
    );
    
  }
}