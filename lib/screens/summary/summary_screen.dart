import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/models/check_in.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/models/period_review.dart';
import 'package:lean_streak/providers/period_review_provider.dart';
import 'package:lean_streak/providers/review_provider.dart';
import 'package:lean_streak/widgets/app_frame.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  _SummaryMode _mode = _SummaryMode.week;
  DateTime? _selectedPeriodStart;

  @override
  Widget build(BuildContext context) {
    final periodsAsync = ref.watch(reviewPeriodsProvider);

    return AppFrame(
      title: 'Summary',
      currentTab: AppFrameTab.summary,
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
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).padding.bottom + 28,
              ),
              children: [
                const _SummaryHeader(),
                SizedBox(height: 20),
                _SummaryModeSelector(
                  mode: _mode,
                  onModeChanged: (mode) {
                    setState(() {
                      _mode = mode;
                      _selectedPeriodStart = null;
                    });
                  },
                ),
                SizedBox(height: 16),
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
                SizedBox(height: 20),
                reviewAsync.when(
                  data: (review) =>
                      _PeriodSummaryContent(review: review, mode: _mode),
                  loading: () => Padding(
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
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, _) => const _SummaryErrorState(),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
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
      segments: [
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
            icon: Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: onLatest,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.divider),
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Latest'),
          ),
          IconButton(
            onPressed: canGoForward ? onNext : null,
            icon: Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _PeriodSummaryContent extends StatelessWidget {
  const _PeriodSummaryContent({required this.review, required this.mode});

  final PeriodReview review;
  final _SummaryMode mode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroSummaryCard(review: review, mode: mode),
        SizedBox(height: 16),
        _MetricGrid(review: review),
        SizedBox(height: 16),
        if (mode == _SummaryMode.month) ...[
          _MonthlySnapshotCard(review: review),
          SizedBox(height: 16),
        ],
        _StatusCountsCard(review: review),
        SizedBox(height: 16),
        _DayHighlightsCard(review: review),
        SizedBox(height: 16),
        _TagsCard(
          title: 'Top healthy tags',
          tags: review.topHelpfulTags,
          emptyLabel: 'No healthy tags were saved in this period.',
          chipColor: AppColors.tagPositive,
          chipBackground: AppColors.tagPositiveBg,
        ),
        SizedBox(height: 16),
        _TagsCard(
          title: 'Top unhealthy tags',
          tags: review.topRiskyTags,
          emptyLabel: 'No unhealthy tags were saved in this period.',
          chipColor: AppColors.tagWarning,
          chipBackground: AppColors.tagWarningBg,
        ),
        SizedBox(height: 16),
        _GuidanceCard(guidance: review.guidance),
        SizedBox(height: 16),
        if (mode == _SummaryMode.month) ...[
          _MonthlyCheckInCard(checkIns: review.checkIns),
          SizedBox(height: 16),
        ],
        _LoggedDaysCard(review: review),
      ],
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({required this.review, required this.mode});

  final PeriodReview review;
  final _SummaryMode mode;

  @override
  Widget build(BuildContext context) {
    final consistencyPercent = (review.calorieConsistencyRate * 100).round();
    final color = _consistencyColor(review.calorieConsistencyRate);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
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
                  style: TextStyle(
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
                  _consistencyLabel(review.calorieConsistencyRate),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            '$consistencyPercent%',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            mode == _SummaryMode.month
                ? 'On-track day rate for this completed month'
                : 'On-track day rate for this completed week',
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
          label: 'Avg per logged day',
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
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
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

class _MonthlySnapshotCard extends StatelessWidget {
  const _MonthlySnapshotCard({required this.review});

  final PeriodReview review;

  @override
  Widget build(BuildContext context) {
    final consistencyPercent = (review.calorieConsistencyRate * 100).round();

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
            'Monthly snapshot',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${review.greenDays} days were on track out of ${review.loggedDays} logged days.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'On-track days',
                  value: '${review.greenDays}',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: 'Consistency',
                  value: '$consistencyPercent%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusCountsCard extends StatelessWidget {
  const _StatusCountsCard({required this.review});

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
          Text(
            'Day status counts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatusCountChip(
                label: 'Green',
                count: review.greenDays,
                color: AppColors.veryGood,
              ),
              _StatusCountChip(
                label: 'Yellow',
                count: review.yellowDays,
                color: AppColors.bad,
              ),
              _StatusCountChip(
                label: 'Red',
                count: review.redDays,
                color: AppColors.veryBad,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusCountChip extends StatelessWidget {
  const _StatusCountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
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
          Text(
            'Closest and furthest from target',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 14),
          if (review.bestDay == null && review.worstDay == null)
            Text(
              'No saved days in this period.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _DayHighlightTile(
                    title: 'Closest day',
                    summary: review.bestDay,
                    accentColor: AppColors.veryGood,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _DayHighlightTile(
                    title: 'Furthest day',
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
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      );
    }

    final date = DateTime.parse(summary!.date);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSummaryDaySheet(context, summary!),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.10),
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
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                DateFormat('EEE, d MMM').format(date),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '${summary!.totalCalories}/${summary!.targetCalories} kcal',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              SizedBox(height: 4),
              Text(
                'Delta ${_deltaLabel(summary!.calorieDelta)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _deltaColor(summary!.calorieDelta),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 14),
          if (tags.isEmpty)
            Text(
              emptyLabel,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
          Text(
            'Guidance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 14),
          ...guidance.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
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

class _MonthlyCheckInCard extends StatelessWidget {
  const _MonthlyCheckInCard({required this.checkIns});

  final List<CheckIn> checkIns;

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
            'Check-ins',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 14),
          if (checkIns.isEmpty)
            Text(
              'No check-ins were saved in this month.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            )
          else
            ...checkIns.map((checkIn) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('d MMM').format(checkIn.periodEnd),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        checkIn.recommendation.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _CheckInChip(
                            label: 'Weight: ${checkIn.weightTrend.label}',
                          ),
                          _CheckInChip(
                            label: 'Target: ${checkIn.targetDifficulty.label}',
                          ),
                          _CheckInChip(
                            label: 'Hunger: ${checkIn.hunger.label}',
                          ),
                          _CheckInChip(label: 'Fit: ${checkIn.planFit.label}'),
                        ],
                      ),
                      if (checkIn.recommendationReason case final reason?) ...[
                        SizedBox(height: 10),
                        Text(
                          reason,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _CheckInChip extends StatelessWidget {
  const _CheckInChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
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
          Text(
            'Logged days',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 14),
          if (review.summaries.isEmpty)
            Text(
              'No daily summaries were saved for this period.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            )
          else
            ...review.summaries.map((summary) {
              final date = DateTime.parse(summary.date);
              final statusColor = _statusColor(summary.status);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showSummaryDaySheet(context, summary),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEE, d MMM').format(date),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${summary.totalCalories}/${summary.targetCalories} kcal',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              summary.status.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
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
          child: Column(
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
    return Center(
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

void _showSummaryDaySheet(BuildContext context, DailySummary summary) {
  final date = DateTime.tryParse(summary.date);
  final statusColor = _statusColor(summary.status);

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (context) {
      return SafeArea(
        top: false,
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
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    summary.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SummaryDetailMetricCard(
                      label: 'Calories',
                      value: '${summary.totalCalories}',
                    ),
                    _SummaryDetailMetricCard(
                      label: 'Target',
                      value: '${summary.targetCalories}',
                    ),
                    _SummaryDetailMetricCard(
                      label: 'Delta',
                      value: _deltaLabel(summary.calorieDelta),
                      valueColor: _deltaColor(summary.calorieDelta),
                    ),
                    _SummaryDetailMetricCard(
                      label: 'Meals',
                      value: '${summary.mealCount}',
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Text(
                  _statusDescription(summary),
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (summary.tagCounts.isNotEmpty) ...[
                  SizedBox(height: 24),
                  Text(
                    'Tag totals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: summary.tagCounts.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_formatTagLabel(entry.key)} (${entry.value})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SummaryDetailMetricCard extends StatelessWidget {
  const _SummaryDetailMetricCard({
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
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          SizedBox(height: 6),
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

Color _statusColor(DailyStatus status) {
  return switch (status) {
    DailyStatus.green => AppColors.veryGood,
    DailyStatus.yellow => AppColors.bad,
    DailyStatus.red => AppColors.veryBad,
  };
}

Color _consistencyColor(double rate) {
  if (rate >= 0.7) return AppColors.veryGood;
  if (rate >= 0.4) return AppColors.bad;
  return AppColors.veryBad;
}

String _consistencyLabel(double rate) {
  if (rate >= 0.7) return 'Consistent';
  if (rate >= 0.4) return 'Mixed';
  return 'Needs work';
}

String _deltaLabel(int delta) => delta > 0 ? '+$delta' : '$delta';

Color _deltaColor(int delta) {
  if (delta > 0) return AppColors.error;
  if (delta < 0) return AppColors.primary;
  return AppColors.textPrimary;
}

String _statusDescription(DailySummary summary) {
  if (summary.status == DailyStatus.green) {
    return 'Calories landed within 10% of target for this day.';
  }
  if (summary.status == DailyStatus.yellow) {
    return summary.calorieDelta > 0
        ? 'Calories finished 10% to 20% above target.'
        : 'Calories finished 10% to 20% below target.';
  }
  return summary.calorieDelta > 0
      ? 'Calories finished more than 20% above target.'
      : 'Calories finished more than 20% below target.';
}

String _formatTagLabel(String tag) {
  return tag
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}
