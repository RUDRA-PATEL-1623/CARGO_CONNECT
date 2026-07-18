import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.message = 'Loading shipment data'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
