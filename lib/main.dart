import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/presentation/screens/splash_screen.dart';
import 'features/authentication/presentation/screens/admin/admin_dashboard_screen.dart';

void main() {
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
      home: const AdminDashboardScreen(),
    );
  }
}