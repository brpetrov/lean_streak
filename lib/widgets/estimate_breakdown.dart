import 'package:flutter/material.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';

/// How the AI arrived at its number: one muted line of components, which
/// opens into rows with protein when tapped.
class EstimateBreakdown extends StatefulWidget {
  const EstimateBreakdown({super.key, required this.items});

  final List<EstimateItem> items;

  @override
  State<EstimateBreakdown> createState() => _EstimateBreakdownState();
}

class _EstimateBreakdownState extends State<EstimateBreakdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final muted = TextStyle(fontSize: 13, color: AppColors.textSecondary);

    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: _expanded
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in widget.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.name, style: muted)),
                          Text(
                            item.protein == null
                                ? '${item.kcal} kcal'
                                : '${item.kcal} kcal · ${item.protein} g',
                            style: muted,
                          ),
                        ],
                      ),
                    ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.items
                          .map((item) => '${item.name} ${item.kcal}')
                          .join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
      ),
    );
  }
}
