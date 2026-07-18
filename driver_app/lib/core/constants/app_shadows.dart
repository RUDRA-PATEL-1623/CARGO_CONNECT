import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x140B1F3A), blurRadius: 18, offset: Offset(0, 8)),
  ];

  static List<BoxShadow> focused = [
    BoxShadow(
      color: AppColors.primaryBlue.withValues(alpha: 0.18),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}
