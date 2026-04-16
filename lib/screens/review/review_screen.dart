import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/models/daily_summary.dart';
import 'package:lean_streak/providers/review_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  _ReviewMode _mode = _ReviewMode.month;
  late DateTime _focusedDate;

  @override
  void initState() {
    super.initState();
    _focusedDate = _dateOnly(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final periodsAsync = ref.watch(reviewPeriodsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Review')),
      body: periodsAsync.when(
        data: (periods) {
          final activePeriods = _mode == _ReviewMode.month
              ? periods.monthStarts
              : periods.weekStarts;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(reviewPeriodsProvider);
              await ref.read(reviewPeriodsProvider.future);
            },
            child: activePeriods.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      MediaQuery.of(context).padding.bottom + 28,
                    ),
                    children: const [
                      _ReviewHeader(),
                      SizedBox(height: 20),
                      _ReviewEmptyState(),
                    ],
                  )
                : _ReviewContent(
                    mode: _mode,
                    focusedDate: _resolvedFocusedDate(
                      _focusedDate,
                      activePeriods,
                      _mode,
                    ),
                    activePeriods: activePeriods,
                    onModeChanged: (mode) {
                      setState(() {
                        _mode = mode;
                      });
                    },
                    onFocusedDateChanged: (date) {
                      setState(() {
                        _focusedDate = date;
                      });
                    },
                  ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => const _ReviewErrorState(),
      ),
    );
  }
}

class _ReviewContent extends ConsumerWidget {
  const _ReviewContent({
    required this.mode,
    required this.focusedDate,
    required this.activePeriods,
    required this.onModeChanged,
    required this.onFocusedDateChanged,
  });

  final _ReviewMode mode;
  final DateTime focusedDate;
  final List<DateTime> activePeriods;
  final ValueChanged<_ReviewMode> onModeChanged;
  final ValueChanged<DateTime> onFocusedDateChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _periodIndexOf(activePeriods, focusedDate);
    final range = mode == _ReviewMode.month
        ? ReviewRange(
            startDate: _firstDayOfMonth(focusedDate),
            endDate: _lastDayOfMonth(focusedDate),
          )
        : ReviewRange(
            startDate: _startOfWeek(focusedDate),
            endDate: _endOfWeek(focusedDate),
          );
    final summariesAsync = ref.watch(reviewSummariesProvider(range));
    final currentPeriod = mode == _ReviewMode.month
        ? _firstDayOfMonth(_dateOnly(DateTime.now()))
        : _startOfWeek(_dateOnly(DateTime.now()));
    final currentPeriodIndex = _periodIndexOf(activePeriods, currentPeriod);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).padding.bottom + 28,
      ),
      children: [
        const _ReviewHeader(),
        const SizedBox(height: 20),
        _ReviewModeSelector(mode: mode, onModeChanged: onModeChanged),
        const SizedBox(height: 16),
        _ReviewPeriodBar(
          label: _periodLabel(focusedDate, mode),
          canGoBack: currentIndex > 0,
          canGoForward:
              currentIndex >= 0 && currentIndex < activePeriods.length - 1,
          showTodayButton: currentPeriodIndex != -1,
          isCurrentPeriod: currentPeriodIndex == currentIndex,
          onPrevious: currentIndex > 0
              ? () => onFocusedDateChanged(activePeriods[currentIndex - 1])
              : null,
          onNext: currentIndex >= 0 && currentIndex < activePeriods.length - 1
              ? () => onFocusedDateChanged(activePeriods[currentIndex + 1])
              : null,
          onToday: currentPeriodIndex == -1
              ? null
              : () => onFocusedDateChanged(activePeriods[currentPeriodIndex]),
        ),
        const SizedBox(height: 12),
        const _ReviewLegend(),
        const SizedBox(height: 20),
        summariesAsync.when(
          data: (summariesByDate) {
            return mode == _ReviewMode.month
                ? _MonthCalendar(
                    month: focusedDate,
                    summariesByDate: summariesByDate,
                  )
                : _WeekCalendar(
                    weekDate: focusedDate,
                    summariesByDate: summariesByDate,
                  );
          },
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (_, _) => const _ReviewErrorState(),
        ),
      ],
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Week and month view',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Each day shows whether calories landed on track, close, or off track.',
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

class _ReviewModeSelector extends StatelessWidget {
  const _ReviewModeSelector({required this.mode, required this.onModeChanged});

  final _ReviewMode mode;
  final ValueChanged<_ReviewMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_ReviewMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: _ReviewMode.week, label: Text('Week')),
        ButtonSegment(value: _ReviewMode.month, label: Text('Month')),
      ],
      selected: {mode},
      onSelectionChanged: (selection) => onModeChanged(selection.first),
    );
  }
}

