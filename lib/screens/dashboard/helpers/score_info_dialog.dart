import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';

Future<void> showScoreInfoDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'How scoring works',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your daily score starts at 5 out of 10. Points are then added or removed based on calories and meal tags.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _ScoreInfoSection(
                    title: 'Calories',
                    items: [
                      'Within 5% of target: +2',
                      'Within 10% of target: +1',
                      '10% to 20% above target: -1',
                      'More than 20% above target: -2',
                      'More than 25% below target: -1',
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _ScoreInfoSection(
                    title: 'Positive meal tags',
                    items: [
                      'At least 1 high protein meal: +1',
                      'At least 1 balanced meal: +1',
                      'At least 2 fruit and veg tags in the day: +1',
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _ScoreInfoSection(
                    title: 'Warning tags',
                    items: [
                      'Any overate tag: -2',
                      '2 or more processed tags: -1',
                      '2 or more sugary tags: -1',
                      'Alcohol and overate on the same day: extra -1',
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _ScoreInfoSection(
                    title: 'Category mapping',
                    items: [
                      '8 to 10: Very good',
                      '6 to 7: Good',
                      '3 to 5: Bad',
                      '0 to 2: Very bad',
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'If no meals are logged, the score is set to 0 and the category is Very bad. The explanation tells you exactly what affected your result.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ScoreInfoSection extends StatelessWidget {
  const _ScoreInfoSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(
                    Icons.circle,
                    size: 6,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
