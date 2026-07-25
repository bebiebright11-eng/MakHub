import 'package:flutter/material.dart';
import 'admin_hostel_details_screen.dart';
import 'admin_add_hostel_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_edit_hostel_screen.dart';

class AdminHostelsScreen extends StatefulWidget {
const AdminHostelsScreen({super.key});
  @override
  State<AdminHostelsScreen> createState() =>
      _AdminHostelsScreenState();
}

class _AdminHostelsScreenState
    extends State<AdminHostelsScreen> {

  String searchQuery = '';
  String selectedFilter = 'All';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hostel Management"),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 15),
            child: Icon(Icons.more_vert),
          )
        ],
      ),

      body: Padding(
  padding: const EdgeInsets.all(16),
  child: SingleChildScrollView(
    child: Column(
      children: [

        TextField(
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: "Search hostels...",
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 15),

  SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
_filterChip("All"),

        const SizedBox(width: 8),

        _filterChip("Boys"),

        const SizedBox(width: 8),

        _filterChip("Girls"),

        const SizedBox(width: 8),

        _filterChip("Mixed"),
      ],
    ),
  ),

  const SizedBox(height: 20),

StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('hostels')
      .snapshots(),
  builder: (context, snapshot) {

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Center(
        child: Text("No hostels found"),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: snapshot.data!.docs.length,
      itemBuilder: (context, index) {

        final hostel = snapshot.data!.docs[index];
        final data = hostel.data() as Map<String, dynamic>;
        final hostelName =
    (data['hostelName'] ?? '').toString().toLowerCase();

final hostelType =
    (data['type'] ?? '').toString();

if (!hostelName.contains(searchQuery)) {
  return const SizedBox.shrink();
}

if (selectedFilter != 'All' &&
    hostelType != selectedFilter) {
  return const SizedBox.shrink();
}
                

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 20),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.apartment,
                      size: 70,
                      color: Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  data['hostelName'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(data['location'] ?? ''),
    Text(
      "${data['distance']} from campus",
      style: const TextStyle(
        color: Colors.grey,
      ),
    ),
  ],
),

                const SizedBox(height: 10),

                Row(
  children: [
    Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          "Single\nUGX ${data['singlePrice']}",
          textAlign: TextAlign.center,
        ),
      ),
    ),

    const SizedBox(width: 10),

    Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          "Double\nUGX ${data['doublePrice']}",
          textAlign: TextAlign.center,
        ),
      ),
    ),
  ],
),

                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                  children: [

                    ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminHostelDetailsScreen(
          hostelId: hostel.id,
          hostelData: data,
        ),
      ),
    );
  },
  icon: const Icon(Icons.visibility),
  label: const Text("View"),
),

ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminEditHostelScreen(
          hostelId: hostel.id,
          hostelData: data,
        ),
      ),
    );
  },
  icon: const Icon(Icons.edit),
  label: const Text("Edit"),
),

                  
                      ElevatedButton.icon(
  onPressed: () async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Hostel"),
        content: Text(
          "Are you sure you want to delete ${data['hostelName']}? This will also delete all its floors and rooms.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final firestore = FirebaseFirestore.instance;
        final hostelRef = firestore.collection('hostels').doc(hostel.id);

        final floorsSnapshot = await hostelRef.collection('floors').get();

        final List<DocumentReference> refsToDelete = [];

        for (final floorDoc in floorsSnapshot.docs) {
          final roomsSnapshot =
              await floorDoc.reference.collection('rooms').get();

          for (final roomDoc in roomsSnapshot.docs) {
            refsToDelete.add(roomDoc.reference);
          }

          refsToDelete.add(floorDoc.reference);
        }

        refsToDelete.add(hostelRef);

        const batchLimit = 500;
        for (var i = 0; i < refsToDelete.length; i += batchLimit) {
          final chunk = refsToDelete.skip(i).take(batchLimit);
          final batch = firestore.batch();
          for (final ref in chunk) {
            batch.delete(ref);
          }
          await batch.commit();
        }

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Hostel deleted successfully"),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete hostel: $e")),
        );
      }
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
  ),
  icon: const Icon(Icons.delete),
  label: const Text("Delete"),
),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  },
),
 

      ],
    ),
  ),
),

floatingActionButton: FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminAddHostelScreen(),
      ),
    );
  },
  child: const Icon(Icons.add),
),
    );
  }

   Widget _filterChip(String text) {
  final selected = selectedFilter == text;

  return GestureDetector(
    onTap: () {
      setState(() {
        selectedFilter = text;
      });
    },
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: selected
            ? Colors.blue
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected
              ? Colors.white
              : Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

}