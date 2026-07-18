import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/mock_admin_data.dart';

enum DriverFormMode { create, edit }

class DriverFormResult {
  const DriverFormResult({
    required this.name,
    required this.username,
    required this.generatedPassword,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.address,
    required this.availabilityStatus,
    required this.activeStatus,
  });

  final String name;
  final String username;
  final String generatedPassword;
  final String email;
  final String phone;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final String address;
  final String availabilityStatus;
  final String activeStatus;
}

Future<DriverFormResult?> showDriverFormDialog({
  required BuildContext context,
  required DriverFormMode mode,
  AdminDriverManagementMock? initialDriver,
}) {
  return showDialog<DriverFormResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return _DriverFormDialog(mode: mode, initialDriver: initialDriver);
    },
  );
}

class _DriverFormDialog extends StatefulWidget {
  const _DriverFormDialog({required this.mode, this.initialDriver});

  final DriverFormMode mode;
  final AdminDriverManagementMock? initialDriver;

  @override
  State<_DriverFormDialog> createState() => _DriverFormDialogState();
}

class _DriverFormDialogState extends State<_DriverFormDialog> {
  static const _activeStatusOptions = ['Active', 'Inactive', 'Suspended'];
  static const _availabilityStatusOptions = [
    'Available',
    'On Trip',
    'Offline',
    'On Leave',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _generatedPasswordController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _licenseNumberController;
  late final TextEditingController _licenseExpiryController;
  late final TextEditingController _addressController;

  late String _activeStatus;
  late String _availabilityStatus;
  late DateTime _licenseExpiry;
  bool _isSubmitting = false;

  bool get _isEditing => widget.mode == DriverFormMode.edit;

  @override
  void initState() {
    super.initState();

    final initialDriver = widget.initialDriver;
    final defaultExpiry = DateUtils.dateOnly(
      DateTime.now().add(const Duration(days: 365)),
    );

    _nameController = TextEditingController(text: initialDriver?.name ?? '');
    _usernameController = TextEditingController(
      text: initialDriver?.username ?? '',
    );
    _generatedPasswordController = TextEditingController(
      text: initialDriver?.temporaryPassword ?? _generatePassword(),
    );
    _emailController = TextEditingController(text: initialDriver?.email ?? '');
    _phoneController = TextEditingController(text: initialDriver?.phone ?? '');
    _licenseNumberController = TextEditingController(
      text: initialDriver?.licenseNumber ?? '',
    );
    _licenseExpiry = initialDriver?.licenseExpiry ?? defaultExpiry;
    _licenseExpiryController = TextEditingController();
    _addressController = TextEditingController(
      text: initialDriver?.address ?? '',
    );
    _activeStatus = initialDriver?.status ?? _activeStatusOptions.first;
    _availabilityStatus =
        initialDriver?.availability ?? _availabilityStatusOptions.first;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _licenseExpiryController.text = _formatDate(_licenseExpiry);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _generatedPasswordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseNumberController.dispose();
    _licenseExpiryController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String get _dialogTitle => _isEditing ? 'Edit driver' : 'Create driver';

  String get _submitLabel => _isEditing ? 'Save changes' : 'Create driver';

  String _formatDate(DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _generatePassword() {
    final token =
        DateTime.now().millisecondsSinceEpoch.remainder(900000) + 100000;
    return 'Cargo@$token';
  }

  void _regeneratePassword() {
    setState(() => _generatedPasswordController.text = _generatePassword());
    _formKey.currentState?.validate();
  }

  Future<void> _pickLicenseExpiry() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDate = DateTime(today.year - 1, 1, 1);
    final lastDate = DateTime(today.year + 8, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: _licenseExpiry,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _licenseExpiry = DateUtils.dateOnly(picked);
      _licenseExpiryController.text = _formatDate(_licenseExpiry);
    });
    _formKey.currentState?.validate();
  }

  String? _validateName(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter the driver name';
    }
    if (input.length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter the username';
    }
    final pattern = RegExp(r'^[a-zA-Z0-9._-]{4,24}$');
    if (!pattern.hasMatch(input)) {
      return 'Use 4-24 letters, numbers, dots, hyphens, or underscores';
    }
    return null;
  }

