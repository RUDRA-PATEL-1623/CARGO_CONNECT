import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/driver_auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';
import 'data/driver_auth_api.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter your driver username';
    }
    if (input.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (input.contains(' ')) {
      return 'Username cannot contain spaces';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return 'Enter your password';
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
          .read(driverAuthApiProvider)
          .login(
            identifier: _usernameController.text,
            password: _passwordController.text,
          );
      await ref.read(driverAuthControllerProvider).markLoggedIn();

      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      context.go(AppRoutes.dashboard);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Driver login failed. Please try again.';
      });
    }
  }

  void _showForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Forgot password flow will be added in a later prompt.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppScaffold(
      title: 'Driver login',
      subtitle: 'Sign in to manage assigned trips and proof uploads.',
      showAppBar: false,
      maxContentWidth: 560,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _LoginBrandCard(),
            const SizedBox(height: AppSpacing.lg),
            if (_errorMessage != null) ...[
              _LoginErrorBanner(message: _errorMessage!),
              const SizedBox(height: AppSpacing.md),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      enabled: !_isLoading,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'driver.ops',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: _validateUsername,
                      onChanged: (_) {
                        if (_errorMessage != null) {
                          setState(() => _errorMessage = null);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_isLoading,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: _validatePassword,
                      onFieldSubmitted: (_) {
                        if (!_isLoading) {
                          _submit();
                        }
                      },
                      onChanged: (_) {
                        if (_errorMessage != null) {
                          setState(() => _errorMessage = null);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _showForgotPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textInverse,
                              ),
                            )
                          : const Icon(Icons.login_rounded),
                      label: Text(_isLoading ? 'Signing in...' : 'Login'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginBrandCard extends StatelessWidget {
  const _LoginBrandCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  'CargoConnect Driver',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Secure access for route, pickup, and delivery workflows.',
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

class _LoginErrorBanner extends StatelessWidget {
  const _LoginErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
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
