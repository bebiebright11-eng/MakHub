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
      // Return to role selection so each role can pick the right login
      return const RoleSelectionScreen();
    }

    if (requiredRole == null) return child;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data?.data()?['role'] != requiredRole) {
          return const RoleSelectionScreen();
        }
        return child;
      },
    );
  }
}
