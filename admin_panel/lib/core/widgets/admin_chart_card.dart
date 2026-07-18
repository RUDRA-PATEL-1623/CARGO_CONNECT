import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class AdminChartEntry {
  const AdminChartEntry({required this.label, required this.value});

  final String label;
  final double value;
}

class AdminChartCard extends StatelessWidget {
  const AdminChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.entries,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final List<AdminChartEntry> entries;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: entries.isEmpty
                  ? const _ChartEmptyState()
                  : _ChartBars(entries: entries),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartBars extends StatelessWidget {
  const _ChartBars({required this.entries});

  final List<AdminChartEntry> entries;

  @override
  Widget build(BuildContext context) {
    final maxValue = entries
        .map((entry) => entry.value)
        .fold<double>(1, (max, value) => value > max ? value : max);

    return SizedBox(
      height: 210,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final entry in entries) ...[
            Expanded(
              child: _ChartBar(entry: entry, maxValue: maxValue),
            ),
            if (entry != entries.last) const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  const _ChartBar({required this.entry, required this.maxValue});

  final AdminChartEntry entry;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final heightFactor = (entry.value / maxValue).clamp(0.08, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          _formatChartValue(entry.value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0.08, end: heightFactor.toDouble()),
              builder: (context, animatedHeight, child) {
                return FractionallySizedBox(
                  heightFactor: animatedHeight,
                  child: child,
                );
              },
              child: Container(
                constraints: const BoxConstraints(minWidth: 14),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Tooltip(
          message: entry.label,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              entry.label,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bar_chart_outlined,
              color: AppColors.primaryBlue,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No chart data',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatChartValue(double value) {
  if (value >= 100 || value % 1 == 0) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}
