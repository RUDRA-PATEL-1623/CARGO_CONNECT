import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_routes.dart';

class VehicleFormScreen extends StatefulWidget {
  const VehicleFormScreen({super.key, this.vehicleId});

  final String? vehicleId;

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  static const _typeOptions = [
    'Pickup Van',
    'Mini Truck',
    '14 ft Truck',
    'Open Truck',
    'Container Truck',
    'Reefer Van',
    'Trailer',
  ];
  static const _fuelOptions = ['Diesel', 'Petrol', 'CNG', 'Electric'];
  static const _availabilityOptions = [
    'Available',
    'Busy',
    'Maintenance',
    'Out of Service',
  ];

  final _formKey = GlobalKey<FormState>();
  final _registrationController = TextEditingController();
  final _capacityController = TextEditingController();
  final _modelController = TextEditingController();
  final _insuranceExpiryController = TextEditingController();
  final _serviceDueController = TextEditingController();
  final _notesController = TextEditingController();

  String _type = _typeOptions.first;
  String _fuel = _fuelOptions.first;
  String _availability = _availabilityOptions.first;
  bool _isSaving = false;

  bool get _isEditing => widget.vehicleId?.isNotEmpty ?? false;

  @override
  void dispose() {
    _registrationController.dispose();
    _capacityController.dispose();
    _modelController.dispose();
    _insuranceExpiryController.dispose();
    _serviceDueController.dispose();
    _notesController.dispose();
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
              ? 'Vehicle form route validated for ${widget.vehicleId}. Use the vehicle list edit action to save through the backend.'
              : 'Vehicle form route validated. Use the vehicle list create action to save through the backend.',
        ),
      ),
    );
    context.go(AppRoutes.vehicles);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormHeader(isEditing: _isEditing, vehicleId: widget.vehicleId),
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
                          controller: _registrationController,
                          decoration: const InputDecoration(
                            labelText: 'Registration number',
                            prefixIcon: Icon(
                              Icons.confirmation_number_outlined,
                            ),
                          ),
                          validator: _validateRegistration,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: TextFormField(
                          controller: _capacityController,
                          decoration: const InputDecoration(
                            labelText: 'Capacity',
                            hintText: '1200 kg',
                            prefixIcon: Icon(Icons.scale_outlined),
                          ),
                          validator: _validateCapacity,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: TextFormField(
                          controller: _modelController,
                          decoration: const InputDecoration(
                            labelText: 'Model',
                            prefixIcon: Icon(Icons.local_shipping_outlined),
                          ),
                          validator: _requiredMin('model', 3),
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownButtonFormField<String>(
                          initialValue: _type,
                          decoration: const InputDecoration(
                            labelText: 'Vehicle type',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: [
                            for (final value in _typeOptions)
                              DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                          ],
                          onChanged: _isSaving
                              ? null
                              : (value) =>
                                    setState(() => _type = value ?? _type),
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownButtonFormField<String>(
                          initialValue: _fuel,
                          decoration: const InputDecoration(
                            labelText: 'Fuel type',
                            prefixIcon: Icon(Icons.local_gas_station_outlined),
                          ),
                          items: [
                            for (final value in _fuelOptions)
                              DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                          ],
                          onChanged: _isSaving
                              ? null
                              : (value) =>
                                    setState(() => _fuel = value ?? _fuel),
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownButtonFormField<String>(
                          initialValue: _availability,
                          decoration: const InputDecoration(
                            labelText: 'Availability',
                            prefixIcon: Icon(Icons.verified_outlined),
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
                        child: TextFormField(
                          controller: _insuranceExpiryController,
                          decoration: const InputDecoration(
                            labelText: 'Insurance expiry',
                            hintText: 'YYYY-MM-DD',
                            prefixIcon: Icon(Icons.policy_outlined),
                          ),
                          validator: _validateDate,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: TextFormField(
                          controller: _serviceDueController,
                          decoration: const InputDecoration(
                            labelText: 'Service due date',
                            hintText: 'YYYY-MM-DD',
                            prefixIcon: Icon(Icons.build_outlined),
                          ),
                          validator: _validateDate,
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: TextFormField(
                          controller: _notesController,
                          minLines: 3,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                          validator: _requiredMin('notes', 10),
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
                                  : () => context.go(AppRoutes.vehicles),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Back to vehicles'),
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
  const _FormHeader({required this.isEditing, required this.vehicleId});

  final bool isEditing;
  final String? vehicleId;

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
                isEditing ? Icons.edit_outlined : Icons.add_road_outlined,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Edit vehicle' : 'Add vehicle',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    isEditing
                        ? 'Route ready for $vehicleId with validation-safe fields.'
                        : 'Route ready for a full-page vehicle creation flow.',
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

String? _validateRegistration(String? value) {
  final input = value?.trim().toUpperCase() ?? '';
  if (!RegExp(r'^[A-Z0-9 -]{6,20}$').hasMatch(input)) {
    return 'Use 6-20 letters, numbers, spaces, or hyphens';
  }
  return null;
}

String? _validateCapacity(String? value) {
  final input = value?.trim() ?? '';
  final number = double.tryParse(
    RegExp(r'\d+(\.\d+)?').firstMatch(input)?.group(0) ?? '',
  );
  if (number == null || number <= 0) {
    return 'Enter a valid capacity';
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
