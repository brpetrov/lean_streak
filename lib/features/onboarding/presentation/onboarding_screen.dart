import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Placeholder — fully built in Phase 4.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Get started')),
      body: const Center(
        child: Text(
          'Onboarding — built in Phase 4',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
