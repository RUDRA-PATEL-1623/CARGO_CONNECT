import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/customer_auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_routes.dart';
import '../onboarding/data/customer_onboarding_storage.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _minimumDisplay = Duration(milliseconds: 850);
  static const String _version = 'Version 1.0.0+1';

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_routeNext());
    });
  }

  Future<void> _routeNext() async {
    final targetRouteFuture = _resolveTargetRoute();
    await Future<void>.delayed(_minimumDisplay);

    final targetRoute = await targetRouteFuture.catchError((_) {
      return AppRoutes.onboarding;
    });

    if (!mounted) {
      return;
    }

    context.go(targetRoute);
  }

  Future<String> _resolveTargetRoute() async {
    final authController = ref.read(customerAuthControllerProvider);
    await authController.ensureInitialized();

    if (authController.isAuthenticated) {
      return AppRoutes.home;
    }

    final onboardingCompleted = await ref
        .read(customerOnboardingStorageProvider)
        .isCompleted();

    return onboardingCompleted ? AppRoutes.auth : AppRoutes.onboarding;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryNavy,
              Color(0xFF113B73),
              AppColors.background,
            ],
            stops: [0, 0.48, 1],
          ),
        ),
        child: Stack(
          children: [
            const _LayeredBackground(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth > 560 ? 440.0 : 520.0;

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(
                              AppSpacing.screenPadding,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(height: AppSpacing.md),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _CargoConnectBrandMark(
                                      animation: _controller,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    Text(
                                      'CargoConnect',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(
                                            color: AppColors.textInverse,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'Smart logistics, real-time delivery control.',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: AppColors.textInverse
                                                .withValues(alpha: 0.86),
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                    _LogisticsMotion(animation: _controller),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: AppSpacing.xl),
                                    _ProgressStatus(animation: _controller),
                                    const SizedBox(height: AppSpacing.lg),
                                    Text(
                                      _version,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: AppColors.primaryNavy
                                                .withValues(alpha: 0.62),
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayeredBackground extends StatelessWidget {
  const _LayeredBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: -72,
          right: 96,
          top: 94,
          child: Transform.rotate(
            angle: -0.22,
            child: Container(
              height: 78,
              decoration: BoxDecoration(
                color: AppColors.textInverse.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -44,
          child: Container(
            height: 220,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
          ),
        ),
        Positioned(
          left: -34,
          right: 48,
          bottom: 126,
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.roadYellow.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    );
  }
}

class _CargoConnectBrandMark extends StatelessWidget {
  const _CargoConnectBrandMark({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final pulse = 1 + (math.sin(animation.value * math.pi * 2) * 0.018);
        return Transform.scale(scale: pulse, child: child);
      },
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.textInverse,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
            ),
            const Positioned(
              top: 23,
              left: 25,
              child: Icon(
                Icons.route_rounded,
                color: AppColors.roadYellow,
                size: 32,
              ),
            ),
            const Positioned(
              right: 18,
              bottom: 22,
              child: Icon(
                Icons.local_shipping_rounded,
                color: AppColors.accentOrange,
                size: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogisticsMotion extends StatelessWidget {
  const _LogisticsMotion({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final travel = Curves.easeInOut.transform(animation.value);
        final float = math.sin(animation.value * math.pi * 2) * 7;

        return Container(
          height: 128,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNavy.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final travelDistance = math.max(72.0, constraints.maxWidth - 116);

              return Stack(
                alignment: Alignment.center,
                children: [
                  const Positioned(
                    left: 12,
                    right: 12,
                    bottom: 36,
                    child: _RouteTrack(),
                  ),
                  Positioned(
                    left: 18,
                    top: 18,
                    child: Transform.translate(
                      offset: Offset(0, float),
                      child: const _MotionTile(
                        icon: Icons.inventory_2_rounded,
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 18,
                    top: 18,
                    child: Transform.translate(
                      offset: Offset(0, -float * 0.7),
                      child: const _MotionTile(
                        icon: Icons.home_work_rounded,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 34 + (travel * travelDistance),
                    bottom: 18,
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: AppColors.primaryBlue,
                      size: 52,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 1,
                    child: _MovingDots(animationValue: animation.value),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _RouteTrack extends StatelessWidget {
  const _RouteTrack();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.trip_origin_rounded,
          color: AppColors.success,
          size: 18,
        ),
        Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const Icon(
          Icons.location_on_rounded,
          color: AppColors.accentOrange,
          size: 22,
        ),
      ],
    );
  }
}

class _MotionTile extends StatelessWidget {
  const _MotionTile({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

class _MovingDots extends StatelessWidget {
  const _MovingDots({required this.animationValue});

  final double animationValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final phase = (animationValue + (index * 0.14)) % 1;
        final opacity = 0.2 + (math.sin(phase * math.pi) * 0.55);
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _ProgressStatus extends StatelessWidget {
  const _ProgressStatus({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final dotCount = 1 + (animation.value * 3).floor().clamp(0, 2);
        final dots = List.filled(dotCount, '.').join();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Checking secure session$dots',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.primaryNavy),
            ),
          ],
        );
      },
    );
  }
}
