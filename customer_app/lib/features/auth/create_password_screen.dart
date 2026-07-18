import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';
import 'data/customer_auth_api.dart';
import 'password_strength.dart';

class CreatePasswordScreen extends ConsumerStatefulWidget {
  const CreatePasswordScreen({super.key, this.identifier, this.resetToken});

  final String? identifier;
  final String? resetToken;

  @override
  ConsumerState<CreatePasswordScreen> createState() =>
      _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends ConsumerState<CreatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  PasswordStrength get _passwordStrength {
    return PasswordStrength.evaluate(_passwordController.text);
  }

  bool get _canConfirmPassword => _passwordStrength.isValid;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_handlePasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_handlePasswordChanged);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handlePasswordChanged() {
    if (!_canConfirmPassword && _confirmPasswordController.text.isNotEmpty) {
      _confirmPasswordController.clear();
    }
    setState(() {});
  }

  String? _validatePassword(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return 'Enter new password';
    }
    if (!PasswordStrength.evaluate(input).isValid) {
      return 'Complete all password rules';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_canConfirmPassword) {
      return 'Enter a valid password first';
    }
    final input = value ?? '';
    if (input.isEmpty) {
      return 'Confirm new password';
    }
    if (input != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final identifier = widget.identifier;
    final resetToken = widget.resetToken;
    if (identifier == null ||
        identifier.trim().isEmpty ||
        resetToken == null ||
        resetToken.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Reset session expired. Request a new OTP to continue.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(customerAuthApiProvider)
          .createNewPassword(
            identifier: identifier,
            resetToken: resetToken,
            newPassword: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please login.')),
      );
      context.go(AppRoutes.auth);
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
            'Unable to update password right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppScaffold(
      title: 'Create new password',
      subtitle: 'Set a strong password for your CargoConnect customer account.',
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CreatePasswordHeader(),
            const SizedBox(height: AppSpacing.lg),
            if (_errorMessage != null) ...[
              _CreatePasswordErrorBanner(message: _errorMessage!),
              const SizedBox(height: AppSpacing.md),
            ],
            TextFormField(
              controller: _passwordController,
              enabled: !_isSubmitting,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'New password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: AppSpacing.sm),
            PasswordStrengthMeter(strength: _passwordStrength),
            const SizedBox(height: AppSpacing.md),
            PasswordRulesChecklist(password: _passwordController.text),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _confirmPasswordController,
              enabled: !_isSubmitting && _canConfirmPassword,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_isSubmitting && _canConfirmPassword) {
                  _submit();
                }
              },
              decoration: InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: const Icon(Icons.lock_reset_rounded),
                helperText: _canConfirmPassword
                    ? null
                    : 'Complete password rules first',
                suffixIcon: IconButton(
                  tooltip: _obscureConfirmPassword
                      ? 'Show confirm password'
                      : 'Hide confirm password',
                  onPressed: (!_isSubmitting && _canConfirmPassword)
                      ? () {
                          setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          );
                        }
                      : null,
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: _validateConfirmPassword,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.textInverse,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                _isSubmitting ? 'Updating password...' : 'Submit password',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => context.go(AppRoutes.auth),
                child: const Text('Back to login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePasswordHeader extends StatelessWidget {
  const _CreatePasswordHeader();

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
              Icons.verified_user_outlined,
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
                  'Protect your account',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Use a password that keeps shipment records and invoices secure.',
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

class _CreatePasswordErrorBanner extends StatelessWidget {
  const _CreatePasswordErrorBanner({required this.message});

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
