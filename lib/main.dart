import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/presentation/screens/admin/admin_login_screen.dart';
import 'features/authentication/presentation/screens/personnel/3_dashboard_screen.dart';
import 'features/authentication/presentation/screens/student/screens/home_screen.dart';

  runApp(const MakHubApp());
}

class MakHubApp extends StatelessWidget {
  const MakHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MakHub',
      theme: AppTheme.lightTheme,
      initialRoute: '/role-selection',
      routes: {
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/login': (context) => const LoginScreen(),
        '/activate-account': (context) => const ActivateAccountScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/student-login': (context) => const StudentLoginScreen(),
        '/student-home': (context) => const StudentHomeScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
      },
    );
  }
}
