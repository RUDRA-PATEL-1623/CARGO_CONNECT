import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/mock_admin_data.dart';

enum VehicleFormMode { create, edit }

class VehicleFormResult {
  const VehicleFormResult({
    required this.registration,
    required this.type,
    required this.capacity,
    required this.model,
    required this.fuelType,
    required this.insuranceExpiry,
    required this.serviceDue,
    required this.availability,
    required this.notes,
  });

  final String registration;
  final String type;
  final String capacity;
  final String model;
  final String fuelType;
  final DateTime insuranceExpiry;
  final DateTime serviceDue;
  final String availability;
  final String notes;
}

Future<VehicleFormResult?> showVehicleFormDialog({
  required BuildContext context,
  required VehicleFormMode mode,
  AdminVehicleManagementMock? initialVehicle,
}) {
  return showDialog<VehicleFormResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return _VehicleFormDialog(mode: mode, initialVehicle: initialVehicle);
    },
  );
}

class _VehicleFormDialog extends StatefulWidget {
  const _VehicleFormDialog({required this.mode, this.initialVehicle});

  final VehicleFormMode mode;
  final AdminVehicleManagementMock? initialVehicle;

  @override
  State<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<_VehicleFormDialog> {
  static const _typeOptions = [
    'Pickup Van',
    'Mini Truck',
    '14 ft Truck',
    'Open Truck',
    'Container Truck',
    'Reefer Van',
    'Trailer',
  ];
  static const _fuelTypeOptions = ['Diesel', 'Petrol', 'CNG', 'Electric'];
  static const _availabilityOptions = [
    'Available',
    'Busy',
    'Maintenance',
    'On Leave',
    'Out of Service',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _registrationController;
  late final TextEditingController _capacityController;
  late final TextEditingController _modelController;
  late final TextEditingController _insuranceExpiryController;
  late final TextEditingController _serviceDueController;
  late final TextEditingController _notesController;

  late String _type;
  late String _fuelType;
  late String _availability;
  late DateTime _insuranceExpiry;
  late DateTime _serviceDue;
  bool _isSubmitting = false;

  bool get _isEditing => widget.mode == VehicleFormMode.edit;

  bool get _hasExistingAssignment =>
      widget.initialVehicle?.assignedTrip != null &&
      widget.initialVehicle!.assignedTrip!.isNotEmpty;

  @override
  void initState() {
    super.initState();

    final initialVehicle = widget.initialVehicle;
    final today = DateUtils.dateOnly(DateTime.now());

    _registrationController = TextEditingController(
      text: initialVehicle?.registration ?? '',
    );
    _capacityController = TextEditingController(
      text: initialVehicle?.capacity ?? '',
    );
    _modelController = TextEditingController(text: initialVehicle?.model ?? '');
    _insuranceExpiry =
        initialVehicle?.insuranceExpiry ??
        DateUtils.dateOnly(today.add(const Duration(days: 365)));
    _serviceDue =
        initialVehicle?.serviceDue ??
        DateUtils.dateOnly(today.add(const Duration(days: 45)));
    _insuranceExpiryController = TextEditingController();
    _serviceDueController = TextEditingController();
    _notesController = TextEditingController(text: initialVehicle?.notes ?? '');
    _type = initialVehicle?.type ?? _typeOptions.first;
    _fuelType = initialVehicle?.fuelType ?? _fuelTypeOptions.first;
    _availability = initialVehicle?.availability ?? _availabilityOptions.first;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _insuranceExpiryController.text = _formatDate(_insuranceExpiry);
    _serviceDueController.text = _formatDate(_serviceDue);
  }

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

  String get _dialogTitle => _isEditing ? 'Edit vehicle' : 'Add vehicle';

  String get _submitLabel => _isEditing ? 'Save changes' : 'Add vehicle';

  String _formatDate(DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  Future<void> _pickDate({
    required DateTime initialDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(today.year - 1, 1, 1),
      lastDate: DateTime(today.year + 8, 12, 31),
    );

    if (picked == null) {
      return;
    }

    onPicked(DateUtils.dateOnly(picked));
    _formKey.currentState?.validate();
  }

  String? _validateRegistration(String? value) {
    final input = value?.trim().toUpperCase() ?? '';
    if (input.isEmpty) {
      return 'Enter the registration number';
    }
    final pattern = RegExp(r'^[A-Z0-9 -]{6,20}$');
    if (!pattern.hasMatch(input)) {
      return 'Use 6-20 letters, numbers, spaces, or hyphens';
    }
    return null;
  }

  String? _validateCapacity(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter the vehicle capacity';
    }
    final capacityValue = double.tryParse(
      RegExp(r'\d+(\.\d+)?').firstMatch(input)?.group(0) ?? '',
    );
    if (capacityValue == null || capacityValue <= 0) {
      return 'Enter a valid capacity';
    }
    return null;
  }

  String? _validateModel(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter the vehicle model';
    }
    if (input.length < 3) {
      return 'Model must be at least 3 characters';
    }
    return null;
  }

  String? _validateInsuranceExpiry() {
    if (_insuranceExpiry.isBefore(DateUtils.dateOnly(DateTime.now()))) {
      return 'Insurance expiry must be today or later';
    }
    return null;
  }

  String? _validateServiceDue() {
    if (_availability == 'Available' &&
        _serviceDue.isBefore(DateUtils.dateOnly(DateTime.now()))) {
      return 'Available vehicles need a valid service due date';
    }
    return null;
  }

  String? _validateAvailability(String? value) {
    final availability = value ?? _availability;
    if (!_hasExistingAssignment && availability == 'Busy') {
      return 'Busy vehicles need an assigned trip';
    }
    return _validateServiceDue();
  }

  String? _validateNotes(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter vehicle notes';
    }
    if (input.length < 10) {
      return 'Notes must be at least 10 characters';
    }
    if (input.length > 240) {
      return 'Keep notes under 240 characters';
    }
    return null;
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
      VehicleFormResult(
        registration: _registrationController.text.trim().toUpperCase(),
        type: _type,
        capacity: _capacityController.text.trim(),
        model: _modelController.text.trim(),
        fuelType: _fuelType,
        insuranceExpiry: _insuranceExpiry,
        serviceDue: _serviceDue,
        availability: _availability,
        notes: _notesController.text.trim(),
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
                      ? 'Update fleet profile, compliance dates, and availability.'
                      : 'Add a fleet vehicle for dispatch planning.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildVehicleFields()),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _buildComplianceFields()),
                    ],
                  )
                else ...[
                  _buildVehicleFields(),
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
              : Icon(_isEditing ? Icons.save_outlined : Icons.add_rounded),
          label: Text(_isSubmitting ? 'Saving...' : _submitLabel),
        ),
      ],
    );
  }

  Widget _buildVehicleFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _registrationController,
          enabled: !_isSubmitting,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          validator: _validateRegistration,
          decoration: const InputDecoration(
            labelText: 'Registration number',
            hintText: 'MH 04 HX 2210',
            prefixIcon: Icon(Icons.confirmation_number_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: _type,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Type',
            prefixIcon: Icon(Icons.local_shipping_outlined),
          ),
          items: [
            for (final option in _typeOptions)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: _isSubmitting
              ? null
              : (value) {
                  if (value != null) {
                    setState(() => _type = value);
                  }
                },
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _capacityController,
          enabled: !_isSubmitting,
          textInputAction: TextInputAction.next,
          validator: _validateCapacity,
          decoration: const InputDecoration(
            labelText: 'Capacity',
            hintText: '2 tons',
            prefixIcon: Icon(Icons.scale_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _modelController,
          enabled: !_isSubmitting,
          textInputAction: TextInputAction.next,
          validator: _validateModel,
          decoration: const InputDecoration(
            labelText: 'Model',
            hintText: 'Tata Ace Gold',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: _fuelType,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Fuel type',
            prefixIcon: Icon(Icons.local_gas_station_outlined),
          ),
          items: [
            for (final option in _fuelTypeOptions)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: _isSubmitting
              ? null
              : (value) {
                  if (value != null) {
                    setState(() => _fuelType = value);
                  }
                },
        ),
      ],
    );
  }

  Widget _buildComplianceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _insuranceExpiryController,
          readOnly: true,
          validator: (_) => _validateInsuranceExpiry(),
          onTap: _isSubmitting
              ? null
              : () => _pickDate(
                  initialDate: _insuranceExpiry,
                  onPicked: (date) {
                    setState(() {
                      _insuranceExpiry = date;
                      _insuranceExpiryController.text = _formatDate(date);
                    });
                  },
                ),
          decoration: InputDecoration(
            labelText: 'Insurance expiry',
            prefixIcon: const Icon(Icons.policy_outlined),
            suffixIcon: IconButton(
              tooltip: 'Pick insurance expiry',
              onPressed: _isSubmitting
                  ? null
                  : () => _pickDate(
                      initialDate: _insuranceExpiry,
                      onPicked: (date) {
                        setState(() {
                          _insuranceExpiry = date;
                          _insuranceExpiryController.text = _formatDate(date);
                        });
                      },
                    ),
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _serviceDueController,
          readOnly: true,
          validator: (_) => _validateServiceDue(),
          onTap: _isSubmitting
              ? null
              : () => _pickDate(
                  initialDate: _serviceDue,
                  onPicked: (date) {
                    setState(() {
                      _serviceDue = date;
                      _serviceDueController.text = _formatDate(date);
                    });
                  },
                ),
          decoration: InputDecoration(
            labelText: 'Service due date',
            prefixIcon: const Icon(Icons.build_circle_outlined),
            suffixIcon: IconButton(
              tooltip: 'Pick service due date',
              onPressed: _isSubmitting
                  ? null
                  : () => _pickDate(
                      initialDate: _serviceDue,
                      onPicked: (date) {
                        setState(() {
                          _serviceDue = date;
                          _serviceDueController.text = _formatDate(date);
                        });
                      },
                    ),
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: _availability,
          isExpanded: true,
          validator: _validateAvailability,
          decoration: const InputDecoration(
            labelText: 'Availability',
            prefixIcon: Icon(Icons.wifi_tethering_outlined),
          ),
          items: [
            for (final option in _availabilityOptions)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: _isSubmitting
              ? null
              : (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _availability = value);
                  _formKey.currentState?.validate();
                },
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _notesController,
          enabled: !_isSubmitting,
          minLines: 3,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          validator: _validateNotes,
          decoration: const InputDecoration(
            labelText: 'Notes',
            hintText: 'Maintenance, compliance, or dispatch notes',
            prefixIcon: Icon(Icons.notes_outlined),
          ),
        ),
      ],
    );
  }
}
