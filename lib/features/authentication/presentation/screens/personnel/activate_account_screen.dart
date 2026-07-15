// ignore_for_file: file_names, deprecated_member_use
import 'package:flutter/material.dart';
import '3_dashboard_screen.dart';

class ActivateAccountScreen extends StatefulWidget {
  const ActivateAccountScreen({super.key});

  @override
  State<ActivateAccountScreen> createState() => _ActivateAccountScreenState();
}

class _ActivateAccountScreenState extends State<ActivateAccountScreen> {
  final _tempPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscureTemp = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  double _passwordStrength = 0.0;
  String _strengthText = '';

  void _checkStrength(String password) {
    if (password.isEmpty) {
      _passwordStrength = 0.0;
      _strengthText = '';
    } else if (password.length < 8) {
      _passwordStrength = 0.3;
      _strengthText = 'Weak';
    } else if (password.length < 12 || !RegExp(r'(?=.*[0-9])(?=.*[a-zA-Z])').hasMatch(password)) {
      _passwordStrength = 0.6;
      _strengthText = 'Medium';
    } else {
      _passwordStrength = 1.0;
      _strengthText = 'Strong';
    }
    setState(() {});
  }

  void _activateAccount() {
    if (_newPassController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_passwordStrength < 0.6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password is too weak'), backgroundColor: Colors.red),
      );
      return;
    }
    // TODO: Call API to activate
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  void dispose() {
    _tempPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // HEADER
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.lock, color: Color(0xFF2563EB), size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Activate Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text(
                          'Set a secure password for your first login to continue to the hostel personnel dashboard.',
                          style: TextStyle(color: Colors.grey, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // TEMP PASSWORD
              _passwordField(
                label: 'Temporary Password',
                controller: _tempPassController,
                obscure: _obscureTemp,
                toggle: () => setState(() => _obscureTemp = !_obscureTemp),
              ),
              const SizedBox(height: 16),

              // NEW PASSWORD + STRENGTH
              _passwordFieldWithStrength(
                label: 'New Password',
                controller: _newPassController,
                obscure: _obscureNew,
                toggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 16),

              // CONFIRM PASSWORD
              _passwordField(
                label: 'Confirm Password',
                controller: _confirmPassController,
                obscure: _obscureConfirm,
                toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 24),

              // SECURITY TIP CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDBA74),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Color(0xFF9A3412), size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Security tip', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9A3412), fontSize: 15)),
                          SizedBox(height: 4),
                          Text(
                            'Choose a password you can remember, but avoid using your temporary password again.',
                            style: TextStyle(color: Color(0xFF9A3412)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // BUTTON
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _activateAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 4,
                    shadowColor: const Color(0xFF2563EB).withOpacity(0.4),
                  ),
                  child: const Text('Activate Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF7F9FC), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                TextField(
                  controller: controller,
                  obscureText: obscure,
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  onChanged: label == 'New Password' ? _checkStrength : null,
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFF7F9FC),
            child: IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18), onPressed: toggle),
          )
        ],
      ),
    );
  }

  Widget _passwordFieldWithStrength({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF7F9FC), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    TextField(
                      controller: controller,
                      obscureText: obscure,
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      onChanged: _checkStrength,
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF7F9FC),
                child: IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18), onPressed: toggle),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _passwordStrength,
                    backgroundColor: Colors.grey.shade200,
                    color: const Color(0xFF2563EB),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(_strengthText, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Use at least 8 characters with a mix of letters, numbers, and symbols.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}