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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_handlePasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_handlePasswordChanged);
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  PasswordStrength get _passwordStrength {
    return PasswordStrength.evaluate(_passwordController.text);
  }

  bool get _canConfirmPassword => _passwordStrength.isValid;

  void _handlePasswordChanged() {
    if (!_canConfirmPassword && _confirmPasswordController.text.isNotEmpty) {
      _confirmPasswordController.clear();
    }
    setState(() {});
  }

  String? _validateFullName(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter full name';
    }
    if (input.length < 3) {
      return 'Full name must be at least 3 characters';
    }
    if (!input.contains(' ')) {
      return 'Enter first and last name';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter email address';
    }
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(input)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter phone number';
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(input)) {
      return 'Enter a valid 10 digit phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final strength = PasswordStrength.evaluate(value ?? '');
    if (value == null || value.isEmpty) {
      return 'Enter password';
    }
    if (!strength.isValid) {
      return 'Use 8+ chars with upper, lower, number, and symbol';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_canConfirmPassword) {
      return 'Enter a valid password first';
    }
    final input = value ?? '';
    if (input.isEmpty) {
      return 'Confirm password';
    }
    if (input != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    final input = value?.trim() ?? '';
    if (input.isNotEmpty && input.length < 8) {
      return 'Address must be at least 8 characters';
    }
    return null;
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
      final result = await ref
          .read(customerAuthApiProvider)
          .register(
            name: _fullNameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
            acceptTerms: _acceptedTerms,
            addressLine1: _addressController.text,
          );

      if (!mounted) {
        return;
      }

      final developmentOtp = result.developmentOtp;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            developmentOtp == null
                ? 'Account created. Verify OTP next.'
                : 'Account created. Development OTP: $developmentOtp',
          ),
        ),
      );
      context.go(
        Uri(
          path: AppRoutes.otpVerification,
          queryParameters: {
            'destination': result.destination.isEmpty
                ? _emailController.text.trim()
                : result.destination,
            'next': 'home',
          },
        ).toString(),
      );
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
            'Unable to create the account right now. Please try again.';
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
      title: 'Create account',
      subtitle:
          'Set up a customer profile for bookings, tracking, delivery proofs, and invoices.',
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _RegisterHeader(),
            const SizedBox(height: AppSpacing.lg),
            if (_errorMessage != null) ...[
              _RegisterErrorBanner(message: _errorMessage!),
              const SizedBox(height: AppSpacing.md),
            ],
            TextFormField(
              controller: _fullNameController,
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: _validateFullName,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _emailController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phoneController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Phone',
                counterText: '',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: _validatePhone,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _passwordController,
              enabled: !_isSubmitting,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Password',
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
            TextFormField(
              controller: _confirmPasswordController,
              enabled: !_isSubmitting && _canConfirmPassword,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: const Icon(Icons.lock_reset_rounded),
                helperText: _canConfirmPassword
                    ? null
                    : 'Complete password requirements first',
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
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _addressController,
              enabled: !_isSubmitting,
              minLines: 2,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Address optional',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              validator: _validateAddress,
            ),
            const SizedBox(height: AppSpacing.md),
            FormField<bool>(
              initialValue: _acceptedTerms,
              validator: (value) {
                if (value != true) {
                  return 'Accept terms to continue';
                }
                return null;
              },
              builder: (field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      value: _acceptedTerms,
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              setState(() => _acceptedTerms = value ?? false);
                              field.didChange(value ?? false);
                            },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'I agree to CargoConnect terms and privacy policy',
                      ),
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.md),
                        child: Text(
                          field.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                );
              },
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
                  : const Icon(Icons.verified_user_outlined),
              label: Text(
                _isSubmitting ? 'Creating account...' : 'Create account',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => context.go(AppRoutes.auth),
                child: const Text('Already have an account? Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

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
              Icons.person_add_alt_1_rounded,
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
                  'Customer registration',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Create a secure profile before OTP verification.',
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

class _RegisterErrorBanner extends StatelessWidget {
  const _RegisterErrorBanner({required this.message});

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
