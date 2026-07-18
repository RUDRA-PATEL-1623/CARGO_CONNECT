import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../auth/data/customer_auth_api.dart';
import '../auth/password_strength.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  String? _errorMessage;

  PasswordStrength get _newPasswordStrength {
    return PasswordStrength.evaluate(_newPasswordController.text);
  }

  bool get _canConfirmPassword => _newPasswordStrength.isValid;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_handleNewPasswordChanged);
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_handleNewPasswordChanged);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleNewPasswordChanged() {
    if (!_canConfirmPassword && _confirmPasswordController.text.isNotEmpty) {
      _confirmPasswordController.clear();
    }
    setState(() {});
  }

  String? _validateCurrentPassword(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return 'Enter current password';
    }
    if (input.length < 8) {
      return 'Current password must be at least 8 characters';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return 'Enter new password';
    }
    if (!PasswordStrength.evaluate(input).isValid) {
      return 'Complete all password rules';
    }
    if (input == _currentPasswordController.text) {
      return 'New password must be different';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_canConfirmPassword) {
      return 'Enter a valid new password first';
    }
    final input = value ?? '';
    if (input.isEmpty) {
      return 'Confirm new password';
    }
    if (input != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(customerAuthApiProvider)
          .changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
            confirmPassword: _confirmPasswordController.text,
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
      context.go(AppRoutes.profile);
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
            'Unable to change password right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppScaffold(
      title: 'Change password',
      subtitle: 'Update your CargoConnect customer password.',
      bottomNavigationIndex: 3,
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PasswordHeader(),
            const SizedBox(height: AppSpacing.lg),
            if (_errorMessage != null) ...[
              _ChangePasswordErrorBanner(message: _errorMessage!),
              const SizedBox(height: AppSpacing.md),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _currentPasswordController,
                      enabled: !_isSaving,
                      obscureText: _obscureCurrent,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Current password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _obscureCurrent
                              ? 'Show current password'
                              : 'Hide current password',
                          onPressed: _isSaving
                              ? null
                              : () {
                                  setState(
                                    () => _obscureCurrent = !_obscureCurrent,
                                  );
                                },
                          icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: _validateCurrentPassword,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _newPasswordController,
                      enabled: !_isSaving,
                      obscureText: _obscureNew,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        prefixIcon: const Icon(
                          Icons.enhanced_encryption_outlined,
                        ),
                        suffixIcon: IconButton(
                          tooltip: _obscureNew
                              ? 'Show new password'
                              : 'Hide new password',
                          onPressed: _isSaving
                              ? null
                              : () {
                                  setState(() => _obscureNew = !_obscureNew);
                                },
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: _validateNewPassword,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    PasswordStrengthMeter(strength: _newPasswordStrength),
                    const SizedBox(height: AppSpacing.md),
                    PasswordRulesChecklist(
                      password: _newPasswordController.text,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _confirmPasswordController,
                      enabled: !_isSaving && _canConfirmPassword,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_isSaving && _canConfirmPassword) {
                          _submit();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: const Icon(Icons.lock_reset_rounded),
                        helperText: _canConfirmPassword
                            ? null
                            : 'Complete new password rules first',
                        suffixIcon: IconButton(
                          tooltip: _obscureConfirm
                              ? 'Show confirm password'
                              : 'Hide confirm password',
                          onPressed: (!_isSaving && _canConfirmPassword)
                              ? () {
                                  setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  );
                                }
                              : null,
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: _validateConfirmPassword,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _submit,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.textInverse,
                      ),
                    )
                  : const Icon(Icons.verified_user_outlined),
              label: Text(_isSaving ? 'Updating...' : 'Update password'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordHeader extends StatelessWidget {
  const _PasswordHeader();

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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.textInverse.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: const Icon(
              Icons.password_rounded,
              color: AppColors.roadYellow,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Protect shipment records',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Use a strong password for invoices, proof files, and live tracking.',
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

class _ChangePasswordErrorBanner extends StatelessWidget {
  const _ChangePasswordErrorBanner({required this.message});

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
