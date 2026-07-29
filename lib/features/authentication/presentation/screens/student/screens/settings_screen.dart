import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'active_booking_screen.dart';
import 'notifications_screen.dart';
import 'help_center_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';
import 'profile_screen.dart';
import 'student_login_screen.dart';

class StudentMenuScreen extends StatelessWidget {
  const StudentMenuScreen({super.key});

  // ── Navigation helpers ────────────────────────────────────────────────────

  Future<void> _goToMyBooking(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You're not logged in.")),
      );
      return;
    }

    try {
      final bookingQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('studentId', isEqualTo: user.uid)
          .orderBy('bookingDate', descending: true)
          .limit(1)
          .get();

      if (!context.mounted) return;

      if (bookingQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You don't have any bookings yet.")),
        );
        return;
      }

      final bookingDoc  = bookingQuery.docs.first;
      final bookingData = bookingDoc.data();
      final hostelId    = bookingData['hostelId'] ?? '';
      final roomId      = bookingData['roomId']   ?? '';
      final floorId     = bookingData['floorId']  ?? '';

      final hostelDoc = await FirebaseFirestore.instance
          .collection('hostels')
          .doc(hostelId)
          .get();

      if (!context.mounted) return;

      final hostelName = hostelDoc.data()?['hostelName'] ?? 'Unknown Hostel';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentActiveBookingScreen(
            bookingId:     bookingDoc.id,
            hostelName:    hostelName,
            roomNumber:    roomId,
            bookingStatus: bookingData['bookingStatus'] ?? 'Pending',
            hostelId:      hostelId,
            roomId:        roomId,
            floorId:       floorId,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong: $e")),
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Log Out",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Log Out",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
      (_) => false,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            // ── Header ───────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Icon(
                    Icons.menu,
                    size: 22,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Menu",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "App settings and account options",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Menu items ───────────────────────────────────────────────
            _menuCard(
              icon: Icons.person_outline,
              iconColor: AppColors.primary,
              iconBg: const Color(0xFFEFF6FF),
              label: "My Profile",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentProfileScreen(),
                ),
              ),
            ),
            _menuCard(
              icon: Icons.calendar_today_outlined,
              iconColor: const Color(0xFF7C3AED),
              iconBg: const Color(0xFFF5F3FF),
              label: "My Booking",
              onTap: () => _goToMyBooking(context),
            ),
            _menuCard(
              icon: Icons.notifications_outlined,
              iconColor: const Color(0xFFF59E0B),
              iconBg: const Color(0xFFFFFBEB),
              label: "Notifications",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentNotificationsScreen(),
                ),
              ),
            ),
            _menuCard(
              icon: Icons.help_outline_rounded,
              iconColor: const Color(0xFF059669),
              iconBg: const Color(0xFFECFDF5),
              label: "Help Center",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentHelpCenterScreen(),
                ),
              ),
            ),
            _menuCard(
              icon: Icons.shield_outlined,
              iconColor: AppColors.primary,
              iconBg: const Color(0xFFEFF6FF),
              label: "Privacy Policy",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentPrivacyPolicyScreen(),
                ),
              ),
            ),
            _menuCard(
              icon: Icons.description_outlined,
              iconColor: const Color(0xFF0891B2),
              iconBg: const Color(0xFFECFEFF),
              label: "Terms & Conditions",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentTermsScreen(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Logout ───────────────────────────────────────────────────
            _logoutCard(context),
          ],
        ),
      ),
    );
  }

  // ── Card builders ─────────────────────────────────────────────────────────

  Widget _menuCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Tinted icon container
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                // Label
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                // Chevron
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _logoutCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCDD2)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _confirmLogout(context),
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.red.withValues(alpha: 0.08),
          highlightColor: Colors.red.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    "Logout",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.red,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.red.shade300,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
