import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

enum ShipmentStatus { booked, inTransit, delivered, delayed, cancelled }

class StatusBadgeStyle {
  const StatusBadgeStyle({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ShipmentStatus status;

  static const Map<ShipmentStatus, StatusBadgeStyle> styles = {
    ShipmentStatus.booked: StatusBadgeStyle(
      label: 'Booked',
      foreground: AppColors.info,
      background: Color(0xFFE0F2FE),
    ),
    ShipmentStatus.inTransit: StatusBadgeStyle(
      label: 'In transit',
      foreground: AppColors.primaryBlue,
      background: Color(0xFFEAF2FF),
    ),
    ShipmentStatus.delivered: StatusBadgeStyle(
      label: 'Delivered',
      foreground: AppColors.success,
      background: Color(0xFFE8F7ED),
    ),
    ShipmentStatus.delayed: StatusBadgeStyle(
      label: 'Delayed',
      foreground: AppColors.warning,
      background: Color(0xFFFFF7E6),
    ),
    ShipmentStatus.cancelled: StatusBadgeStyle(
      label: 'Cancelled',
      foreground: AppColors.danger,
      background: Color(0xFFFFEBEE),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final style = styles[status]!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          style.label,
          style: TextStyle(
            color: style.foreground,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}
