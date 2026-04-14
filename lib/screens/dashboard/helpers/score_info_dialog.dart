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
                    'Your daily score starts at 5 out of 10. It then moves up or down based on how close the full day was to target, how complete the logging looks, which meal tags showed up, and whether meals left you too full.',
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
                      '10% to 25% below target: -1',
                      '25% to 50% below target: -2',
                      'More than 50% below target: -3',
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _ScoreInfoSection(
                    title: 'Logging completeness',
                    items: [
                      'Only 1 meal logged in the day: -1',
                      'A very low total day is treated as incomplete, even if the meal quality was good',
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _ScoreInfoSection(
                    title: 'Healthier choice tags',
                    items: [
                      'At least 1 high protein meal: +1',
                      'At least 1 balanced meal: +1',
                      'At least 2 fruit and veg tags in the day: +1',
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _ScoreInfoSection(
                    title: 'Things to limit',
                    items: [
                      'Any High Sugar tag in the day: -1',
                      'Any Fried tag in the day: -1',
                      'Any Highly Processed tag in the day: -1',
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _ScoreInfoSection(
                    title: 'After the meal',
                    items: [
                      'Any Too Full selection in the day: -2',
                      'Satisfied and Still Hungry are tracked, but do not change the score in this version',
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
                      'The score is meant to reflect the whole day, not just whether one meal looked healthy. If no meals are logged, the score is set to 0 and the category is Very bad.',
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
  const _ScoreInfoSection({required this.title, required this.items});

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
