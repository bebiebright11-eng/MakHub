import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // Get current logged-in user's UID
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

  // Map notification types to corresponding icons and color themes
  Map<String, dynamic> _getStyleForType(String? type) {
    switch (type) {
      case 'booking':
        return {
          'icon': Icons.calendar_today,
          'bgColor': const Color(0xFFDBEAFE),
          'iconColor': AppColors.primary,
        };
      case 'payment':
        return {
          'icon': Icons.receipt_long,
          'bgColor': const Color(0xFFFED7AA),
          'iconColor': AppColors.accent,
        };
      case 'student':
        return {
          'icon': Icons.group,
          'bgColor': const Color(0xFFCFFAFE),
          'iconColor': const Color(0xFF06B6D4),
        };
      case 'room':
        return {
          'icon': Icons.bed,
          'bgColor': const Color(0xFFD1FAE5),
          'iconColor': const Color(0xFF10B981),
        };
      default:
        return {
          'icon': Icons.notifications,
          'bgColor': Colors.grey.shade200,
          'iconColor': Colors.grey.shade700,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please log in to view notifications.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('Mark all as read'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Listen to live stream from Firestore ordered by timestamp
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
            return Center(child: Text('Error loading notifications: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('No notifications yet', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String title = data['title'] ?? '';
              final String subtitle = data['subtitle'] ?? '';
              final Timestamp? timestamp = data['createdAt'] as Timestamp?;
              final String type = data['type'] ?? 'default';
              final bool isRead = data['isRead'] ?? false;

              final style = _getStyleForType(type);

              return GestureDetector(
                onTap: () => _markAsRead(doc.id),
                child: _notificationItem(
                  title: title,
                  subtitle: subtitle,
                  time: _formatTimestamp(timestamp),
                  icon: style['icon'],
                  bgColor: style['bgColor'],
                  iconColor: style['iconColor'],
                  isRead: isRead,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _notificationItem({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required bool isRead,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFF0FDF4), // Subtle highlight for unread
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.bold : FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(time, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

