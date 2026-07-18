import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import 'data/customer_profile_api.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadProfile);
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await ref.read(customerProfileApiProvider).getProfile();
      if (!mounted) {
        return;
      }
      _applyProfile(profile);
      setState(() => _isLoading = false);
    } on ApiException catch (error) {
      _setLoadError(error.message);
    } catch (_) {
      _setLoadError('Unable to load customer profile.');
    }
  }

  void _setLoadError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  void _applyProfile(CustomerProfile profile) {
    final digits = profile.phone.replaceAll(RegExp(r'\D'), '');
    _nameController.text = profile.displayName;
    _emailController.text = profile.email;
    _phoneController.text = digits.length > 10
        ? digits.substring(digits.length - 10)
        : digits;
    _addressController.text = profile.address.addressLine1 ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter full name';
    }
    if (input.length < 3) {
      return 'Name must be at least 3 characters';
    }
    if (!RegExp(r"^[A-Za-z][A-Za-z .'-]*$").hasMatch(input)) {
      return 'Use a valid customer name';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter phone number';
    }
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(input)) {
      return 'Enter a valid 10 digit Indian mobile number';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter address';
    }
    if (input.length < 12) {
      return 'Address must be at least 12 characters';
    }
    return null;
  }

  Future<void> _saveProfile() async {
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
          .read(customerProfileApiProvider)
          .updateProfile(
            CustomerProfileUpdateRequest(
              name: _nameController.text,
              phone: '+91${_phoneController.text.trim()}',
              addressLine1: _addressController.text,
              country: 'India',
            ),
          );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = error.message;
      });
      return;
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = 'Unable to update profile right now.';
      });
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully.')),
    );
    context.go(AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppScaffold(
      title: 'Edit profile',
      subtitle: 'Update customer contact details from your backend profile.',
      bottomNavigationIndex: 3,
      body: _isLoading
          ? const LoadingWidget(message: 'Loading profile details')
          : _errorMessage != null && _nameController.text.isEmpty
          ? ErrorStateWidget(
              title: 'Profile unavailable',
              message: _errorMessage!,
              onRetry: _loadProfile,
            )
          : Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _EditProfileHeader(),
                  const SizedBox(height: AppSpacing.lg),
                  if (_errorMessage != null) ...[
                    _EditProfileErrorBanner(message: _errorMessage!),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            enabled: !_isSaving,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: _validateName,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _emailController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                              suffixIcon: _VerifiedSuffix(),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _phoneController,
                            enabled: !_isSaving,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              prefixIcon: Icon(Icons.phone_outlined),
                              prefixText: '+91 ',
                            ),
                            validator: _validatePhone,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _addressController,
                            enabled: !_isSaving,
                            minLines: 3,
                            maxLines: 4,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            validator: _validateAddress,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.textInverse,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Saving...' : 'Save changes'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _EditProfileHeader extends StatelessWidget {
  const _EditProfileHeader();

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
              Icons.manage_accounts_outlined,
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
                  'Customer profile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Email is verified and managed by authentication.',
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

class _EditProfileErrorBanner extends StatelessWidget {
  const _EditProfileErrorBanner({required this.message});

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

class _VerifiedSuffix extends StatelessWidget {
  const _VerifiedSuffix();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_rounded,
            color: AppColors.success,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            'Verified',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