  String? _validateGeneratedPassword(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Generate a password';
    }
    if (input.length < 10) {
      return 'Password must be at least 10 characters';
    }
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(input);
    final hasNumber = RegExp(r'[0-9]').hasMatch(input);
    final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(input);
    if (!hasLetter || !hasNumber || !hasSymbol) {
      return 'Password needs letters, numbers, and a symbol';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter the email address';
    }
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(input)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter the phone number';
    }

    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10 || digits.length > 13) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  String? _validateLicenseNumber(String? value) {
    final input = value?.trim().toUpperCase() ?? '';
    if (input.isEmpty) {
      return 'Enter the license number';
    }
    final pattern = RegExp(r'^[A-Z0-9-]{6,20}$');
    if (!pattern.hasMatch(input)) {
      return 'Use 6-20 uppercase letters, numbers, or hyphens';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter the driver address';
    }
    if (input.length < 10) {
      return 'Address must be at least 10 characters';
    }
    return null;
  }

  String? _validateStatusCombination(String? value) {
    final availability = value ?? _availabilityStatus;

    if (_activeStatus == 'Suspended' && availability != 'Offline') {
      return 'Suspended drivers must stay offline';
    }

    if (_activeStatus == 'Inactive' &&
        (availability == 'Available' || availability == 'On Trip')) {
      return 'Inactive drivers cannot be available or on trip';
    }

    return _validateLicenseExpiry();
  }

  String? _validateLicenseExpiry() {
    if (_activeStatus == 'Active' &&
        _licenseExpiry.isBefore(DateUtils.dateOnly(DateTime.now()))) {
      return 'Active drivers need a valid license expiry date';
    }
    return null;
  }

  void _setActiveStatus(String value) {
    setState(() {
      _activeStatus = value;
      if (_activeStatus == 'Suspended') {
        _availabilityStatus = 'Offline';
      } else if (_activeStatus == 'Inactive' &&
          (_availabilityStatus == 'Available' ||
              _availabilityStatus == 'On Trip')) {
        _availabilityStatus = 'Offline';
      }
    });
    _formKey.currentState?.validate();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      DriverFormResult(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim().toLowerCase(),
        generatedPassword: _generatedPasswordController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        phone: _phoneController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim().toUpperCase(),
        licenseExpiry: _licenseExpiry,
        address: _addressController.text.trim(),
        availabilityStatus: _availabilityStatus,
        activeStatus: _activeStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 860;

    return AlertDialog(
      title: Text(_dialogTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? 'Update driver account, license, and roster status.'
                      : 'Create a driver account with backend login credentials.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildAccountFields()),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _buildComplianceFields()),
                    ],
                  )
                else ...[
                  _buildAccountFields(),
                  const SizedBox(height: AppSpacing.md),
                  _buildComplianceFields(),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_isEditing ? Icons.save_outlined : Icons.person_add_alt_1),
          label: Text(_isSubmitting ? 'Saving...' : _submitLabel),
        ),
      ],
    );
  }

  Widget _buildAccountFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _nameController,
          enabled: !_isSubmitting,
          textInputAction: TextInputAction.next,
          validator: _validateName,
          decoration: const InputDecoration(
            labelText: 'Driver name',
            hintText: 'Amit Verma',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _usernameController,
          enabled: !_isSubmitting,
          textInputAction: TextInputAction.next,
          validator: _validateUsername,
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'amit.verma',
            prefixIcon: Icon(Icons.account_circle_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _generatedPasswordController,
          enabled: !_isSubmitting,
          readOnly: true,
          validator: _validateGeneratedPassword,
          decoration: InputDecoration(
            labelText: 'Generated password',
            prefixIcon: const Icon(Icons.key_outlined),
            suffixIcon: IconButton(
              tooltip: 'Generate password',
              onPressed: _isSubmitting ? null : _regeneratePassword,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _emailController,
          enabled: !_isSubmitting,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: _validateEmail,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'driver@cargoconnect.example',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _phoneController,
          enabled: !_isSubmitting,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: _validatePhone,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: '+91 98765 43210',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
      ],
    );
  }

  Widget _buildComplianceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _licenseNumberController,
          enabled: !_isSubmitting,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          validator: _validateLicenseNumber,
          decoration: const InputDecoration(
            labelText: 'License number',
            hintText: 'MH14TR8821',
            prefixIcon: Icon(Icons.credit_card_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _licenseExpiryController,
          readOnly: true,
          validator: (_) => _validateLicenseExpiry(),
          onTap: _isSubmitting ? null : _pickLicenseExpiry,
          decoration: InputDecoration(
            labelText: 'License expiry',
            prefixIcon: const Icon(Icons.event_available_outlined),
            suffixIcon: IconButton(
              tooltip: 'Pick expiry date',
              onPressed: _isSubmitting ? null : _pickLicenseExpiry,
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _addressController,
          enabled: !_isSubmitting,
          minLines: 2,
          maxLines: 3,
          textInputAction: TextInputAction.newline,
          validator: _validateAddress,
          decoration: const InputDecoration(
            labelText: 'Address',
            hintText: 'Driver residential or dispatch address',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: _activeStatus,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Active status',
            prefixIcon: Icon(Icons.verified_user_outlined),
          ),
          items: [
            for (final option in _activeStatusOptions)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: _isSubmitting
              ? null
              : (value) {
                  if (value != null) {
                    _setActiveStatus(value);
                  }
                },
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          key: ValueKey('availability-$_activeStatus-$_availabilityStatus'),
          initialValue: _availabilityStatus,
          isExpanded: true,
          validator: _validateStatusCombination,
          decoration: const InputDecoration(
            labelText: 'Availability status',
            prefixIcon: Icon(Icons.wifi_tethering_outlined),
          ),
          items: [
            for (final option in _availabilityStatusOptions)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: _isSubmitting
              ? null
              : (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _availabilityStatus = value);
                  _formKey.currentState?.validate();
                },
        ),
      ],
    );
  }
}
