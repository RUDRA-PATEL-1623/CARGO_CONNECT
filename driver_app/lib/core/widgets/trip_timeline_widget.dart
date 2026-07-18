import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../utils/mock_driver_data.dart';

class TripTimelineWidget extends StatelessWidget {
  const TripTimelineWidget({super.key, required this.items});

  final List<DriverTimelineMock> items;

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
                const Icon(
                  Icons.timeline_rounded,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Trip timeline',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...List.generate(items.length, (index) {
              final item = items[index];
              return _TimelineRow(
                item: item,
                isLast: index == items.length - 1,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.isLast});

  final DriverTimelineMock item;
  final bool isLast;

  Color get _color {
    return switch (item.state) {
      DriverTimelineState.completed => AppColors.success,
      DriverTimelineState.current => AppColors.primaryBlue,
      DriverTimelineState.pending => AppColors.border,
    };
  }

  IconData get _icon {
    return switch (item.state) {
      DriverTimelineState.completed => Icons.check_rounded,
      DriverTimelineState.current => Icons.local_shipping_rounded,
      DriverTimelineState.pending => Icons.circle_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: item.state == DriverTimelineState.pending ? 0.35 : 1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _icon,
                  color: item.state == DriverTimelineState.pending
                      ? AppColors.textSecondary
                      : AppColors.textInverse,
                  size: 18,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        item.time,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    item.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
