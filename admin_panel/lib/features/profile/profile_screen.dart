import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/mock_admin_data.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/admin_state_widgets.dart';
import '../../core/widgets/admin_status_badge.dart';
import '../auth/data/admin_auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _hasLoadError = false;
  bool _isChangingPassword = false;
  bool _passwordChanged = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  AdminProfileData? _profile;
  List<AdminStatMock> _activityStats = const <AdminStatMock>[];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });

    try {
      await ref.read(adminAuthControllerProvider).ensureInitialized();
      final results = await Future.wait<Object>([
        ref.read(adminApiServiceProvider).fetchProfile(),
        ref.read(adminApiServiceProvider).fetchDashboard(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = results[0] as AdminProfileData;
        _activityStats = (results[1] as AdminDashboardData).stats
            .take(4)
            .toList();
        _isLoading = false;
        _hasLoadError = false;
      });
    } on ApiException {
      if (!mounted) {
        return;
      }
      final session = ref.read(adminAuthControllerProvider).session;
      setState(() {
        _isLoading = false;
        _hasLoadError = session == null;
        _profile = session == null
            ? null
            : AdminProfileData(
                name: session.displayName,
                role: session.role,
                email: session.displayEmail,
                phone: session.displayPhone,
                status: 'Active',
                lastLogin: session.displayLastLogin,
                permissions: const {},
              );
      });
    }
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _passwordChanged = false;
    });

    try {
      await ref
          .read(adminAuthControllerProvider)
          .changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
            confirmPassword: _confirmPasswordController.text,
          );

      if (!mounted) {
        return;
      }

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      setState(() {
        _isChangingPassword = false;
        _passwordChanged = true;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Admin password updated.')));
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isChangingPassword = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isChangingPassword = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password update failed. Try again.')),
      );
    }
  }

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out admin?'),
        content: const Text(
          'This will clear the admin session from this browser.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    await ref.read(adminAuthControllerProvider).logout();

    if (!mounted) {
      return;
    }

    context.go(AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileHeader(
          passwordChanged: _passwordChanged,
          onLogout: _showLogoutDialog,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_isLoading)
          const AdminLoadingState(message: 'Loading admin profile...')
        else if (_hasLoadError)
          AdminErrorState(
            title: 'Profile unavailable',
            message:
                'Admin profile session could not be loaded. Retry or sign in again to restore account and activity details.',
            onRetry: _loadProfile,
          )
        else if (profile == null)
          AdminErrorState(
            title: 'Profile unavailable',
            message:
                'Admin profile could not be loaded. Retry or sign in again to restore account and activity details.',
            onRetry: _loadProfile,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final profileColumn = Column(
                children: [
                  _AdminIdentityCard(profile: profile),
                  const SizedBox(height: AppSpacing.lg),
                  _AccountActionsCard(onLogout: _showLogoutDialog),
                ],
              );
              final activityAndSecurity = Column(
                children: [
                  _ActivitySummaryCard(stats: _activityStats),
                  const SizedBox(height: AppSpacing.lg),
                  _ChangePasswordCard(
                    formKey: _passwordFormKey,
                    currentPasswordController: _currentPasswordController,
                    newPasswordController: _newPasswordController,
                    confirmPasswordController: _confirmPasswordController,
                    obscureCurrentPassword: _obscureCurrentPassword,
                    onToggleCurrentPassword: () => setState(
                      () => _obscureCurrentPassword = !_obscureCurrentPassword,
                    ),
                    obscureNewPassword: _obscureNewPassword,
                    onToggleNewPassword: () => setState(
                      () => _obscureNewPassword = !_obscureNewPassword,
                    ),
                    obscureConfirmPassword: _obscureConfirmPassword,
                    onToggleConfirmPassword: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                    isChangingPassword: _isChangingPassword,
                    passwordChanged: _passwordChanged,
                    onSubmit: _changePassword,
                  ),
                ],
              );

              if (constraints.maxWidth >= 1100) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 420, child: profileColumn),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: activityAndSecurity),
                  ],
                );
              }

              return Column(
                children: [
                  profileColumn,
                  const SizedBox(height: AppSpacing.lg),
                  activityAndSecurity,
                ],
              );
            },
          ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.passwordChanged, required this.onLogout});

  final bool passwordChanged;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminStatusBadge(
                  label: passwordChanged
                      ? 'Password updated'
                      : 'Active admin account',
                  tone: passwordChanged
                      ? AdminStatusTone.success
                      : AdminStatusTone.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Admin profile',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Review account identity, admin role, contact details, recent activity, and security actions.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            );

            final action = OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
              ),
            );

            if (constraints.maxWidth >= 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: AppSpacing.lg),
                  action,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.lg),
                action,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminIdentityCard extends StatelessWidget {
  const _AdminIdentityCard({required this.profile});

  final AdminProfileData profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.22),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        profile.initials,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    profile.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AdminStatusBadge(
                    label: profile.displayRole,
                    tone: AdminStatusTone.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ProfileInfoTile(
              icon: Icons.mail_outline,
              label: 'Email',
              value: profile.email,
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileInfoTile(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: profile.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileInfoTile(
              icon: Icons.business_center_outlined,
              label: 'Role',
              value: profile.displayRole,
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileInfoTile(
              icon: Icons.access_time_outlined,
              label: 'Last login',
              value: profile.lastLogin,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: Icon(icon, color: AppColors.primaryBlue),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivitySummaryCard extends StatelessWidget {
  const _ActivitySummaryCard({required this.stats});

  final List<AdminStatMock> stats;

  @override
  Widget build(BuildContext context) {
    final summaries = stats.isEmpty
        ? <_ActivityMetric>[]
        : [
            for (final stat in stats)
              _ActivityMetric(
                label: stat.label,
                value: stat.value,
                icon: stat.icon,
                tone: stat.isPositive
                    ? AdminStatusTone.success
                    : AdminStatusTone.warning,
              ),
          ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Recent admin actions across dispatch, finance, reports, and support.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (summaries.isEmpty)
              const AdminEmptyState(
                title: 'No activity metrics',
                message:
                    'Dashboard metrics will appear here after backend activity exists.',
                icon: Icons.insights_outlined,
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 720 ? 4 : 2;
                  final width =
                      (constraints.maxWidth - AppSpacing.md * (columns - 1)) /
                      columns;

                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final summary in summaries)
                        SizedBox(width: width, child: summary),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ActivityMetric extends StatelessWidget {
  const _ActivityMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final AdminStatusTone tone;

  Color get _color {
    return switch (tone) {
      AdminStatusTone.primary => AppColors.primaryBlue,
      AdminStatusTone.success => AppColors.success,
      AdminStatusTone.warning => AppColors.warning,
      AdminStatusTone.danger => AppColors.danger,
      AdminStatusTone.info => AppColors.info,
      AdminStatusTone.neutral => AppColors.neutral,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _color),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ChangePasswordCard extends StatelessWidget {
  const _ChangePasswordCard({
    required this.formKey,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.obscureCurrentPassword,
    required this.onToggleCurrentPassword,
    required this.obscureNewPassword,
    required this.onToggleNewPassword,
    required this.obscureConfirmPassword,
    required this.onToggleConfirmPassword,
    required this.isChangingPassword,
    required this.passwordChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool obscureCurrentPassword;
  final VoidCallback onToggleCurrentPassword;
  final bool obscureNewPassword;
  final VoidCallback onToggleNewPassword;
  final bool obscureConfirmPassword;
  final VoidCallback onToggleConfirmPassword;
  final bool isChangingPassword;
  final bool passwordChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change password',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Update the active admin password through the secure API.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  if (passwordChanged)
                    const AdminStatusBadge(
                      label: 'Updated',
                      tone: AdminStatusTone.success,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _PasswordField(
                controller: currentPasswordController,
                label: 'Current password',
                obscureText: obscureCurrentPassword,
                onToggleVisibility: onToggleCurrentPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter the current password';
                  }
                  if (value.length < 6) {
                    return 'Use at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _PasswordField(
                controller: newPasswordController,
                label: 'New password',
                obscureText: obscureNewPassword,
                onToggleVisibility: onToggleNewPassword,
                validator: _newPasswordValidator,
              ),
              const SizedBox(height: AppSpacing.md),
              _PasswordField(
                controller: confirmPasswordController,
                label: 'Confirm password',
                obscureText: obscureConfirmPassword,
                onToggleVisibility: onToggleConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirm the new password';
                  }
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: isChangingPassword ? null : onSubmit,
                icon: isChangingPassword
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_reset_outlined),
                label: Text(
                  isChangingPassword ? 'Updating...' : 'Change password',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggleVisibility,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: obscureText ? 'Show password' : 'Hide password',
          onPressed: onToggleVisibility,
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: validator,
    );
  }
}

class _AccountActionsCard extends StatelessWidget {
  const _AccountActionsCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Session controls for this admin account.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _newPasswordValidator(String? value) {
  final password = value ?? '';
  if (password.isEmpty) {
    return 'Enter the new password';
  }
  if (password.length < 8) {
    return 'Use at least 8 characters';
  }
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return 'Include an uppercase letter';
  }
  if (!RegExp(r'[0-9]').hasMatch(password)) {
    return 'Include a number';
  }
  return null;
}
