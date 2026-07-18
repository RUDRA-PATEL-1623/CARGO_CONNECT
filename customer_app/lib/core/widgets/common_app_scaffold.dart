import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import 'customer_bottom_navigation.dart';

class CommonAppScaffold extends StatelessWidget {
  const CommonAppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.showAppBar = true,
    this.scrollable = true,
    this.maxContentWidth = AppSpacing.maxContentWidth,
    this.bottomNavigationIndex,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final bool showAppBar;
  final bool scrollable;
  final double maxContentWidth;
  final int? bottomNavigationIndex;

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth > 520
              ? AppSpacing.xl
              : AppSpacing.screenPadding;

          final page = Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!showAppBar) ...[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (subtitle != null) ...[
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  body,
                ],
              ),
            ),
          );

          if (!scrollable) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: AppSpacing.lg,
              ),
              child: page,
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: AppSpacing.lg,
            ),
            child: page,
          );
        },
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: showAppBar ? AppBar(title: Text(title), actions: actions) : null,
      bottomNavigationBar: bottomNavigationIndex == null
          ? null
          : CustomerBottomNavigation(selectedIndex: bottomNavigationIndex!),
      body: content,
    );
  }
}
