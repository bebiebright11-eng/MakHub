import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'student_register_screen.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildForm(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 80, bottom: 40),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text('M', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('MakHub', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text('Hostel Management System', style: TextStyle(fontSize: 13, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome Back', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Sign in to your student account', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          _buildTextField(controller: _emailController, label: 'Email Address', hint: 'student@makhub.edu', icon: Icons.email_outlined),
          const SizedBox(height: 16),
          _buildTextField(controller: _passwordController, label: 'Password', hint: 'Enter your password', icon: Icons.lock_outline, isPassword: true),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () {}, child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primary))),
          ),
          const SizedBox(height: 8),
          _buildButton(text: 'Login', onPressed: () {}),
          const SizedBox(height: 12),
          _buildOutlinedButton(
            text: 'Create Account',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegisterScreen())),
          ),
          const SizedBox(height: 32),
          const Center(child: Text('MakHub Student v1.0 - Secure Login', style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, required IconData icon, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildOutlinedButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
