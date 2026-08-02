// ignore_for_file: file_names, deprecated_member_use, dead_code
import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'activate_account_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../state/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

Future<void> _handleLogin() async {
  final email = _emailController.text.trim().toLowerCase();
  final password = _passwordController.text;

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enter both your email address and password.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  try {
    // Login with Firebase Authentication
    final credential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // Find this personnel in Firestore
    final result = await FirebaseFirestore.instance
        .collection('personnel')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (!mounted) return;

    if (result.docs.isEmpty) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Personnel account not found."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }


final doc = result.docs.first;
final data = doc.data();

// Check activation
if (data['activated'] != true) {
  await FirebaseAuth.instance.signOut();
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Please activate your account first."),
      backgroundColor: Colors.orange,
    ),
  );
  return;
}

// A roster entry must be bound to the same Firebase account that signed in.
// This prevents an account from being accepted merely because it matches a
// personnel email address.
final linkedUid = (data['firebaseUid'] ?? '').toString();
if (linkedUid.isNotEmpty && linkedUid != uid) {
  await FirebaseAuth.instance.signOut();
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('This account is not linked to the personnel record.'),
      backgroundColor: Colors.red,
    ),
  );
  return;
}

// Check account status — Inactive accounts are blocked from logging in.
final status = (data['status'] ?? 'Active').toString();
if (status == 'Inactive') {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
          "Your account has been deactivated. Please contact the administrator."),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 5),
    ),
  );
  // Sign out immediately — Firebase Auth succeeded but we must not
  // allow access to the dashboard.
  await FirebaseAuth.instance.signOut();
  return;
}

// Save Firebase UID if it hasn't been saved yet
if ((data['firebaseUid'] ?? '') == '') {
  await doc.reference.update({
    'firebaseUid': uid,
  });
}

if (!mounted) return;

// Save personnel + hostel session into AppState
AppState().setPersonnel(
  personnelId: doc.id,
  personnelName: data['fullName'] ?? '',
  personnelEmail: data['email'] ?? '',
  hostelId: data['hostelId'] ?? '',
  hostelName: data['hostelName'] ?? '',
);

// Open Hostel Personnel Dashboard
Navigator.pushReplacementNamed(context, '/dashboard');


  } on FirebaseAuthException catch (e) {
    String message = "Login failed.";

    if (e.code == 'user-not-found') {
      message = "No account found.";
    } else if (e.code == 'wrong-password') {
      message = "Incorrect password.";
    } else if (e.code == 'invalid-credential') {
      message = "Invalid email or password.";
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  } catch (_) {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not verify this personnel account. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<void> _sendPasswordReset() async {
  final email = _emailController.text.trim();
  if (email.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter your email address first.')),
    );
    return;
  }

  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset link sent. Check your email.')),
    );
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message ?? 'Could not send the reset link.')),
    );
  }
}

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 50),

                // LOGO - Blue rounded square with shadow
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ]
                  ),
                  child: const Icon(Icons.apartment, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 20),

                // TITLE
                const Text(
                  'MakHub',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hostel Personnel Module',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 40),

                // LOGIN CARD - White with rounded corners
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome back', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to manage rooms, payments, and student verification.',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                      ),
                      const SizedBox(height: 24),

                      // EMAIL FIELD
                      Container(
                        decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200)
                        ),
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Email / Username',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: Icon(Icons.mail_outline, color: Colors.grey.shade500),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // PASSWORD FIELD
                      Container(
                        decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200)
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade500),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade500),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // LOGIN BUTTON - Blue with shadow
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            shadowColor: AppColors.primary.withOpacity(0.4),
                          ),
                          child: const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const SizedBox(height: 12),

Center(
  child: TextButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ActivateAccountScreen(),
        ),
      );
    },
    child: const Text(
      'Activate Account',
      style: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  ),
),

                      // FORGOT PASSWORD - Orange
                      Center(
                        child: TextButton(
                          onPressed: _sendPasswordReset,
                          child: const Text(
                            'Forgot Password',
                            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // DOTS INDICATOR
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _dot(true),
                    const SizedBox(width: 8),
                    _dot(false),
                    const SizedBox(width: 8),
                    _dot(false),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(bool isActive) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.primary.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}

