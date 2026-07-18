import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/customer_auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_routes.dart';
import 'data/customer_onboarding_storage.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFinishing = false;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Book shipments easily',
      description:
          'Create pickup and delivery requests with cargo details, package category, preferred vehicle, and receiver information in one guided flow.',
      primaryIcon: Icons.inventory_2_rounded,
      secondaryIcon: Icons.local_shipping_rounded,
      accentIcon: Icons.fact_check_rounded,
      badge: 'Quick booking',
      stat: '3-step flow',
    ),
    _OnboardingPageData(
      title: 'Track shipments live',
      description:
          'Follow shipment progress with current status, route checkpoints, driver placeholders, ETA updates, and delivery timeline visibility.',
      primaryIcon: Icons.route_rounded,
      secondaryIcon: Icons.location_on_rounded,
      accentIcon: Icons.speed_rounded,
      badge: 'Live control',
      stat: 'Real-time ETA',
    ),
    _OnboardingPageData(
      title: 'Secure delivery proofs and invoices',
      description:
          'Keep pickup proofs, delivery confirmations, payment records, and invoice previews organized for every shipment.',
      primaryIcon: Icons.verified_user_rounded,
      secondaryIcon: Icons.receipt_long_rounded,
      accentIcon: Icons.picture_as_pdf_rounded,
      badge: 'Trusted records',
      stat: 'Proof-ready',
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectIfCompleted();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _redirectIfCompleted() async {
    final isCompleted = await ref
        .read(customerOnboardingStorageProvider)
        .isCompleted();
    if (!mounted || !isCompleted) {
      return;
    }

    final authController = ref.read(customerAuthControllerProvider);
    await authController.ensureInitialized();
    if (!mounted) {
      return;
    }

    context.go(
      authController.isAuthenticated ? AppRoutes.home : AppRoutes.auth,
    );
  }

  Future<void> _finishOnboarding() async {
    if (_isFinishing) {
      return;
    }

    setState(() => _isFinishing = true);
    try {
      await ref.read(customerOnboardingStorageProvider).markCompleted();
      if (!mounted) {
        return;
      }
      context.go(AppRoutes.auth);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isFinishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save onboarding status. Please try again.'),
        ),
      );
    }
  }

  Future<void> _goNext() async {
    if (_isLastPage) {
      await _finishOnboarding();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToPage(int index) {
    if (_isFinishing || index == _currentPage) {
      return;
    }

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF8FAFF),
                AppColors.background,
                Color(0xFFEAF1F9),
              ],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth > 560
                  ? AppSpacing.xl
                  : AppSpacing.screenPadding;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      AppSpacing.md,
                      horizontalPadding,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        _OnboardingHeader(
                          isBusy: _isFinishing,
                          onSkip: _finishOnboarding,
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _pages.length,
                            onPageChanged: (index) {
                              setState(() => _currentPage = index);
                            },
                            itemBuilder: (context, index) {
                              return _OnboardingPageTransition(
                                pageController: _pageController,
                                currentPage: _currentPage,
                                index: index,
                                child: _OnboardingPage(data: _pages[index]),
                              );
                            },
                          ),
                        ),
                        _PageIndicators(
                          currentPage: _currentPage,
                          pageCount: _pages.length,
                          onSelected: _goToPage,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          onPressed: _isFinishing ? null : _goNext,
                          icon: _isFinishing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: AppColors.textInverse,
                                  ),
                                )
                              : Icon(
                                  _isLastPage
                                      ? Icons.login_rounded
                                      : Icons.arrow_forward_rounded,
                                ),
                          label: Text(
                            _isFinishing
                                ? 'Saving'
                                : _isLastPage
                                ? 'Get started'
                                : 'Next',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.isBusy, required this.onSkip});

  final bool isBusy;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_shipping_rounded,
            color: AppColors.roadYellow,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'CargoConnect',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primaryNavy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton(
          onPressed: isBusy ? null : onSkip,
          child: const Text('Skip'),
        ),
      ],
    );
  }
}

class _OnboardingPageTransition extends StatelessWidget {
  const _OnboardingPageTransition({
    required this.pageController,
    required this.currentPage,
    required this.index,
    required this.child,
  });

  final PageController pageController;
  final int currentPage;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, child) {
        double page = currentPage.toDouble();
        if (pageController.hasClients &&
            pageController.position.haveDimensions) {
          page = pageController.page ?? currentPage.toDouble();
        }

        final rawDelta = page - index;
        final delta = rawDelta < -1 ? -1.0 : (rawDelta > 1 ? 1.0 : rawDelta);
        final opacity = 1 - (delta.abs() * 0.18);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(delta * 24, 0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _OnboardingIllustration(data: data),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.18,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 26,
              right: 26,
              bottom: 60,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Positioned(top: 12, left: 12, child: _Badge(label: data.badge)),
            Positioned(top: 12, right: 12, child: _Badge(label: data.stat)),
            Positioned(
              top: 66,
              child: Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Icon(
                  data.primaryIcon,
                  color: AppColors.roadYellow,
                  size: 60,
                ),
              ),
            ),
            Positioned(
              left: 30,
              bottom: 40,
              child: _IconTile(
                icon: data.accentIcon,
                color: AppColors.accentOrange,
              ),
            ),
            Positioned(
              right: 28,
              bottom: 34,
              child: _IconTile(
                icon: data.secondaryIcon,
                color: AppColors.primaryBlue,
                large: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.color,
    this.large = false,
  });

  final IconData icon;
  final Color color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 76.0 : 58.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: color, size: large ? 40 : 30),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.primaryBlue),
        ),
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  const _PageIndicators({
    required this.currentPage,
    required this.pageCount,
    required this.onSelected,
  });

  final int currentPage;
  final int pageCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;

        return Semantics(
          button: true,
          label: 'Onboarding page ${index + 1}',
          selected: isActive,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: isActive ? 30 : 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryBlue : AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.primaryIcon,
    required this.secondaryIcon,
    required this.accentIcon,
    required this.badge,
    required this.stat,
  });

  final String title;
  final String description;
  final IconData primaryIcon;
  final IconData secondaryIcon;
  final IconData accentIcon;
  final String badge;
  final String stat;
}
