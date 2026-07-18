import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../auth/data/driver_auth_api.dart';

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

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateCurrentPassword(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return 'Enter current password';
    }
    if (input.length < 6) {
      return 'Current password must be at least 6 characters';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return 'Enter new password';
    }
    if (input.length < 8) {
      return 'Use at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(input)) {
      return 'Add at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(input)) {
      return 'Add at least one lowercase letter';
    }
    if (!RegExp(r'\d').hasMatch(input)) {
      return 'Add at least one number';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(input)) {
      return 'Add at least one special character';
    }
    if (input == _currentPasswordController.text) {
      return 'New password must be different';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Confirm new password';
    }
    if (value != _newPasswordController.text) {
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
      await ref.read(driverAuthApiProvider).changePassword(
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
      setState(() {
        _isSaving = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = 'Unable to change password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppScaffold(
      title: 'Change password',
      subtitle: 'Update the password for your driver login.',
      bottomNavigationIndex: 3,
      body: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  _ErrorBanner(message: _errorMessage!),
                  const SizedBox(height: AppSpacing.md),
                ],
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrent,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip:
                          _obscureCurrent ? 'Show password' : 'Hide password',
                      onPressed: () => setState(
                        () => _obscureCurrent = !_obscureCurrent,
                      ),
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
                  obscureText: _obscureNew,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    prefixIcon: const Icon(Icons.password_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscureNew ? 'Show password' : 'Hide password',
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                      icon: Icon(
                        _obscureNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: _validateNewPassword,
                  onChanged: (_) {
                    if (_confirmPasswordController.text.isNotEmpty) {
                      _formKey.currentState?.validate();
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: const Icon(Icons.verified_user_outlined),
                    suffixIcon: IconButton(
                      tooltip:
                          _obscureConfirm ? 'Show password' : 'Hide password',
                      onPressed: () => setState(
                        () => _obscureConfirm = !_obscureConfirm,
                      ),
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: _validateConfirmPassword,
                  onFieldSubmitted: (_) {
                    if (!_isSaving) {
                      _submit();
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textInverse,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Saving...' : 'Save password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

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
