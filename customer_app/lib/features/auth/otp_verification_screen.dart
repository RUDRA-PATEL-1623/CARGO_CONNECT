import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/customer_auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';
import 'data/customer_auth_api.dart';

enum OtpVerificationNext {
  home,
  createPassword;

  static OtpVerificationNext fromQuery(String? value) {
    return switch (value) {
      'create-password' ||
      'createPassword' => OtpVerificationNext.createPassword,
      _ => OtpVerificationNext.home,
    };
  }
}

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.destination,
    required this.next,
    required this.editRoute,
  });

  final String destination;
  final OtpVerificationNext next;
  final String editRoute;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  static const int _timerDuration = 30;
  static const int _otpLength = 6;

  final List<TextEditingController> _digitControllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _digitFocusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  Timer? _timer;
  int _secondsRemaining = _timerDuration;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _otpError;

  String get _otpCode {
    return _digitControllers.map((controller) => controller.text).join();
  }

  bool get _canResend =>
      _secondsRemaining == 0 && !_isVerifying && !_isResending;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _digitControllers) {
      controller.dispose();
    }
    for (final focusNode in _digitFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _timerDuration);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  void _handleDigitChanged(String value, int index) {
    if (value.isNotEmpty && index < _otpLength - 1) {
      _digitFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _digitFocusNodes[index - 1].requestFocus();
    }
    if (_otpError != null && _otpCode.length == _otpLength) {
      setState(() => _otpError = null);
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) {
      return;
    }

    setState(() {
      _isResending = true;
      _otpError = null;
    });

    try {
      final authApi = ref.read(customerAuthApiProvider);
      String? developmentOtp;

      switch (widget.next) {
        case OtpVerificationNext.home:
          final result = await authApi.resendRegistrationOtp(
            email: widget.destination,
          );
          developmentOtp = result.developmentOtp;
        case OtpVerificationNext.createPassword:
          final result = await authApi.requestPasswordReset(
            identifier: widget.destination,
          );
          developmentOtp = result.developmentOtp;
      }

      if (!mounted) {
        return;
      }

      for (final controller in _digitControllers) {
        controller.clear();
      }
      _digitFocusNodes.first.requestFocus();
      _startTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            developmentOtp == null
                ? 'OTP resent to ${widget.destination}.'
                : 'OTP resent. Development OTP: $developmentOtp',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _otpError = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _otpError = 'Unable to resend OTP. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _verifyCode() async {
    FocusScope.of(context).unfocus();
    if (_otpCode.length != _otpLength) {
      setState(() => _otpError = 'Enter the 6 digit verification code');
      return;
    }

    for (final controller in _digitControllers) {
      controller.text = controller.text.trim();
    }

    setState(() {
      _isVerifying = true;
      _otpError = null;
    });

    try {
      final authApi = ref.read(customerAuthApiProvider);

      switch (widget.next) {
        case OtpVerificationNext.home:
          await authApi.verifyRegistrationOtp(
            email: widget.destination,
            otp: _otpCode,
          );
          await ref.read(customerAuthControllerProvider).markLoggedIn();

          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP verified successfully.')),
          );
          context.go(AppRoutes.home);
        case OtpVerificationNext.createPassword:
          final result = await authApi.verifyResetOtp(
            identifier: widget.destination,
            otp: _otpCode,
          );

          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP verified. Create new password.')),
          );
          context.go(
            Uri(
              path: AppRoutes.createPassword,
              queryParameters: {
                'identifier': widget.destination,
                'resetToken': result.resetToken,
              },
            ).toString(),
          );
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _otpError = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _otpError = 'Unable to verify OTP. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _editDestination() {
    context.go(widget.editRoute);
  }

  @override
  Widget build(BuildContext context) {
    final timerText = _secondsRemaining.toString().padLeft(2, '0');

    return CommonAppScaffold(
      title: 'OTP verification',
      subtitle: 'Confirm your customer contact detail before continuing.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VerificationHeader(destination: widget.destination),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.06),
                  blurRadius: 22,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter 6 digit code',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.next == OtpVerificationNext.createPassword
                      ? 'Enter the reset code sent by CargoConnect.'
                      : 'Enter the registration code sent by CargoConnect.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                _OtpDigitRow(
                  controllers: _digitControllers,
                  focusNodes: _digitFocusNodes,
                  enabled: !_isVerifying,
                  onChanged: _handleDigitChanged,
                ),
                if (_otpError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _otpError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: _canResend
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _canResend
                            ? 'You can request a new code now'
                            : 'Resend available in 00:$timerText',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: _canResend ? () => _resendCode() : null,
                      child: Text(_isResending ? 'Sending...' : 'Resend'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: _isVerifying ? null : _verifyCode,
                  icon: _isVerifying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.textInverse,
                          ),
                        )
                      : const Icon(Icons.verified_rounded),
                  label: Text(_isVerifying ? 'Verifying...' : 'Verify OTP'),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: TextButton.icon(
                    onPressed: _isVerifying ? null : _editDestination,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit email or phone'),
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

class _VerificationHeader extends StatelessWidget {
  const _VerificationHeader({required this.destination});

  final String destination;

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
              Icons.mark_email_read_outlined,
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
                  'Code sent to',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.surfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  destination,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textInverse,
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

class _OtpDigitRow extends StatelessWidget {
  const _OtpDigitRow({
    required this.controllers,
    required this.focusNodes,
    required this.enabled,
    required this.onChanged,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool enabled;
  final void Function(String value, int index) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(controllers.length, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == controllers.length - 1 ? 0 : AppSpacing.xs,
            ),
            child: TextField(
              controller: controllers[index],
              focusNode: focusNodes[index],
              enabled: enabled,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              textInputAction: index == controllers.length - 1
                  ? TextInputAction.done
                  : TextInputAction.next,
              maxLength: 1,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppColors.primaryNavy),
              decoration: const InputDecoration(counterText: ''),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              onChanged: (value) => onChanged(value, index),
            ),
          ),
        );
      }),
    );
  }
}
