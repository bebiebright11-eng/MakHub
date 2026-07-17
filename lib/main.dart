import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/presentation/screens/admin/admin_login_screen.dart';
import 'features/authentication/presentation/screens/personnel/3_dashboard_screen.dart';
<<<<<<< HEAD
import 'features/authentication/presentation/screens/personnel/activate_account_screen.dart';
import 'features/authentication/presentation/screens/personnel/personnel_login_screen.dart';
import 'features/authentication/presentation/screens/role_selection_screen.dart';
import 'features/authentication/presentation/screens/splash_screen.dart';
import 'features/authentication/presentation/screens/student/screens/student_login_screen.dart';
import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'features/authentication/presentation/screens/admin/admin_dashboard_screen.dart';
import 'shared/widgets/auth_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
=======
import 'features/authentication/presentation/screens/student/screens/home_screen.dart';
>>>>>>> 8697d792dc9f52cd3e6de74655bcdce2da584162

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
      home: FirebaseAuth.instance.currentUser == null
          ? const RoleSelectionScreen()
          : const AdminDashboardScreen(),
      routes: {
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/login': (context) => const LoginScreen(),
        '/activate-account': (context) => const ActivateAccountScreen(),
        '/dashboard': (context) => const AuthGuard(
              child: DashboardScreen(),
            ),
        '/student-login': (context) => const StudentLoginScreen(),
        '/student-home': (context) => const StudentHomeScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
      },
    );
  }
}
