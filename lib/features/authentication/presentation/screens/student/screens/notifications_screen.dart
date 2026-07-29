import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentNotificationsScreen extends StatelessWidget {
  const StudentNotificationsScreen({super.key});

  // Current logged-in student's UID
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Mark all notifications as read in Firestore
  Future<void> _markAllAsRead() async {
    if (_currentUserId == null) return;

    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Mark a single notification as read on tap
  Future<void> _markAsRead(String docId) async {
    if (_currentUserId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  // Format dynamic relative timestamps (e.g., '2m ago', '1h ago')
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final DateTime dateTime = timestamp.toDate();
    final Duration difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  // Map notification types to corresponding icons and colors
  Map<String, dynamic> _getStyleForType(String? type) {
    switch (type) {
      case 'booking':
        return {'icon': Icons.event_available, 'color': AppColors.primary};
      case 'payment':
        return {'icon': Icons.payment, 'color': Colors.green};
      case 'room':
        return {'icon': Icons.meeting_room, 'color': Colors.purple};
      case 'reminder':
        return {'icon': Icons.calendar_today, 'color': Colors.orange};
      case 'warning':
        return {'icon': Icons.warning_amber_rounded, 'color': Colors.red};
      default:
        return {'icon': Icons.notifications, 'color': Colors.grey};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Notifications"), centerTitle: true),
        body: const Center(child: Text("Please log in to view notifications.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text("Mark All Read"),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading notifications: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No notifications yet",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String title = data['title'] ?? '';
              final String subtitle = data['subtitle'] ?? '';
              final Timestamp? timestamp = data['createdAt'] as Timestamp?;
              final bool isRead = data['isRead'] ?? false;
              final style = _getStyleForType(data['type']?.toString());

              return GestureDetector(
                onTap: () => _markAsRead(doc.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isRead
                        ? Colors.white
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            (style['color'] as Color).withValues(alpha: 0.1),
                        child: Icon(style['icon'],
                            color: style['color'], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(timestamp),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
