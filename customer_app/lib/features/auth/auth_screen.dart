import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/auth/customer_auth_controller.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';
import 'data/customer_auth_api.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(
    text: 'aarav.mehta@example.com',
  );
  final _passwordController = TextEditingController(text: 'Cargo@12345');

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateIdentifier(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter email or mobile number';
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final phonePattern = RegExp(r'^[0-9]{10}$');
    if (!emailPattern.hasMatch(input) && !phonePattern.hasMatch(input)) {
      return 'Use a valid email or 10 digit mobile number';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return 'Enter password';
    }
    if (input.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(customerAuthApiProvider)
          .login(
            identifier: _identifierController.text,
            password: _passwordController.text,
            rememberMe: _rememberMe,
          );
      await ref.read(customerAuthControllerProvider).markLoggedIn();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _rememberMe
                ? 'Login successful. Customer remembered.'
                : 'Login successful.',
          ),
        ),
      );
      context.go(AppRoutes.home);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage =
            'Unable to sign in right now. Please try again in a moment.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordMessage() {
    context.go(AppRoutes.forgotPassword);
  }

  void _showCreateAccountMessage() {
    context.go(AppRoutes.register);
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppScaffold(
      title: 'Customer login',
      subtitle:
          'Access your shipment dashboard, tracking updates, invoices, and support workspace.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LoginHero(),
          const SizedBox(height: AppSpacing.lg),
          _LoginFormPanel(
            formKey: _formKey,
            identifierController: _identifierController,
            passwordController: _passwordController,
            obscurePassword: _obscurePassword,
            rememberMe: _rememberMe,
            isLoading: _isLoading,
            errorMessage: _errorMessage,
            onTogglePassword: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
            onRememberChanged: (value) {
              setState(() => _rememberMe = value ?? false);
            },
            onSubmit: _submit,
            onForgotPassword: _showForgotPasswordMessage,
            onCreateAccount: _showCreateAccountMessage,
            validateIdentifier: _validateIdentifier,
            validatePassword: _validatePassword,
          ),
        ],
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.textInverse.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: AppColors.roadYellow,
              size: 34,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CargoConnect Customer',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Secure access for shipment bookings and live freight status.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.surfaceMuted,
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

class _LoginFormPanel extends StatelessWidget {
  const _LoginFormPanel({
    required this.formKey,
    required this.identifierController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onRememberChanged,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onCreateAccount,
    required this.validateIdentifier,
    required this.validatePassword,
    this.errorMessage,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onCreateAccount;
  final FormFieldValidator<String> validateIdentifier;
  final FormFieldValidator<String> validatePassword;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (errorMessage != null) ...[
            _LoginErrorBanner(message: errorMessage!),
            const SizedBox(height: AppSpacing.md),
          ],
          TextFormField(
            controller: identifierController,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email or mobile number',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: validateIdentifier,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: passwordController,
            enabled: !isLoading,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!isLoading) {
                onSubmit();
              }
            },
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: obscurePassword ? 'Show password' : 'Hide password',
                onPressed: isLoading ? null : onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: validatePassword,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Checkbox(
                value: rememberMe,
                onChanged: isLoading ? null : onRememberChanged,
              ),
              const Expanded(child: Text('Remember me')),
              TextButton(
                onPressed: isLoading ? null : onForgotPassword,
                child: const Text('Forgot password?'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: isLoading ? null : onSubmit,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.textInverse,
                    ),
                  )
                : const Icon(Icons.login_rounded),
            label: Text(isLoading ? 'Signing in...' : 'Login'),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.center,
              children: [
                Text(
                  'New to CargoConnect?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: isLoading ? null : onCreateAccount,
                  child: const Text('Create account'),
                ),
              ],
            ),
          ),
        ],
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
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
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
