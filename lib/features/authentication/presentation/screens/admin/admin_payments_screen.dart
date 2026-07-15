import 'package:flutter/material.dart';
import 'admin_payment_details_screen.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  String _selectedFilter = "All";

  final List<Map<String, String>> _payments = [
    {
      "name": "Ama K.",
      "hostelRoom": "Sunrise Residence • Room 204",
      "amount": "GHS 2,500",
      "date": "12 Jul 2026",
      "reference": "INV-204",
      "status": "Completed",
      "note": "Payment cleared successfully",
    },
    {
      "name": "Kwesi M.",
      "hostelRoom": "Sunrise Residence • Room 101",
      "amount": "GHS 1,800",
      "date": "15 Jul 2026",
      "reference": "INV-101",
      "status": "Pending",
      "note": "Awaiting confirmation from finance",
    },
    {
      "name": "Esi A.",
      "hostelRoom": "Sunrise Residence • Room 306",
      "amount": "GHS 3,200",
      "date": "08 Jul 2026",
      "reference": "INV-306",
      "status": "Overdue",
      "note": "Payment overdue by 4 days",
    },
    {
      "name": "Name B.",
      "hostelRoom": "Sunrise Residence • Room 112",
      "amount": "GHS 2,100",
      "date": "05 Jul 2026",
      "reference": "INV-112",
      "status": "Completed",
      "note": "Receipt issued and archived",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payments"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Track collected revenue, pending balances, and overdue student payments.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _statCard("GHS 48.2K", "Total\nPayments", Colors.blue),
                const SizedBox(width: 10),
                _statCard("GHS 6.4K", "Pending\nClearance", Colors.orange),
                const SizedBox(width: 10),
                _statCard("128", "Payment\nRecords", Colors.green),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              decoration: InputDecoration(
                hintText: "Search payments...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip("All"),
                  const SizedBox(width: 8),
                  _filterChip("Pending"),
                  const SizedBox(width: 8),
                  _filterChip("Completed"),
                  const SizedBox(width: 8),
                  _filterChip("Overdue"),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: _payments.length,
                itemBuilder: (context, index) {
                  final p = _payments[index];
                  return _paymentCard(
                    context: context,
                    name: p["name"]!,
                    hostelRoom: p["hostelRoom"]!,
                    amount: p["amount"]!,
                    date: p["date"]!,
                    reference: p["reference"]!,
                    status: p["status"]!,
                    note: p["note"]!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final selected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _paymentCard({
    required BuildContext context,
    required String name,
    required String hostelRoom,
    required String amount,
    required String date,
    required String reference,
    required String status,
    required String note,
  }) {
    Color statusColor;
    if (status == "Completed") {
      statusColor = Colors.green;
    } else if (status == "Pending") {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(hostelRoom, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text("Ref: $reference", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(note, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminPaymentDetailsScreen(
                      studentName: name,
                      hostelRoom: hostelRoom,
                      amount: amount,
                      status: status,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("View Details"),
            ),
          ),
        ],
      ),
    );
  }
}