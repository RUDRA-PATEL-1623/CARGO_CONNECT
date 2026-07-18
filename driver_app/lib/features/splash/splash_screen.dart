import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_routes.dart';
import '../../core/storage/auth_token_storage.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () async {
      if (mounted) {
        final token = await ref.read(authTokenStorageProvider).readToken();
        if (!mounted) {
          return;
        }
        context.go(
          token == null || token.isEmpty ? AppRoutes.auth : AppRoutes.dashboard,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryNavy, AppColors.primaryBlue],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              children: [
                const Spacer(),
                const _AnimatedTruckMark(),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'CargoConnect Driver',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Move every shipment with confidence.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.surfaceMuted,
                  ),
                ),
                const Spacer(),
                const _RoutePulse(),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Driver App v1.0.0',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.surfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedTruckMark extends StatelessWidget {
  const _AnimatedTruckMark();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -14, end: 14),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, offset, child) {
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              color: AppColors.textInverse.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.textInverse.withValues(alpha: 0.18),
              ),
            ),
          ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.textInverse,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: AppColors.primaryBlue,
              size: 48,
            ),
          ),
          Positioned(
            right: 14,
            top: 26,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.roadYellow,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                color: AppColors.primaryNavy,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePulse extends StatelessWidget {
  const _RoutePulse();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.96 + (value * 0.04), child: child),
        );
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.textInverse.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: AppColors.textInverse.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.route_rounded, color: AppColors.roadYellow),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Preparing duty dashboard',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.textInverse),
              ),
            ),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textInverse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
