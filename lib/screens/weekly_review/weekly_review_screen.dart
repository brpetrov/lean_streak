import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/period_review.dart';
import 'package:lean_streak/providers/period_review_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';

class WeeklyReviewScreen extends ConsumerStatefulWidget {
  const WeeklyReviewScreen({super.key});

  @override
  ConsumerState<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends ConsumerState<WeeklyReviewScreen> {
  _SummaryMode _mode = _SummaryMode.week;
  DateTime? _selectedPeriodStart;

  @override
  Widget build(BuildContext context) {
    final periodsAsync = ref.watch(reviewPeriodsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Summary')),
      body: periodsAsync.when(
        data: (periods) {
          final completedPeriods = _mode == _SummaryMode.week
              ? _completedWeekStarts(periods.weekStarts)
              : _completedMonthStarts(periods.monthStarts);

          if (completedPeriods.isEmpty) {
            return const _SummaryEmptyState();
          }

          final focusedStart = _resolvedPeriodStart(
            _selectedPeriodStart,
            completedPeriods,
          );
          final currentIndex = completedPeriods.indexOf(focusedStart);
          final range = _mode == _SummaryMode.week
              ? PeriodReviewRange(
                  startDate: focusedStart,
                  endDate: focusedStart.add(const Duration(days: 6)),
                )
              : PeriodReviewRange(
                  startDate: focusedStart,
                  endDate: DateTime(
                    focusedStart.year,
                    focusedStart.month + 1,
                    0,
                  ),
                );
          final reviewAsync = ref.watch(periodReviewProvider(range));

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(reviewPeriodsProvider);
              ref.invalidate(periodReviewProvider(range));
              await ref.read(reviewPeriodsProvider.future);
              await ref.read(periodReviewProvider(range).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                const _SummaryHeader(),
                const SizedBox(height: 20),
                _SummaryModeSelector(
                  mode: _mode,
                  onModeChanged: (mode) {
                    setState(() {
                      _mode = mode;
                      _selectedPeriodStart = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _SummaryPeriodBar(
                  label: _periodLabel(focusedStart, _mode),
                  canGoBack: currentIndex > 0,
                  canGoForward: currentIndex < completedPeriods.length - 1,
                  onPrevious: currentIndex > 0
                      ? () => setState(() {
                          _selectedPeriodStart =
                              completedPeriods[currentIndex - 1];
                        })
                      : null,
                  onNext: currentIndex < completedPeriods.length - 1
                      ? () => setState(() {
                          _selectedPeriodStart =
                              completedPeriods[currentIndex + 1];
                        })
                      : null,
                  onLatest: currentIndex == completedPeriods.length - 1
                      ? null
                      : () => setState(() {
                          _selectedPeriodStart = completedPeriods.last;
                        }),
                ),
                const SizedBox(height: 20),
                reviewAsync.when(
                  data: (review) => _PeriodSummaryContent(review: review),
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  error: (_, _) => const _SummaryErrorState(),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => const _SummaryErrorState(),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completed period summary',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Week mode uses the last completed Monday to Sunday block. Month mode uses the last completed calendar month.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SummaryModeSelector extends StatelessWidget {
  const _SummaryModeSelector({required this.mode, required this.onModeChanged});

  final _SummaryMode mode;
  final ValueChanged<_SummaryMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_SummaryMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: _SummaryMode.week, label: Text('Week')),
        ButtonSegment(value: _SummaryMode.month, label: Text('Month')),
      ],
      selected: {mode},
      onSelectionChanged: (selection) => onModeChanged(selection.first),
    );
  }
}

class _SummaryPeriodBar extends StatelessWidget {
  const _SummaryPeriodBar({
    required this.label,
    required this.canGoBack,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
    required this.onLatest,
  });

  final String label;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onLatest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: canGoBack ? onPrevious : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: onLatest,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.divider),
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Latest'),
          ),
          IconButton(
            onPressed: canGoForward ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _PeriodSummaryContent extends StatelessWidget {
  const _PeriodSummaryContent({required this.review});

  final PeriodReview review;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroSummaryCard(review: review),
        const SizedBox(height: 16),
        _MetricGrid(review: review),
        const SizedBox(height: 16),
        _CategoryCountsCard(review: review),
        const SizedBox(height: 16),
        _DayHighlightsCard(review: review),
        const SizedBox(height: 16),
        _TagsCard(
          title: 'Top helpful tags',
          tags: review.topHelpfulTags,
          emptyLabel: 'No helpful tags were saved in this period.',
          chipColor: AppColors.tagPositive,
          chipBackground: AppColors.tagPositiveBg,
        ),
        const SizedBox(height: 16),
        _TagsCard(
          title: 'Top risky tags',
          tags: review.topRiskyTags,
          emptyLabel: 'No risky tags were saved in this period.',
          chipColor: AppColors.tagWarning,
          chipBackground: AppColors.tagWarningBg,
        ),
        const SizedBox(height: 16),
        _GuidanceCard(guidance: review.guidance),
        const SizedBox(height: 16),
        _LoggedDaysCard(review: review),
      ],
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({required this.review});

  final PeriodReview review;

  @override
  Widget build(BuildContext context) {
    final averageCategory = _categoryForAverage(review.averageScore);
    final color = _categoryColor(averageCategory);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${review.loggedDays} of ${review.daysInPeriod} days logged',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  averageCategory.label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            review.averageScore.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Average score for this completed period',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.review});

  final PeriodReview review;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MetricTile(label: 'Total calories', value: '${review.totalCalories}'),
        _MetricTile(
          label: 'Avg calories/day',
          value: review.averageCaloriesPerDay.toStringAsFixed(0),
        ),
        _MetricTile(label: 'Meals logged', value: '${review.totalMeals}'),
        _MetricTile(label: 'Logged days', value: '${review.loggedDays}'),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCountsCard extends StatelessWidget {
  const _CategoryCountsCard({required this.review});

  final PeriodReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Day categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: DailyCategory.values.map((category) {
              final count = review.categoryCounts[category] ?? 0;
              final color = _categoryColor(category);

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${category.label}: $count',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DayHighlightsCard extends StatelessWidget {
  const _DayHighlightsCard({required this.review});

  final PeriodReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Best and worst day',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          if (review.bestDay == null && review.worstDay == null)
            const Text(
              'No saved days in this period.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _DayHighlightTile(
                    title: 'Best day',
                    summary: review.bestDay,
                    accentColor: AppColors.veryGood,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DayHighlightTile(
                    title: 'Worst day',
                    summary: review.worstDay,
                    accentColor: AppColors.veryBad,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DayHighlightTile extends StatelessWidget {
  const _DayHighlightTile({
    required this.title,
    required this.summary,
    required this.accentColor,
  });

  final String title;
  final DailySummary? summary;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '$title unavailable',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      );
    }

    final date = DateTime.parse(summary!.date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showReviewDaySheet(context, summary!),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('EEE, d MMM').format(date),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${summary!.score}/${summary!.maxScore} score',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagsCard extends StatelessWidget {
  const _TagsCard({
    required this.title,
    required this.tags,
    required this.emptyLabel,
    required this.chipColor,
    required this.chipBackground,
  });

  final String title;
  final List<PeriodTagCount> tags;
  final String emptyLabel;
  final Color chipColor;
  final Color chipBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          if (tags.isEmpty)
            Text(
              emptyLabel,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: chipBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${tag.label} (${tag.count})',
                    style: TextStyle(
                      color: chipColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({required this.guidance});

  final List<String> guidance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guidance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...guidance.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
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
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LoggedDaysCard extends StatelessWidget {
  const _LoggedDaysCard({required this.review});

  final PeriodReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Logged days',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          if (review.summaries.isEmpty)
            const Text(
              'No daily summaries were saved for this period.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            )
          else
            ...review.summaries.map((summary) {
              final date = DateTime.parse(summary.date);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showReviewDaySheet(context, summary),
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('EEE, d MMM').format(date),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${summary.score}/${summary.maxScore}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _categoryColor(summary.category),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SummaryEmptyState extends StatelessWidget {
  const _SummaryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insights_rounded,
                size: 48,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 16),
              Text(
                'No completed summaries yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Weekly summaries appear after a full week has finished. Monthly summaries appear after a full month has finished.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryErrorState extends StatelessWidget {
  const _SummaryErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Could not load summary data right now.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

void _showReviewDaySheet(BuildContext context, DailySummary summary) {
  final date = DateTime.tryParse(summary.date);
  final categoryColor = _categoryColor(summary.category);
  final calorieDelta = summary.totalCalories - summary.targetCalories;

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date == null
                      ? summary.date
                      : DateFormat('EEEE, d MMMM yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${summary.category.label} - ${summary.score}/${summary.maxScore}',
                    style: TextStyle(
                      color: categoryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DetailMetricCard(
                      label: 'Calories',
                      value: '${summary.totalCalories}',
                    ),
                    _DetailMetricCard(
                      label: 'Target',
                      value: '${summary.targetCalories}',
                    ),
                    _DetailMetricCard(
                      label: 'Delta',
                      value: calorieDelta >= 0
                          ? '+$calorieDelta'
                          : '$calorieDelta',
                      valueColor: calorieDelta > 0
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                    _DetailMetricCard(
                      label: 'Meals',
                      value: '${summary.mealCount}',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'How the score was built',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                ...summary.explanation.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 7),
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
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _DetailMetricCard extends StatelessWidget {
  const _DetailMetricCard({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

enum _SummaryMode { week, month }

List<DateTime> _completedWeekStarts(List<DateTime> weekStarts) {
  final currentWeekStart = _startOfWeek(DateTime.now());
  return weekStarts.where((date) => date.isBefore(currentWeekStart)).toList();
}

List<DateTime> _completedMonthStarts(List<DateTime> monthStarts) {
  final currentMonthStart = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  return monthStarts.where((date) => date.isBefore(currentMonthStart)).toList();
}

DateTime _resolvedPeriodStart(DateTime? selected, List<DateTime> periods) {
  if (selected != null && periods.contains(selected)) {
    return selected;
  }

  return periods.last;
}

DateTime _startOfWeek(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

String _periodLabel(DateTime start, _SummaryMode mode) {
  if (mode == _SummaryMode.month) {
    return DateFormat('MMMM yyyy').format(start);
  }

  final end = start.add(const Duration(days: 6));
  if (start.month == end.month) {
    return '${DateFormat('d').format(start)} - ${DateFormat('d MMM yyyy').format(end)}';
  }

  return '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM yyyy').format(end)}';
}

DailyCategory _categoryForAverage(double score) {
  if (score >= 8) return DailyCategory.veryGood;
  if (score >= 6) return DailyCategory.good;
  if (score >= 3) return DailyCategory.bad;
  return DailyCategory.veryBad;
}

Color _categoryColor(DailyCategory category) {
  return switch (category) {
    DailyCategory.veryGood => AppColors.veryGood,
    DailyCategory.good => AppColors.good,
    DailyCategory.bad => AppColors.bad,
    DailyCategory.veryBad => AppColors.veryBad,
  };
}
