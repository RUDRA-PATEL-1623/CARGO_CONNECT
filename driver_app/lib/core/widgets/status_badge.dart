import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

enum StatusBadgeTone {
  assigned,
  accepted,
  pickup,
  transit,
  delivered,
  completed,
  available,
  warning,
  emergency,
  neutral,
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});

  factory StatusBadge.fromTripStatus(String status, {Key? key}) {
    final normalized = status.toLowerCase();
    final tone = switch (normalized) {
      'assigned' => StatusBadgeTone.assigned,
      'new' => StatusBadgeTone.assigned,
      'accepted' => StatusBadgeTone.accepted,
      'started' => StatusBadgeTone.accepted,
      'pickup completed' => StatusBadgeTone.pickup,
      'in transit' => StatusBadgeTone.transit,
      'near delivery' => StatusBadgeTone.transit,
      'delivered' => StatusBadgeTone.delivered,
      'completed' => StatusBadgeTone.completed,
      'rejected' => StatusBadgeTone.emergency,
      _ => StatusBadgeTone.neutral,
    };
    return StatusBadge(key: key, label: status, tone: tone);
  }

  final String label;
  final StatusBadgeTone tone;

  Color get _foreground {
    return switch (tone) {
      StatusBadgeTone.assigned => AppColors.info,
      StatusBadgeTone.accepted => AppColors.primaryBlue,
      StatusBadgeTone.pickup => AppColors.warning,
      StatusBadgeTone.transit => AppColors.primaryNavy,
      StatusBadgeTone.delivered => AppColors.success,
      StatusBadgeTone.completed => AppColors.success,
      StatusBadgeTone.available => AppColors.success,
      StatusBadgeTone.warning => AppColors.warning,
      StatusBadgeTone.emergency => AppColors.danger,
      StatusBadgeTone.neutral => AppColors.neutral,
    };
  }

  @override
  Widget build(BuildContext context) {
    final foreground = _foreground;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: foreground.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
