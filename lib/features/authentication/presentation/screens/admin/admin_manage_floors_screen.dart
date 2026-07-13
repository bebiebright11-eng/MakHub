import 'package:flutter/material.dart';

class AdminManageFloorsScreen extends StatelessWidget{
  const AdminManageFloorsScreen({super.key});

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
              onPressed: () {
                // Add floor logic goes here later
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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
          const Text(
            'Sunrise Residence',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey
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
      
            _floorCard(
              name: "Ground Floor",
              description: "Main access level and reception area",
              rooms: "30",
              available: "8",
            ),
          ],
        ),
      ),
    );
  }

  Widget _floorCard({
    required String name,
    required String description,
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
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
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
                // Navigate to Room List screen — we'll wire this later
              },
              icon: const Icon(Icons.meeting_room, size: 18),
              label: const Text("Manage Rooms"),
            ),
          ),
        ],
      ),
    );
  }
}
        