class _ReviewPeriodBar extends StatelessWidget {
  const _ReviewPeriodBar({
    required this.label,
    required this.canGoBack,
    required this.canGoForward,
    required this.showTodayButton,
    required this.isCurrentPeriod,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final String label;
  final bool canGoBack;
  final bool canGoForward;
  final bool showTodayButton;
  final bool isCurrentPeriod;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToday;

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
          if (showTodayButton)
            OutlinedButton(
              onPressed: isCurrentPeriod ? null : onToday,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.divider),
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Today'),
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

class _ReviewLegend extends StatelessWidget {
  const _ReviewLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: const [
        _LegendChip(label: 'Green', color: AppColors.veryGood),
        _LegendChip(label: 'Yellow', color: AppColors.bad),
        _LegendChip(label: 'Red', color: AppColors.veryBad),
        _LegendChip(label: 'No data', color: AppColors.textSecondary),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekCalendar extends StatelessWidget {
  const _WeekCalendar({required this.weekDate, required this.summariesByDate});

  final DateTime weekDate;
  final Map<String, DailySummary> summariesByDate;

  @override
  Widget build(BuildContext context) {
    final start = _startOfWeek(weekDate);
    final days = List.generate(7, (index) => start.add(Duration(days: index)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This week',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _WeekdayHeader(days: days, compact: false),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final date = days[index];
            final summary = summariesByDate[_dateKey(date)];
            return _ReviewDayCell(date: date, summary: summary);
          },
        ),
      ],
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({required this.month, required this.summariesByDate});

  final DateTime month;
  final Map<String, DailySummary> summariesByDate;

  @override
  Widget build(BuildContext context) {
    final firstDay = _firstDayOfMonth(month);
    final lastDay = _lastDayOfMonth(month);
    final leadingEmptyCount = firstDay.weekday - 1;
    final totalDays = lastDay.day;
    final totalSlots = leadingEmptyCount + totalDays;
    final trailingEmptyCount = (7 - (totalSlots % 7)) % 7;

    final cells = <DateTime?>[
      ...List<DateTime?>.filled(leadingEmptyCount, null),
      ...List.generate(
        totalDays,
        (index) => DateTime(month.year, month.month, index + 1),
      ),
      ...List<DateTime?>.filled(trailingEmptyCount, null),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This month',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        const _WeekdayHeader(),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final date = cells[index];
            if (date == null) return const SizedBox.shrink();
            return _ReviewDayCell(
              date: date,
              summary: summariesByDate[_dateKey(date)],
            );
          },
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({this.days, this.compact = true});

  final List<DateTime>? days;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final labels = days == null
        ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        : days!
              .map((day) => DateFormat(compact ? 'E' : 'EEE').format(day))
              .toList();

    return Row(
      children: labels.map((label) {
        return Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ReviewDayCell extends StatelessWidget {
  const _ReviewDayCell({required this.date, required this.summary});

  final DateTime date;
  final DailySummary? summary;

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final isToday = _sameDay(date, today);
    final statusColor = summary == null
        ? AppColors.textSecondary
        : _statusColor(summary!.status);
    final backgroundColor = summary == null
        ? AppColors.surface
        : statusColor.withValues(alpha: 0.14);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: summary == null ? null : () => _showReviewDaySheet(context, summary!),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isToday ? AppColors.primary : AppColors.divider,
              width: isToday ? 1.5 : 1,
            ),
            boxShadow: isToday
                ? const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isToday ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isToday ? AppColors.surface : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              if (summary != null)
                Center(
                  child: Icon(
                    _statusIcon(summary!.status),
                    size: 18,
                    color: statusColor,
                  ),
                ),
              if (summary != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Text(
                    '${summary!.totalCalories}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewEmptyState extends StatelessWidget {
  const _ReviewEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.calendar_month_rounded,
            size: 46,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'No review data yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Review will fill in once you log meals on at least one day.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewErrorState extends StatelessWidget {
  const _ReviewErrorState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Could not load review data right now.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
      ),
    );
  }
}

void _showReviewDaySheet(BuildContext context, DailySummary summary) {
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
                      value: _deltaLabel(summary.calorieDelta),
                      valueColor: _deltaColor(summary.calorieDelta),
                    ),
                    _DetailMetricCard(
                      label: 'Meals',
                      value: '${summary.mealCount}',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  _statusDescription(summary),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (summary.tagCounts.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Tag totals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                          style: const TextStyle(
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

enum _ReviewMode { week, month }

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _firstDayOfMonth(DateTime date) => DateTime(date.year, date.month, 1);

DateTime _lastDayOfMonth(DateTime date) =>
    DateTime(date.year, date.month + 1, 0);

DateTime _startOfWeek(DateTime date) {
  final normalized = _dateOnly(date);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

DateTime _endOfWeek(DateTime date) =>
    _startOfWeek(date).add(const Duration(days: 6));

DateTime _resolvedFocusedDate(
  DateTime focusedDate,
  List<DateTime> activePeriods,
  _ReviewMode mode,
) {
  if (activePeriods.isEmpty) return focusedDate;

  final normalizedFocused = mode == _ReviewMode.month
      ? _firstDayOfMonth(focusedDate)
      : _startOfWeek(focusedDate);
  final currentIndex = _periodIndexOf(activePeriods, normalizedFocused);
  if (currentIndex != -1) {
    return activePeriods[currentIndex];
  }

  return activePeriods.last;
}

int _periodIndexOf(List<DateTime> periods, DateTime target) {
  for (var index = 0; index < periods.length; index++) {
    if (_sameDay(periods[index], target)) {
      return index;
    }
  }

  return -1;
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _periodLabel(DateTime focusedDate, _ReviewMode mode) {
  if (mode == _ReviewMode.month) {
    return DateFormat('MMMM yyyy').format(focusedDate);
  }

  final start = _startOfWeek(focusedDate);
  final end = _endOfWeek(focusedDate);
  if (start.month == end.month) {
    return '${DateFormat('d').format(start)} - ${DateFormat('d MMM yyyy').format(end)}';
  }

  return '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM yyyy').format(end)}';
}

String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

Color _statusColor(DailyStatus status) {
  return switch (status) {
    DailyStatus.green => AppColors.veryGood,
    DailyStatus.yellow => AppColors.bad,
    DailyStatus.red => AppColors.veryBad,
  };
}

IconData _statusIcon(DailyStatus status) {
  return switch (status) {
    DailyStatus.green => Icons.check_circle_rounded,
    DailyStatus.yellow => Icons.remove_circle_outline_rounded,
    DailyStatus.red => Icons.warning_amber_rounded,
  };
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
