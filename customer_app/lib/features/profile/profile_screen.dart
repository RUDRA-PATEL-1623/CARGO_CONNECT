import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/customer_auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../auth/data/customer_auth_api.dart';
import 'data/customer_profile_api.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Future<CustomerProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<CustomerProfile> _loadProfile() {
    return ref.read(customerProfileApiProvider).getProfile();
  }

  void _retryProfile() {
    setState(() => _profileFuture = _loadProfile());
  }

  void _showLogoutSheet(BuildContext context, WidgetRef ref) {
    final parentContext = context;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: AppColors.danger,
                size: 40,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Log out?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Your saved customer session will be cleared on this device.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final router = GoRouter.of(parentContext);

                  navigator.pop();
                  await ref.read(customerAuthApiProvider).logout();
                  await ref
                      .read(customerAuthControllerProvider)
                      .handleUnauthorized();
                  router.go(AppRoutes.auth);
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CustomerProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data;

        return CommonAppScaffold(
          title: 'Profile',
          subtitle: 'Manage your CargoConnect customer account.',
          bottomNavigationIndex: 3,
          body: Builder(
            builder: (context) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget(message: 'Loading customer profile');
              }

              if (snapshot.hasError || profile == null) {
                return ErrorStateWidget(
                  title: 'Profile unavailable',
                  message: _profileError(snapshot.error),
                  onRetry: _retryProfile,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHero(profile: profile),
                  const SizedBox(height: AppSpacing.lg),
                  _QuickStats(profile: profile),
                  const SizedBox(height: AppSpacing.lg),
                  _ContactDetails(profile: profile),
                  const SizedBox(height: AppSpacing.lg),
                  _ProfileActions(
                    onEditProfile: () => context.go(AppRoutes.editProfile),
                    onChangePassword: () =>
                        context.go(AppRoutes.changePassword),
                    onNotifications: () => context.go(AppRoutes.notifications),
                    onLogout: () => _showLogoutSheet(context, ref),
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

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile});

  final CustomerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryNavy, AppColors.primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.roadYellow,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(
                    color: AppColors.textInverse.withValues(alpha: 0.45),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    profile.initials,
                    style: const TextStyle(
                      color: AppColors.primaryNavy,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.textInverse,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      profile.customerCode.isEmpty
                          ? 'Customer account'
                          : profile.customerCode,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.surfaceMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _AccountStatusBadge(status: profile.accountStatus),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeroMeta(
                  icon: Icons.badge_outlined,
                  label: 'Customer ID',
                  value: profile.customerCode.isEmpty
                      ? 'Pending'
                      : profile.customerCode,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeroMeta(
                  icon: Icons.verified_user_outlined,
                  label: 'KYC',
                  value: profile.accountStatus == 'active'
                      ? 'Verified'
                      : 'Pending',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.textInverse.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: AppColors.textInverse.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.roadYellow, size: 20),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.surfaceMuted),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textInverse,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.profile});

  final CustomerProfile profile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRow = constraints.maxWidth >= 620;
        final stats = [
          _ProfileStat(
            label: 'Shipments',
            value: '${profile.stats.totalShipments}',
            icon: Icons.local_shipping_rounded,
            color: AppColors.primaryBlue,
          ),
          const _ProfileStat(
            label: 'Delivered',
            value: '--',
            icon: Icons.done_all_rounded,
            color: AppColors.success,
          ),
          const _ProfileStat(
            label: 'Invoices',
            value: '--',
            icon: Icons.receipt_long_rounded,
            color: AppColors.accentOrange,
          ),
        ];

        if (!useRow) {
          return Column(
            children: [
              for (final stat in stats) ...[
                _StatCard(stat: stat),
                if (stat != stats.last) const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (final stat in stats) ...[
              Expanded(child: _StatCard(stat: stat)),
              if (stat != stats.last) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final _ProfileStat stat;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: stat.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Icon(stat.icon, color: stat.color),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.value,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    stat.label,
                    style: Theme.of(context).textTheme.labelMedium,
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

class _ContactDetails extends StatelessWidget {
  const _ContactDetails({required this.profile});

  final CustomerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.contact_mail_outlined,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Contact details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            _ProfileInfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Name',
              value: profile.displayName,
            ),
            _ProfileInfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: profile.email.isEmpty
                  ? 'Email unavailable'
                  : profile.email,
            ),
            _ProfileInfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: profile.phone.isEmpty
                  ? 'Phone unavailable'
                  : profile.phone,
            ),
            _ProfileInfoRow(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: profile.address.displayAddress,
            ),
            _ProfileInfoRow(
              icon: Icons.verified_outlined,
              label: 'Account status',
              value: profile.accountStatus == 'active'
                  ? 'Active and verified'
                  : 'Verification pending',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({
    required this.onEditProfile,
    required this.onChangePassword,
    required this.onNotifications,
    required this.onLogout,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onNotifications;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune_rounded, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Account actions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _ActionTile(
              icon: Icons.edit_outlined,
              title: 'Edit profile',
              subtitle: 'Update name, phone, and address',
              onTap: onEditProfile,
            ),
            _ActionTile(
              icon: Icons.lock_reset_rounded,
              title: 'Change password',
              subtitle: 'Open the secure password reset screen',
              onTap: onChangePassword,
            ),
            _ActionTile(
              icon: Icons.notifications_active_outlined,
              title: 'Notification settings',
              subtitle: 'Review shipment and payment alerts',
              onTap: onNotifications,
            ),
            _ActionTile(
              icon: Icons.logout_rounded,
              title: 'Logout',
              subtitle: 'Clear saved session and return to login',
              color: AppColors.danger,
              onTap: onLogout,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = AppColors.primaryBlue,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            color: color,
            size: 16,
          ),
          onTap: onTap,
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}

class _AccountStatusBadge extends StatelessWidget {
  const _AccountStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    final color = isActive ? AppColors.success : AppColors.warning;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.verified_rounded : Icons.pending_outlined,
              color: color,
              size: 14,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              isActive ? 'Active' : 'Pending',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat {
  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

String _profileError(Object? error) {
  if (error is ApiException) {
    return error.message;
  }
  return 'Unable to load your customer profile.';
}
