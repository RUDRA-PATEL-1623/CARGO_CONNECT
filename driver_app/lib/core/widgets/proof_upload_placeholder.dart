import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class ProofUploadPlaceholder extends StatelessWidget {
  const ProofUploadPlaceholder({
    super.key,
    required this.title,
    required this.description,
    required this.status,
    this.onPressed,
  });

  final String title;
  final String description;
  final String status;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.primaryBlue,
                size: 30,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    status,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: AppColors.warning),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Mock upload',
              onPressed: onPressed,
              icon: const Icon(Icons.cloud_upload_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
