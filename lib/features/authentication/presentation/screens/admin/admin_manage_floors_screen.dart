import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'admin_add_floor_screen.dart';
import 'admin_room_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AdminManageFloorsScreen extends StatefulWidget {
final String hostelId;
final String hostelName;

const AdminManageFloorsScreen({
  super.key,
  required this.hostelId,
  required this.hostelName,
});

@override
State<AdminManageFloorsScreen> createState() =>
    _AdminManageFloorsScreenState();
}

class _AdminManageFloorsScreenState
    extends State<AdminManageFloorsScreen> {

  final List<Map<String, dynamic>> floors = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      appBar: AppBar(
        title: const Text("Manage Floors"),
        centerTitle: true,
        actions:[

          Padding(
            padding : const EdgeInsets.only(right: 15),
            child : ElevatedButton.icon(
              onPressed: () async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AdminAddFloorScreen(
  hostelId: widget.hostelId,
),
    ),
  );

  if (result != null) {
  setState(() {
    floors.add({
      "name": result["floorName"],
      "description": "Rooms ${result["roomRange"]}",
      "rooms": _countRooms(result["roomRange"]).toString(),
      "available": _countRooms(result["roomRange"]).toString(),
    });
  });
}
},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                ),
              icon :const Icon(Icons.add,size:18),
              label:const Text('Add Floor') , 
              ),
            ),
          ],  
        ),
        
      
      body: Padding(
       padding:const EdgeInsets.all(16),
       child:Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Text(
  widget.hostelName,
  style: const TextStyle(
    fontSize: 13,
    color: Colors.grey,
  ),
),
          const Text(
            'Hostel management',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 20),

            
            
            Expanded(
  child: StreamBuilder<QuerySnapshot>(
    stream: _firestore
        .collection("hostels")
        .doc(widget.hostelId)
        .collection("floors")
        .snapshots(),
    builder: (context, snapshot) {

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(
          child: Text("No floors added yet."),
        );
      }

      return ListView.builder(
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {

          final floor = snapshot.data!.docs[index];

          return _floorCard(
            context: context,
            floorId: floor.id,
            name: floor["floorName"],
            description: "Rooms ${floor["roomRange"]}",
            roomRange: floor["roomRange"],
            rooms: floor["totalRooms"].toString(),
            available: floor["availableRooms"].toString(),
          );
        },
      );
    },
  ),
),
      
            
          ],
        ),
      ),
    );
  }

Future<void> _confirmAndDeleteFloor(
  BuildContext context, {
  required String floorId,
  required String floorName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete Floor?'),
      content: Text(
        'Are you sure you want to delete "$floorName"? This will also delete all its rooms and cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    final floorRef = _firestore
        .collection('hostels')
        .doc(widget.hostelId)
        .collection('floors')
        .doc(floorId);

    final roomsSnapshot = await floorRef.collection('rooms').get();

    final List<DocumentReference> refsToDelete = [
      for (final roomDoc in roomsSnapshot.docs) roomDoc.reference,
      floorRef,
    ];

    const batchLimit = 500;
    for (var i = 0; i < refsToDelete.length; i += batchLimit) {
      final chunk = refsToDelete.skip(i).take(batchLimit);
      final batch = _firestore.batch();
      for (final ref in chunk) {
        batch.delete(ref);
      }
      await batch.commit();
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$floorName" and its rooms were deleted.')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to delete floor: $e')),
    );
  }
}


int _countRooms(String range) {
  try {
    final parts = range.split('-');

    final start = int.parse(parts[0]);
    final end = int.parse(parts[1]);

    return end - start + 1;
  } catch (e) {
    return 0;
  }
}


  Widget _floorCard({
  required BuildContext context,
  required String floorId,
  required String name,
  required String description,
  required String roomRange,
  required String rooms,
  required String available,
}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Active",
                  style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rooms,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Number of Rooms",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      available,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const Text(
                      "Available Rooms",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
  onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AdminRoomListScreen(
        hostelId: widget.hostelId,
        floorId: floorId,
        hostelName: widget.hostelName,
        floorName: name,
      ),
    ),
  );
},
  icon: const Icon(Icons.meeting_room, size: 18),
  label: const Text("Manage Rooms"),
),

          ),
          const SizedBox(height: 10),

Row(
  children: [

    Expanded(
      child: OutlinedButton.icon(
        onPressed: () {
          // TODO: Edit Floor
        },
        icon: const Icon(Icons.edit),
        label: const Text("Edit Floor"),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),

    const SizedBox(width: 10),

    Expanded(
      child: OutlinedButton.icon(
        onPressed: () => _confirmAndDeleteFloor(
          context,
          floorId: floorId,
          floorName: name,
        ),
        icon: const Icon(Icons.delete),
        label: const Text("Delete"),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),

  ],
),
        ],
      ),
    );
  }
}
        