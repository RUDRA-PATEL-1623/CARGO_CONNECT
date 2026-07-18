import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_routes.dart';

class DriverFormScreen extends StatefulWidget {
  const DriverFormScreen({super.key, this.driverId});

  final String? driverId;

  @override
  State<DriverFormScreen> createState() => _DriverFormScreenState();
}

class _DriverFormScreenState extends State<DriverFormScreen> {
  static const _availabilityOptions = [
    'Available',
    'On Trip',
    'Offline',
    'On Leave',
  ];
  static const _statusOptions = ['Active', 'Inactive', 'Suspended'];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController(text: 'Cargo@123456');
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _licenseExpiryController = TextEditingController();
  final _addressController = TextEditingController();

  String _availability = _availabilityOptions.first;
  String _status = _statusOptions.first;
  bool _isSaving = false;

  bool get _isEditing => widget.driverId?.isNotEmpty ?? false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _licenseExpiryController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? 'Driver form route validated for ${widget.driverId}. Use the driver list edit action to save through the backend.'
              : 'Driver form route validated. Use the driver list create action to save through the backend.',
        ),
      ),
    );
    context.go(AppRoutes.drivers);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormHeader(isEditing: _isEditing, driverId: widget.driverId),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 760;
                  final fieldWidth = twoColumns
                      ? (constraints.maxWidth - AppSpacing.md) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      SizedBox(
                        width: fieldWidth,
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Driver name',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: _requiredMin('driver name', 3),
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                          validator: _validateUsername,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: TextFormField(
                          controller: _passwordController,
                          enabled: !_isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Generated password',
                            prefixIcon: Icon(Icons.password_rounded),
                          ),
                          validator: _isEditing ? null : _validatePassword,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                          validator: _validateEmail,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: _validatePhone,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: TextFormField(
                          controller: _licenseController,
                          decoration: const InputDecoration(
                            labelText: 'License number',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: _requiredMin('license number', 6),
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: TextFormField(
                          controller: _licenseExpiryController,
                          decoration: const InputDecoration(
                            labelText: 'License expiry',
                            hintText: 'YYYY-MM-DD',
                            prefixIcon: Icon(Icons.event_outlined),
                          ),
                          validator: _validateDate,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownButtonFormField<String>(
                          initialValue: _availability,
                          decoration: const InputDecoration(
                            labelText: 'Availability',
                            prefixIcon: Icon(Icons.online_prediction_outlined),
                          ),
                          items: [
                            for (final value in _availabilityOptions)
                              DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                          ],
                          onChanged: _isSaving
                              ? null
                              : (value) => setState(
                                  () => _availability = value ?? _availability,
                                ),
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration: const InputDecoration(
                            labelText: 'Active status',
                            prefixIcon: Icon(Icons.verified_user_outlined),
                          ),
                          items: [
                            for (final value in _statusOptions)
                              DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                          ],
                          onChanged: _isSaving
                              ? null
                              : (value) =>
                                    setState(() => _status = value ?? _status),
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: TextFormField(
                          controller: _addressController,
                          minLines: 3,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            prefixIcon: Icon(Icons.home_outlined),
                          ),
                          validator: _requiredMin('address', 10),
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          alignment: WrapAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () => context.go(AppRoutes.drivers),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Back to drivers'),
                            ),
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
                              label: Text(_isSaving ? 'Saving...' : 'Save'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({required this.isEditing, required this.driverId});

  final bool isEditing;
  final String? driverId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Icon(
                isEditing ? Icons.edit_outlined : Icons.person_add_alt,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Edit driver' : 'Add driver',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    isEditing
                        ? 'Route ready for $driverId with validation-safe fields.'
                        : 'Route ready for a full-page driver creation flow.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

FormFieldValidator<String> _requiredMin(String label, int minLength) {
  return (value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter $label';
    }
    if (input.length < minLength) {
      return 'Use at least $minLength characters';
    }
    return null;
  };
}

String? _validateUsername(String? value) {
  final input = value?.trim() ?? '';
  if (input.isEmpty) {
    return 'Enter username';
  }
  if (!RegExp(r'^[a-zA-Z0-9._-]{4,24}$').hasMatch(input)) {
    return 'Use 4-24 letters, numbers, dots, hyphens, or underscores';
  }
  return null;
}

String? _validatePassword(String? value) {
  final input = value?.trim() ?? '';
  if (input.length < 10) {
    return 'Use at least 10 characters';
  }
  if (!RegExp(r'[A-Za-z]').hasMatch(input) ||
      !RegExp(r'\d').hasMatch(input) ||
      !RegExp(r'[^A-Za-z0-9]').hasMatch(input)) {
    return 'Use letters, numbers, and a symbol';
  }
  return null;
}

String? _validateEmail(String? value) {
  final input = value?.trim() ?? '';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(input)) {
    return 'Enter a valid email';
  }
  return null;
}

String? _validatePhone(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 10 || digits.length > 13) {
    return 'Enter a valid phone number';
  }
  return null;
}

String? _validateDate(String? value) {
  final input = value?.trim() ?? '';
  if (DateTime.tryParse(input) == null) {
    return 'Use YYYY-MM-DD';
  }
  return null;
}
