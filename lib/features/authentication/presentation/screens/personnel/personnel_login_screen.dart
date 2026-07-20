// ignore_for_file: file_names, deprecated_member_use, dead_code
import 'package:flutter/material.dart';
import 'activate_account_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  try {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

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

    if (result.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Personnel account not found."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final doc = result.docs.first;

    // Check activation
    if (doc['activated'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please activate your account first."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Save Firebase UID if it hasn't been saved yet
    if (doc['firebaseUid'] == "") {
      await doc.reference.update({
        'firebaseUid': uid,
      });
    }

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
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
      backgroundColor: const Color(0xFFF9FAFB), // Light gray background like image
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
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
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
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            shadowColor: const Color(0xFF2563EB).withOpacity(0.4),
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
        color: Color(0xFF2563EB),
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  ),
),

                      // FORGOT PASSWORD - Orange
                      Center(
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Forgot Password',
                            style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.w600, fontSize: 14),
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
        color: isActive ? const Color(0xFF2563EB) : const Color(0xFF2563EB).withOpacity(0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}