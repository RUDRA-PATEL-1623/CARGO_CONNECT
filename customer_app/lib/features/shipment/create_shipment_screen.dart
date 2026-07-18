import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';
import 'data/customer_shipment_api.dart';

class CreateShipmentScreen extends ConsumerStatefulWidget {
  const CreateShipmentScreen({
    super.key,
    this.initialPackageType,
    this.initialCategoryCode,
  });

  final String? initialPackageType;
  final String? initialCategoryCode;

  @override
  ConsumerState<CreateShipmentScreen> createState() =>
      _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends ConsumerState<CreateShipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupAddressController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _weightController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _pickupDateTimeController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _deliveryNotesController = TextEditingController();

  String? _packageType;
  String? _vehiclePreference = 'Pickup truck';
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  bool _isFragile = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const List<String> _packageTypes = [
    'Small parcel',
    'Medium goods',
    'Heavy cargo',
    'Refrigerated',
    'Fragile',
    'Urgent',
  ];

  static const List<String> _vehiclePreferences = [
    'Bike or mini van',
    'Pickup truck',
    '14 ft truck',
    '20 ft truck',
    '32 ft container',
    'Reefer vehicle',
  ];

  @override
  void initState() {
    super.initState();
    _packageType = _packageTypes.contains(widget.initialPackageType)
        ? widget.initialPackageType
        : null;
    _isFragile = _packageType == 'Fragile';
  }

  @override
  void dispose() {
    _pickupAddressController.dispose();
    _deliveryAddressController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    _pickupDateTimeController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _deliveryNotesController.dispose();
    super.dispose();
  }

