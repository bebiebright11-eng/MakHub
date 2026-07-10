import 'package:flutter/material.dart';

class StudentRegisterScreen extends StatefulWidget {
  const StudentRegisterScreen({super.key});

  @override
  State<StudentRegisterScreen> createState() => _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends State<StudentRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    // Later we will connect this to Firebase
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Account Created!"),
        content: Text("Welcome, ${_nameController.text}"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), backgroundColor: const Color(0xFF2563EB)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTextField(controller: _nameController, label: 'Full Name', hint: 'John Doe', icon: Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField(controller: _emailController, label: 'Email Address', hint: 'student@makhub.edu', icon: Icons.email_outlined),
            const SizedBox(height: 16),
            _buildTextField(controller: _passwordController, label: 'Password', hint: 'Create a password', icon: Icons.lock_outline, isPassword: true),
            const SizedBox(height: 24),
            _buildButton(text: 'Register', onPressed: _handleRegister),
          ],
        ),
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
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}