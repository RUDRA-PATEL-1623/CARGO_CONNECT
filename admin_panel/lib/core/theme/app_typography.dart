import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTypography {
  const AppTypography._();

  static const TextTheme textTheme = TextTheme(
    displaySmall: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 32,
      fontWeight: FontWeight.w800,
      height: 1.15,
    ),
    headlineSmall: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 24,
      fontWeight: FontWeight.w800,
      height: 1.2,
    ),
    titleLarge: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w800,
      height: 1.25,
    ),
    titleMedium: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w800,
      height: 1.3,
    ),
    bodyLarge: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    bodyMedium: TextStyle(
      color: AppColors.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.45,
    ),
    labelLarge: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 13,
      fontWeight: FontWeight.w800,
      height: 1.2,
    ),
    labelMedium: TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.2,
    ),
  );
}
