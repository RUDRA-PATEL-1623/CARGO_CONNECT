import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.isPositive,
    this.accentColor = AppColors.primaryBlue,
  });

  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final bool isPositive;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final deltaColor = isPositive ? AppColors.success : AppColors.warning;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    delta,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: deltaColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
