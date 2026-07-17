import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/authentication/presentation/screens/admin/admin_dashboard_screen.dart';
import '../../features/authentication/presentation/screens/admin/admin_login_screen.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const AdminLoginScreen();
    }

    return child;
  }
}