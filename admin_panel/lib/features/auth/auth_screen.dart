import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/admin_dialog.dart';
import 'data/admin_auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(adminAuthControllerProvider)
          .login(
            identifier: _identityController.text,
            password: _passwordController.text,
            rememberMe: _rememberMe,
          );

      if (!mounted) {
        return;
      }

      setState(() => _isSubmitting = false);
      context.go(_routeAfterLogin());
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Admin login failed. Please try again.';
      });
    }
  }

  String _routeAfterLogin() {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    if (from != null &&
        from.startsWith('/') &&
        !from.startsWith(AppRoutes.auth)) {
      return from;
    }

    return AppRoutes.dashboard;
  }

  String? _validateIdentity(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter admin email or username';
    }

    if (input.contains('@')) {
      final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (!emailPattern.hasMatch(input)) {
        return 'Enter a valid email address';
      }
      return null;
    }

    final usernamePattern = RegExp(r'^[a-zA-Z0-9._-]{3,}$');
    if (!usernamePattern.hasMatch(input)) {
      return 'Username must be at least 3 characters';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Enter your password';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.surfaceMuted.withValues(alpha: 0.86),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;
              final horizontalPadding = constraints.maxWidth >= 720
                  ? AppSpacing.xl
                  : AppSpacing.md;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: AppSpacing.lg,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - AppSpacing.xl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: isWide
                          ? Row(
                              children: [
                                const Expanded(child: _LoginBrandPanel()),
                                const SizedBox(width: AppSpacing.xxl),
                                SizedBox(
                                  width: 430,
                                  child: _LoginFormCard(
                                    formKey: _formKey,
                                    identityController: _identityController,
                                    passwordController: _passwordController,
                                    rememberMe: _rememberMe,
                                    obscurePassword: _obscurePassword,
                                    isSubmitting: _isSubmitting,
                                    errorMessage: _errorMessage,
                                    onRememberChanged: (value) => setState(
                                      () => _rememberMe = value ?? false,
                                    ),
                                    onTogglePassword: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                    onForgotPassword: _showForgotPassword,
                                    onSubmit: _submit,
                                    validateIdentity: _validateIdentity,
                                    validatePassword: _validatePassword,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                const _CompactBrandHeader(),
                                const SizedBox(height: AppSpacing.lg),
                                _LoginFormCard(
                                  formKey: _formKey,
                                  identityController: _identityController,
                                  passwordController: _passwordController,
                                  rememberMe: _rememberMe,
                                  obscurePassword: _obscurePassword,
                                  isSubmitting: _isSubmitting,
                                  errorMessage: _errorMessage,
                                  onRememberChanged: (value) => setState(
                                    () => _rememberMe = value ?? false,
                                  ),
                                  onTogglePassword: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  onForgotPassword: _showForgotPassword,
                                  onSubmit: _submit,
                                  validateIdentity: _validateIdentity,
                                  validatePassword: _validatePassword,
                                ),
                              ],
                            ),
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

  void _showForgotPassword() {
    showAdminDialog(
      context: context,
      title: 'Password reset placeholder',
      message:
          'Admin password reset will be connected to secure email delivery in a later integration prompt.',
      icon: Icons.lock_reset_rounded,
    );
  }
}

class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _BrandMark(size: 58),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'CargoConnect Admin',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Control shipments, drivers, invoices, and operational reports from one logistics command center.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _OperationsPreview(),
      ],
    );
  }
}

class _CompactBrandHeader extends StatelessWidget {
  const _CompactBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _BrandMark(size: 52),
        const SizedBox(height: AppSpacing.md),
        Text(
          'CargoConnect Admin',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Secure logistics operations console',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_shipping_rounded,
            color: AppColors.textInverse,
            size: 30,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.accentOrange,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ],
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({
    required this.formKey,
    required this.identityController,
    required this.passwordController,
    required this.rememberMe,
    required this.obscurePassword,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onRememberChanged,
    required this.onTogglePassword,
    required this.onForgotPassword,
    required this.onSubmit,
    required this.validateIdentity,
    required this.validatePassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController identityController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool obscurePassword;
  final bool isSubmitting;
  final String? errorMessage;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgotPassword;
  final VoidCallback onSubmit;
  final FormFieldValidator<String> validateIdentity;
  final FormFieldValidator<String> validatePassword;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sign in', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Use your admin credentials to open the dashboard.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _LoginErrorBanner(message: errorMessage!),
              ],
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: identityController,
                enabled: !isSubmitting,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                validator: validateIdentity,
                decoration: const InputDecoration(
                  labelText: 'Email or username',
                  hintText: 'admin@cargoconnect.com',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: passwordController,
                enabled: !isSubmitting,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: validatePassword,
                onFieldSubmitted: (_) => isSubmitting ? null : onSubmit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: isSubmitting ? null : onTogglePassword,
                    tooltip: obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _RememberMeControl(
                    value: rememberMe,
                    enabled: !isSubmitting,
                    onChanged: onRememberChanged,
                  ),
                  TextButton(
                    onPressed: isSubmitting ? null : onForgotPassword,
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSubmitting ? null : onSubmit,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textInverse,
                          ),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(isSubmitting ? 'Signing in...' : 'Sign in'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Authorized CargoConnect administrators only.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RememberMeControl extends StatelessWidget {
  const _RememberMeControl({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      onTap: enabled ? () => onChanged(!value) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: value,
            onChanged: enabled ? onChanged : null,
            visualDensity: VisualDensity.compact,
          ),
          const Text('Remember me'),
        ],
      ),
    );
  }
}

class _OperationsPreview extends StatelessWidget {
  const _OperationsPreview();

  @override
  Widget build(BuildContext context) {
    final items = [
      const _PreviewItem(
        icon: Icons.inventory_2_outlined,
        label: 'Active shipments',
        value: '128',
      ),
      const _PreviewItem(
        icon: Icons.local_shipping_outlined,
        label: 'Drivers online',
        value: '42',
      ),
      const _PreviewItem(
        icon: Icons.receipt_long_outlined,
        label: 'Invoices queued',
        value: '19',
      ),
    ];

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [for (final item in items) SizedBox(width: 180, child: item)],
    );
  }
}

class _PreviewItem extends StatelessWidget {
  const _PreviewItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryBlue),
            const SizedBox(height: AppSpacing.md),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xxs),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _LoginErrorBanner extends StatelessWidget {
  const _LoginErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
