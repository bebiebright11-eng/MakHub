import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Logo
              Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.apartment,
                  color: Colors.white,
                  size: 45,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "MakHub",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "University Hostel Booking",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 60),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Continue as",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              _roleButton(
                context,
                title: "Administrator",
                icon: Icons.admin_panel_settings,
                route: '/admin-login',
              ),

              const SizedBox(height: 20),

              _roleButton(
                context,
                title: "Student",
                icon: Icons.school,
                route: '/student-login',
              ),

              const SizedBox(height: 20),

              _roleButton(
                context,
                title: "Hostel Personnel",
                icon: Icons.business_center,
                route: '/login',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, route);
        },
        icon: Icon(icon),
        label: Text(
          title,
          style: const TextStyle(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