  String? _validateAddress(String? value, String label) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter $label';
    }
    if (input.length < 8) {
      return '$label must be at least 8 characters';
    }
    return null;
  }

  String? _validateRequiredSelection(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Select $label';
    }
    return null;
  }

  String? _validateWeight(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter package weight';
    }
    final weight = double.tryParse(input);
    if (weight == null || weight <= 0) {
      return 'Enter a valid weight';
    }
    if (weight > 50000) {
      return 'Weight must be under 50,000 kg';
    }
    return null;
  }

  String? _validateDimensions(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return null;
    }
    if (input.length < 5) {
      return 'Enter dimensions like 120 x 80 x 90 cm';
    }
    return null;
  }

  String? _validatePickupDateTime(String? value) {
    if (_pickupDate == null || _pickupTime == null) {
      return 'Select pickup date and time';
    }
    return null;
  }

  String? _validateReceiverName(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter receiver name';
    }
    if (input.length < 3) {
      return 'Receiver name must be at least 3 characters';
    }
    return null;
  }

  String? _validateReceiverPhone(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter receiver phone';
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(input)) {
      return 'Enter a valid 10 digit phone number';
    }
    return null;
  }

  String? _validateDeliveryNotes(String? value) {
    final input = value?.trim() ?? '';
    if (input.length > 180) {
      return 'Notes must be 180 characters or fewer';
    }
    return null;
  }

  Future<void> _pickPickupDateTime() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _pickupDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (selectedDate == null || !mounted) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _pickupTime ?? TimeOfDay.now(),
    );
    if (selectedTime == null) {
      return;
    }

    setState(() {
      _pickupDate = selectedDate;
      _pickupTime = selectedTime;
      _pickupDateTimeController.text = _formatPickupDateTime(
        selectedDate,
        selectedTime,
      );
    });
  }

  String _formatPickupDateTime(DateTime date, TimeOfDay time) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$day/$month/$year, $hour:$minute $period';
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
          .read(customerShipmentApiProvider)
          .createShipment(
            ShipmentCreateRequest(
              categoryCode:
                  widget.initialCategoryCode ??
                  _categoryCodeForPackageType(_packageType),
              pickupAddress: _pickupAddressController.text,
              deliveryAddress: _deliveryAddressController.text,
              packageType: _packageType ?? 'Shipment',
              packageWeightKg: double.parse(_weightController.text.trim()),
              vehiclePreference: _vehicleCode(_vehiclePreference),
              pickupDateTime: _selectedPickupDateTime(),
              receiverName: _receiverNameController.text,
              receiverPhone: _receiverPhoneController.text,
              isFragile: _isFragile,
              dimensions: _parseDimensions(_dimensionsController.text),
              deliveryNotes: _deliveryNotesController.text,
            ),
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Shipment draft created.')));
      context.go(
        Uri(
          path: AppRoutes.shipmentSummary,
          queryParameters: {
            'shipmentId': result.shipment.id.toString(),
            'packageType': result.shipment.packageType,
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
            'Unable to create shipment right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  DateTime _selectedPickupDateTime() {
    final date = _pickupDate!;
    final time = _pickupTime!;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  ShipmentDimensions? _parseDimensions(String value) {
    final numbers = RegExp(r'\d+(\.\d+)?')
        .allMatches(value)
        .map((match) => double.tryParse(match.group(0) ?? ''))
        .whereType<double>()
        .toList();

    if (numbers.length < 3) {
      return null;
    }

    return ShipmentDimensions(
      lengthCm: numbers[0],
      widthCm: numbers[1],
      heightCm: numbers[2],
    );
  }

  String _categoryCodeForPackageType(String? packageType) {
    return switch (packageType) {
      'Small parcel' => 'small_parcel',
      'Medium goods' => 'medium_goods',
      'Heavy cargo' => 'heavy_cargo',
      'Refrigerated' => 'refrigerated',
      'Fragile' => 'fragile',
      'Urgent' => 'urgent',
      _ => 'medium_goods',
    };
  }

  String _vehicleCode(String? vehiclePreference) {
    return switch (vehiclePreference) {
      'Bike or mini van' => 'bike',
      'Pickup truck' => 'mini_truck',
      '14 ft truck' || '20 ft truck' => 'truck',
      '32 ft container' => 'heavy_truck',
      'Reefer vehicle' => 'refrigerated_truck',
      _ => 'mini_truck',
    };
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppScaffold(
      title: 'Create shipment',
      subtitle: 'Add pickup, package, and receiver details for a shipment.',
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CreateShipmentHeader(),
            const SizedBox(height: AppSpacing.lg),
            if (_errorMessage != null) ...[
              _CreateShipmentErrorBanner(message: _errorMessage!),
              const SizedBox(height: AppSpacing.md),
            ],
            _FormStepSection(
              step: '1',
              title: 'Route details',
              icon: Icons.route_rounded,
              children: [
                TextFormField(
                  controller: _pickupAddressController,
                  enabled: !_isSubmitting,
                  minLines: 2,
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Pickup address',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.my_location_rounded),
                  ),
                  validator: (value) =>
                      _validateAddress(value, 'pickup address'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _deliveryAddressController,
                  enabled: !_isSubmitting,
                  minLines: 2,
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Delivery address',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) =>
                      _validateAddress(value, 'delivery address'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _pickupDateTimeController,
                  enabled: !_isSubmitting,
                  readOnly: true,
                  onTap: _isSubmitting ? null : _pickPickupDateTime,
                  decoration: const InputDecoration(
                    labelText: 'Pickup date and time',
                    prefixIcon: Icon(Icons.event_available_rounded),
                    suffixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                  validator: _validatePickupDateTime,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _FormStepSection(
              step: '2',
              title: 'Package and vehicle',
              icon: Icons.inventory_2_rounded,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _packageType,
                  decoration: const InputDecoration(
                    labelText: 'Package type',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _packageTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _packageType = value;
                            if (value == 'Fragile') {
                              _isFragile = true;
                            }
                          });
                        },
                  validator: (value) =>
                      _validateRequiredSelection(value, 'package type'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _weightController,
                  enabled: !_isSubmitting,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Weight kg',
                    prefixIcon: Icon(Icons.scale_outlined),
                  ),
                  validator: _validateWeight,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _dimensionsController,
                  enabled: !_isSubmitting,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Dimensions optional',
                    hintText: 'L x W x H cm',
                    prefixIcon: Icon(Icons.straighten_rounded),
                  ),
                  validator: _validateDimensions,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _vehiclePreference,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle preference',
                    prefixIcon: Icon(Icons.local_shipping_outlined),
                  ),
                  items: _vehiclePreferences
                      .map(
                        (vehicle) => DropdownMenuItem(
                          value: vehicle,
                          child: Text(vehicle),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _vehiclePreference = value),
                  validator: (value) =>
                      _validateRequiredSelection(value, 'vehicle preference'),
                ),
                const SizedBox(height: AppSpacing.sm),
                CheckboxListTile(
                  value: _isFragile,
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _isFragile = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Fragile package handling required'),
                  subtitle: const Text(
                    'Adds a handling flag for delivery care.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _FormStepSection(
              step: '3',
              title: 'Receiver details',
              icon: Icons.person_pin_circle_outlined,
              children: [
                TextFormField(
                  controller: _receiverNameController,
                  enabled: !_isSubmitting,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Receiver name',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: _validateReceiverName,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _receiverPhoneController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Receiver phone',
                    counterText: '',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: _validateReceiverPhone,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _deliveryNotesController,
                  enabled: !_isSubmitting,
                  minLines: 3,
                  maxLines: 4,
                  maxLength: 180,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Delivery notes',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  validator: _validateDeliveryNotes,
                ),
              ],
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
                  : const Icon(Icons.assignment_turned_in_outlined),
              label: Text(
                _isSubmitting ? 'Creating shipment...' : 'Review summary',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateShipmentErrorBanner extends StatelessWidget {
  const _CreateShipmentErrorBanner({required this.message});

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

class _CreateShipmentHeader extends StatelessWidget {
  const _CreateShipmentHeader();

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
              Icons.add_road_rounded,
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
                  'Shipment draft',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Capture freight details before review and pricing.',
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

class _FormStepSection extends StatelessWidget {
  const _FormStepSection({
    required this.step,
    required this.title,
    required this.icon,
    required this.children,
  });

  final String step;
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Center(
                  child: Text(
                    step,
                    style: const TextStyle(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(icon, color: AppColors.primaryBlue),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}
