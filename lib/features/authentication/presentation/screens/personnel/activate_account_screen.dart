// ignore_for_file: file_names, deprecated_member_use
import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'package:cloud_functions/cloud_functions.dart';


class ActivateAccountScreen extends StatefulWidget {
  const ActivateAccountScreen({super.key});

  @override
  State<ActivateAccountScreen> createState() => _ActivateAccountScreenState();
}

class _ActivateAccountScreenState extends State<ActivateAccountScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();


  bool _obscureNew = true;
  bool _obscureConfirm = true;

  double _passwordStrength = 0.0;
  String _strengthText = '';
  bool _isLoading = false;

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

  Future<void> _activateAccount() async {
  final email = _emailController.text.trim().toLowerCase();
  final phone = _phoneController.text.trim();

  if (email.isEmpty || phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter your email address and phone number.'), backgroundColor: Colors.red),
    );
    return;
  }

  if (_newPassController.text != _confirmPassController.text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Passwords do not match"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (_passwordStrength < 0.6) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Password is too weak"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() => _isLoading = true);
  try {
    await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('activatePersonnelAccount')
        .call({
      'email': email,
      'phoneNumber': phone,
      'password': _newPassController.text,
    });
  } on FirebaseFunctionsException catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message ?? 'Could not activate the account.'), backgroundColor: Colors.red),
    );
    return;
  } catch (_) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not activate the account. Try again.'), backgroundColor: Colors.red),
    );
    return;
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Account activated successfully."),
      backgroundColor: Colors.green,
    ),
  );

  Navigator.pushReplacementNamed(context, '/login');
}

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
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
                    child: const Icon(Icons.lock, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Activate Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text(
                          'Verify your email and phone number, then create a password to activate your hostel personnel account.',
                          style: TextStyle(color: Colors.grey, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),


              

              
              const SizedBox(height: 16),

              _buildTextField(
  label: "Email Address",
  controller: _emailController,
  icon: Icons.email_outlined,
  hint: "Enter your email",
),

const SizedBox(height: 16),

_buildTextField(
  label: "Phone Number",
  controller: _phoneController,
  icon: Icons.phone_outlined,
  hint: "Enter your phone number",
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
    color: const Color(0xFFEFF6FF),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: const Color(0xFFBFDBFE),
    ),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(
        Icons.info_outline,
        color: AppColors.primary,
      ),

      const SizedBox(width: 12),

      Expanded(
        child: Text(
          "Your account must already have been created by the hostel administrator before you can activate it.",
          style: TextStyle(
            color: Colors.grey.shade700,
            height: 1.4,
          ),
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
                  onPressed: _isLoading ? null : _activateAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 4,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Activate Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildTextField({
  required String label,
  required TextEditingController controller,
  required IconData icon,
  required String hint,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: Colors.grey,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
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
                    color: AppColors.primary,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(_strengthText, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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

