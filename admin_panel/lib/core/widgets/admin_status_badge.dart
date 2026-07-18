import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

enum AdminStatusTone { primary, success, warning, danger, info, neutral }

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({
    super.key,
    required this.label,
    this.tone = AdminStatusTone.neutral,
  });

  factory AdminStatusBadge.fromStatus(String status, {Key? key}) {
    final normalized = status.toLowerCase();
    final tone = switch (normalized) {
      'completed' ||
      'delivered' ||
      'paid' ||
      'active' ||
      'approved' ||
      'available' ||
      'valid' ||
      'issued' ||
      'resolved' => AdminStatusTone.success,
      'in transit' ||
      'assigned' ||
      'accepted' ||
      'processing' ||
      'busy' ||
      'on trip' => AdminStatusTone.primary,
      'pending' ||
      'pending review' ||
      'on leave' ||
      'expires soon' ||
      'maintenance' ||
      'service due' ||
      'draft' ||
      'medium' => AdminStatusTone.warning,
      'cancelled' ||
      'rejected' ||
      'failed' ||
      'blocked' ||
      'out of service' ||
      'suspended' ||
      'expired' ||
      'voided' ||
      'high' => AdminStatusTone.danger,
      'inactive' || 'offline' => AdminStatusTone.neutral,
      'refunded' || 'low' => AdminStatusTone.info,
      _ => AdminStatusTone.neutral,
    };

    return AdminStatusBadge(key: key, label: status, tone: tone);
  }

  final String label;
  final AdminStatusTone tone;

  Color get _color {
    return switch (tone) {
      AdminStatusTone.primary => AppColors.primaryBlue,
      AdminStatusTone.success => AppColors.success,
      AdminStatusTone.warning => AppColors.warning,
      AdminStatusTone.danger => AppColors.danger,
      AdminStatusTone.info => AppColors.info,
      AdminStatusTone.neutral => AppColors.neutral,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}
