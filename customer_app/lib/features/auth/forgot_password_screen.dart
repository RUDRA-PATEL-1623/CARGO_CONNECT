import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';
import 'data/customer_auth_api.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController(
    text: 'aarav.mehta@example.com',
  );

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  String? _validateDestination(String? value) {
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
          .requestPasswordReset(identifier: _destinationController.text);

      if (!mounted) {
        return;
      }

      final developmentOtp = result.developmentOtp;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            developmentOtp == null
                ? 'Reset OTP prepared.'
                : 'Reset OTP prepared. Development OTP: $developmentOtp',
          ),
        ),
      );
      context.go(
        Uri(
          path: AppRoutes.otpVerification,
          queryParameters: {
            'destination': result.destination.isEmpty
                ? _destinationController.text.trim()
                : result.destination,
            'next': 'create-password',
            'edit': 'forgot-password',
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
            'Unable to start password reset. Please try again in a moment.';
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
      title: 'Forgot password',
      subtitle: 'Enter your registered customer email or mobile number.',
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ResetHeader(),
            const SizedBox(height: AppSpacing.lg),
            if (_errorMessage != null) ...[
              _ForgotPasswordErrorBanner(message: _errorMessage!),
              const SizedBox(height: AppSpacing.md),
            ],
            TextFormField(
              controller: _destinationController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_isSubmitting) {
                  _submit();
                }
              },
              decoration: const InputDecoration(
                labelText: 'Email or mobile number',
                prefixIcon: Icon(Icons.person_search_outlined),
              ),
              validator: _validateDestination,
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
                  : const Icon(Icons.mark_email_read_outlined),
              label: Text(_isSubmitting ? 'Sending OTP...' : 'Send OTP'),
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

class _ResetHeader extends StatelessWidget {
  const _ResetHeader();

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
              Icons.lock_reset_rounded,
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
                  'Reset securely',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'We will route you through OTP verification before password setup.',
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

class _ForgotPasswordErrorBanner extends StatelessWidget {
  const _ForgotPasswordErrorBanner({required this.message});

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
