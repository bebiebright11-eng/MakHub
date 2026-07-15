import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/presentation/screens/personnel/personnel_login_screen.dart';
import 'features/authentication/presentation/screens/personnel/activate_account_screen.dart';
import 'features/authentication/presentation/screens/personnel/3_dashboard_screen.dart';

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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/activate-account': (context) => const ActivateAccountScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
