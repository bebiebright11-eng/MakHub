import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_add_personnel_screen.dart';

/// Shows the personnel assigned to a hostel.
///
/// • No personnel  → empty state + "Add Personnel" button
/// • Personnel found → info card + Edit + Deactivate/Activate actions
class AdminManagePersonnelScreen extends StatelessWidget {
  final String hostelId;
  final String hostelName;

  const AdminManagePersonnelScreen({
    super.key,
    required this.hostelId,
    required this.hostelName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Manage Personnel',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('personnel')
            .where('hostelId', isEqualTo: hostelId)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading personnel: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _EmptyState(
              hostelId: hostelId,
              hostelName: hostelName,
            );
          }

          final doc = docs.first;
          final data = doc.data() as Map<String, dynamic>;

          return _PersonnelCard(
            personnelId: doc.id,
            data: data,
            hostelId: hostelId,
            hostelName: hostelName,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String hostelId;
  final String hostelName;

  const _EmptyState({required this.hostelId, required this.hostelName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.manage_accounts_outlined,
              size: 52,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No personnel assigned to this hostel.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Create a hostel personnel account to manage this hostel.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminAddPersonnelScreen(
                    hostelId: hostelId,
                    hostelName: hostelName,
                  ),
                ),
              ),
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text(
                '+ Add Personnel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Personnel info card + actions
// ─────────────────────────────────────────────────────────────────────────────

class _PersonnelCard extends StatelessWidget {
  final String personnelId;
  final Map<String, dynamic> data;
  final String hostelId;
  final String hostelName;

  const _PersonnelCard({
    required this.personnelId,
    required this.data,
    required this.hostelId,
    required this.hostelName,
  });

  // Status field defaults to 'Active' for legacy docs that pre-date this field.
  String get _status => (data['status'] ?? 'Active').toString();
  bool get _isActive => _status == 'Active';

  Future<void> _toggleStatus(BuildContext context) async {
    final newStatus = _isActive ? 'Inactive' : 'Active';
    final actionLabel = _isActive ? 'Deactivate' : 'Activate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$actionLabel Personnel?'),
        content: Text(
          _isActive
              ? 'The personnel will no longer be able to log into MakHub.'
              : 'The personnel will be able to log into MakHub again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isActive ? Colors.red : AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseFirestore.instance
        .collection('personnel')
        .doc(personnelId)
        .update({'status': newStatus});

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Personnel ${newStatus == 'Active' ? 'activated' : 'deactivated'} successfully.'),
          backgroundColor:
              newStatus == 'Active' ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Personnel info card ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 38,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),

                // Name
                Text(
                  (data['fullName'] ?? '').toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                // Status pill
                _StatusPill(isActive: _isActive),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // Detail rows
                _infoRow(Icons.email_outlined, 'Email',
                    (data['email'] ?? '').toString()),
                const SizedBox(height: 12),
                _infoRow(Icons.phone_outlined, 'Phone',
                    (data['phoneNumber'] ?? '').toString()),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Edit ──────────────────────────────────────────────────────
          _ActionTile(
            icon: Icons.edit_outlined,
            label: 'Edit Personnel',
            iconColor: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminAddPersonnelScreen(
                  hostelId: hostelId,
                  hostelName: hostelName,
                  personnelId: personnelId,
                  existingData: data,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Deactivate / Activate ─────────────────────────────────────
          _ActionTile(
            icon:
                _isActive ? Icons.block_outlined : Icons.check_circle_outline,
            label:
                _isActive ? 'Deactivate Account' : 'Activate Account',
            iconColor: _isActive ? Colors.red : Colors.green,
            isDestructive: _isActive,
            onTap: () => _toggleStatus(context),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status pill widget
// ─────────────────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final bool isActive;
  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.red;
    final label = isActive ? 'Active' : 'Inactive';
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable action tile
// ─────────────────────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDestructive ? Colors.red : Colors.black87;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.04)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDestructive
                ? Colors.red.withValues(alpha: 0.25)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}
