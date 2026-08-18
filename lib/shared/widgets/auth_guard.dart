import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/authentication/presentation/screens/role_selection_screen.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final String? requiredRole;

  const AuthGuard({
    super.key,
    required this.child,
    this.requiredRole,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Not signed in — return to role selection.
      return const RoleSelectionScreen();
    }

    if (requiredRole == null) return child;

    return FutureBuilder<bool>(
      future: _isAuthorised(user.uid, requiredRole!),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != true) {
          return const RoleSelectionScreen();
        }
        return child;
      },
    );
  }

  /// Returns true when the signed-in [uid] is authorised for [role].
  ///
  /// Role-to-collection mapping:
  ///   'hostelPersonnel' → personnel collection, queried by firebaseUid field
  ///                       (activated == true, status != 'Inactive')
  ///   'student'         → users/{uid}  (role == 'student')
  ///   anything else     → users/{uid}  (role == requiredRole)
  ///
  /// IMPORTANT: Personnel documents are created by the admin with an
  /// auto-generated Firestore document ID.  The Firebase Auth UID is stored
  /// as the `firebaseUid` field on that document (written on first login).
  /// Therefore we MUST query by field, not by document ID.
  static Future<bool> _isAuthorised(String uid, String role) async {
    try {
      if (role == 'hostelPersonnel') {
        // Personnel documents use auto-generated Firestore IDs.
        // The Firebase Auth UID is stored in the `firebaseUid` field.
        final query = await FirebaseFirestore.instance
            .collection('personnel')
            .where('firebaseUid', isEqualTo: uid)
            .limit(1)
            .get();

        if (query.docs.isEmpty) return false;
        final data = query.docs.first.data();

        // Must be activated and not deactivated by an admin.
        if (data['activated'] != true) return false;
        if ((data['status'] ?? 'Active').toString() == 'Inactive') return false;

        return true;
      }

      // For students and all other roles, check the `users` collection.
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) return false;
      return doc.data()?['role'] == role;
    } catch (_) {
      return false;
    }
  }
}
