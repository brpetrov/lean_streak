import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../meals/presentation/log_meal_sheet.dart';

/// Placeholder — fully built in Phase 8.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('LeanStreak')),
      body: const Center(
        child: Text(
          'Dashboard — built in Phase 8',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showLogMealSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Log Meal',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
