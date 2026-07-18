import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/mock_driver_data.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../emergency/data/driver_request_api.dart';
import '../trips/data/driver_trip_api.dart';

class FuelScreen extends ConsumerStatefulWidget {
  const FuelScreen({super.key});

  @override
  ConsumerState<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends ConsumerState<FuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fuelAmountController = TextEditingController(text: '42');
  final _billAmountController = TextEditingController(text: '4200');
  final _fuelStationController = TextEditingController(
    text: 'HP Fuel Station, Tumakuru Road',
  );
  final _notesController = TextEditingController();

  DriverTripMock? _selectedTrip;
  var _availableTrips = <DriverTripMock>[];
  bool _hasBillUpload = false;
  String? _billPath;
  Uint8List? _billBytes;
  String? _billName;
  bool _isSubmitting = false;
  var _status = _FuelRequestStatus.draft;
  var _isLoadingTrips = true;
  String? _loadError;

  DriverTripApi get _tripApi => ref.read(driverTripApiProvider);
  DriverRequestApi get _requestApi => ref.read(driverRequestApiProvider);
  final _imagePicker = ImagePicker();

  bool get _isLocked => _isSubmitting || _status == _FuelRequestStatus.pending;

  bool get _canSubmit {
    return _selectedTrip != null &&
        _hasBillUpload &&
        !_isSubmitting &&
        _status != _FuelRequestStatus.pending;
  }

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  @override
  void dispose() {
    _fuelAmountController.dispose();
    _billAmountController.dispose();
    _fuelStationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoadingTrips = true;
      _loadError = null;
    });

    try {
      final result = await _tripApi.listTrips(limit: 50);
      if (!mounted) {
        return;
      }
      final trips = result.trips
          .where(
            (trip) => ![
              'rejected',
              'cancelled',
              'completed',
            ].contains(trip.assignmentStatus),
          )
          .map((trip) => trip.toTripCardModel())
          .toList();
      setState(() {
        _availableTrips = trips;
        _selectedTrip = trips.isNotEmpty ? trips.first : null;
        _isLoadingTrips = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = error.message;
        _isLoadingTrips = false;
      });
    }
  }

  String? _validateFuelAmount(String? value) {
    final input = value?.trim() ?? '';
    final amount = double.tryParse(input);
    if (input.isEmpty) {
      return 'Enter fuel amount';
    }
    if (amount == null) {
      return 'Enter a valid litre amount';
    }
    if (amount <= 0) {
      return 'Fuel amount must be greater than zero';
    }
    if (amount > 500) {
      return 'Fuel amount must be 500 L or less';
    }
    return null;
  }

  String? _validateBillAmount(String? value) {
    final input = value?.trim() ?? '';
    final amount = double.tryParse(input);
    if (input.isEmpty) {
      return 'Enter bill amount';
    }
    if (amount == null) {
      return 'Enter a valid bill amount';
    }
    if (amount <= 0) {
      return 'Bill amount must be greater than zero';
    }
    if (amount > 100000) {
      return 'Bill amount must be INR 100,000 or less';
    }
    return null;
  }

  String? _validateFuelStation(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter fuel station';
    }
    if (input.length < 4) {
      return 'Enter a clear fuel station name';
    }
    if (input.length > 90) {
      return 'Fuel station must be 90 characters or fewer';
    }
    return null;
  }

  String? _validateNotes(String? value) {
    final input = value?.trim() ?? '';
    if (input.length > 220) {
      return 'Notes must be 220 characters or fewer';
    }
    return null;
  }

  Future<void> _attachBill() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
      );
      if (photo == null || !mounted) {
        return;
      }
      final bytes = await photo.readAsBytes();
      if (!mounted) {
        return;
      }
      final fileName = _xFileName(photo);
      setState(() {
        _billPath = fileName;
        _billBytes = bytes;
        _billName = fileName;
        _hasBillUpload = true;
        if (_status == _FuelRequestStatus.needsBill) {
          _status = _FuelRequestStatus.draft;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fileName attached.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open image picker. Check app permissions.'),
        ),
      );
    }
  }

  void _removeBill() {
    setState(() {
      _hasBillUpload = false;
      _billPath = null;
      _billBytes = null;
      _billName = null;
      _status = _FuelRequestStatus.needsBill;
    });
  }

  Future<void> _submitFuelRequest() async {
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState!.validate();

    if (!_hasBillUpload) {
      setState(() => _status = _FuelRequestStatus.needsBill);
    }

    if (!isValid || !_canSubmit || _billBytes == null || _billName == null) {
      return;
    }
    if (_selectedTrip?.assignmentId == null &&
        _selectedTrip?.vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a backend trip or vehicle.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final fuelRequest = await _requestApi.createFuelRequest(
        fuelAmountLiters: double.parse(_fuelAmountController.text.trim()),
        billAmount: double.parse(_billAmountController.text.trim()),
        fuelStation: _fuelStationController.text,
        notes: _notesController.text,
        assignmentId: _selectedTrip?.assignmentId,
        vehicleId: _selectedTrip?.vehicleId,
      );
      await _requestApi.uploadFuelBill(
        fuelRequestId: fuelRequest.id,
        billBytes: _billBytes!,
        billName: _billName!,
        notes: _notesController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _status = _FuelRequestStatus.pending;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fuel request ${fuelRequest.requestCode} submitted.'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _createAnotherRequest() {
    setState(() {
      _selectedTrip = _availableTrips.isNotEmpty ? _availableTrips.first : null;
      _fuelAmountController.text = '42';
      _billAmountController.text = '4200';
      _fuelStationController.text = 'HP Fuel Station, Tumakuru Road';
      _notesController.clear();
      _hasBillUpload = false;
      _billPath = null;
      _billBytes = null;
      _billName = null;
      _status = _FuelRequestStatus.draft;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppScaffold(
      title: 'Fuel request',
      subtitle: 'Optional fuel reimbursement request for driver trips.',
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FuelHeader(status: _status),
            const SizedBox(height: AppSpacing.lg),
            if (_isLoadingTrips) ...[
              const LoadingWidget(message: 'Loading trips for fuel request'),
              const SizedBox(height: AppSpacing.lg),
            ] else if (_loadError != null) ...[
              ErrorStateWidget(
                title: 'Could not load trips',
                message: _loadError!,
                onRetry: _loadTrips,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _RequestStatusCard(
              status: _status,
              selectedTrip: _selectedTrip,
              fuelAmount: _fuelAmountController.text.trim(),
              billAmount: _billAmountController.text.trim(),
              hasBillUpload: _hasBillUpload,
              billPath: _billPath,
              onNewRequest: _status == _FuelRequestStatus.pending
                  ? _createAnotherRequest
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            _TripSelector(
              trips: _availableTrips,
              selectedTrip: _selectedTrip,
              isLocked: _isLocked,
              onChanged: (value) => setState(() => _selectedTrip = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            _FuelAmountFields(
              fuelAmountController: _fuelAmountController,
              billAmountController: _billAmountController,
              stationController: _fuelStationController,
              isLocked: _isLocked,
              onChanged: (_) => setState(() {}),
              fuelValidator: _validateFuelAmount,
              billValidator: _validateBillAmount,
              stationValidator: _validateFuelStation,
            ),
            const SizedBox(height: AppSpacing.lg),
            _BillUploadCard(
              hasBillUpload: _hasBillUpload,
              billPath: _billPath,
              isLocked: _isLocked,
              onAttachBill: _attachBill,
              onRemoveBill: _removeBill,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _notesController,
              enabled: !_isLocked,
              maxLines: 4,
              maxLength: 220,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Add odometer reading, route delay, or pump notes',
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
              validator: _validateNotes,
            ),
            const SizedBox(height: AppSpacing.md),
            _SubmitFuelRequestButton(
              status: _status,
              isLoading: _isSubmitting,
              canSubmit: _canSubmit,
              onPressed: _submitFuelRequest,
            ),
          ],
        ),
      ),
    );
  }
}

class _FuelHeader extends StatelessWidget {
  const _FuelHeader({required this.status});

  final _FuelRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final isPending = status == _FuelRequestStatus.pending;
    final color = isPending ? AppColors.success : AppColors.primaryNavy;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.textInverse.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Icon(
              isPending
                  ? Icons.receipt_long_rounded
                  : Icons.local_gas_station_rounded,
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
                  isPending ? 'Fuel request submitted' : 'Fuel reimbursement',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  isPending
                      ? 'The request is waiting for fleet desk review.'
                      : 'Attach bill details for optional trip fuel support.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.surfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(label: status.label, tone: status.tone),
        ],
      ),
    );
  }
}

class _RequestStatusCard extends StatelessWidget {
  const _RequestStatusCard({
    required this.status,
    required this.selectedTrip,
    required this.fuelAmount,
    required this.billAmount,
    required this.hasBillUpload,
    required this.billPath,
    required this.onNewRequest,
  });

  final _FuelRequestStatus status;
  final DriverTripMock? selectedTrip;
  final String fuelAmount;
  final String billAmount;
  final bool hasBillUpload;
  final String? billPath;
  final VoidCallback? onNewRequest;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Icon(status.icon, color: status.color),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        status.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                StatusBadge(label: status.label, tone: status.tone),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 560;
                final items = [
                  _StatusMetric(
                    icon: Icons.route_outlined,
                    label: 'Trip',
                    value: selectedTrip?.id ?? 'Not selected',
                  ),
                  _StatusMetric(
                    icon: Icons.local_gas_station_outlined,
                    label: 'Fuel',
                    value: fuelAmount.isEmpty ? '0 L' : '$fuelAmount L',
                  ),
                  _StatusMetric(
                    icon: Icons.payments_outlined,
                    label: 'Bill',
                    value: billAmount.isEmpty ? 'INR 0' : 'INR $billAmount',
                  ),
                  _StatusMetric(
                    icon: Icons.upload_file_outlined,
                    label: 'Bill upload',
                    value: hasBillUpload ? 'Attached' : 'Required',
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: [
                      for (var index = 0; index < items.length; index++) ...[
                        Expanded(child: items[index]),
                        if (index != items.length - 1)
                          const SizedBox(width: AppSpacing.sm),
                      ],
                    ],
                  );
                }

                return Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      items[index],
                      if (index != items.length - 1)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                );
              },
            ),
            if (onNewRequest != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: onNewRequest,
                icon: const Icon(Icons.add_card_outlined),
                label: const Text('Create another fuel request'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusMetric extends StatelessWidget {
  const _StatusMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryBlue),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(value, style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripSelector extends StatelessWidget {
  const _TripSelector({
    required this.trips,
    required this.selectedTrip,
    required this.isLocked,
    required this.onChanged,
  });

  final List<DriverTripMock> trips;
  final DriverTripMock? selectedTrip;
  final bool isLocked;
  final ValueChanged<DriverTripMock?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<DriverTripMock>(
              initialValue: selectedTrip,
              decoration: const InputDecoration(
                labelText: 'Trip',
                prefixIcon: Icon(Icons.local_shipping_outlined),
              ),
              items: [
                for (final trip in trips)
                  DropdownMenuItem(
                    value: trip,
                    child: Text('${trip.id} - ${trip.status}'),
                  ),
              ],
              onChanged: isLocked ? null : onChanged,
              validator: (value) => value == null ? 'Select trip' : null,
            ),
            if (selectedTrip != null) ...[
              const SizedBox(height: AppSpacing.md),
              _TripPreview(trip: selectedTrip!),
            ],
          ],
        ),
      ),
    );
  }
}

class _TripPreview extends StatelessWidget {
  const _TripPreview({required this.trip});

  final DriverTripMock trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${trip.package} - ${trip.vehicle}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              StatusBadge.fromTripStatus(trip.status),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          _InfoLine(
            icon: Icons.my_location_rounded,
            label: 'Pickup',
            value: trip.pickup,
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoLine(
            icon: Icons.location_on_rounded,
            label: 'Delivery',
            value: trip.delivery,
          ),
        ],
      ),
    );
  }
}

class _FuelAmountFields extends StatelessWidget {
  const _FuelAmountFields({
    required this.fuelAmountController,
    required this.billAmountController,
    required this.stationController,
    required this.isLocked,
    required this.onChanged,
    required this.fuelValidator,
    required this.billValidator,
    required this.stationValidator,
  });

  final TextEditingController fuelAmountController;
  final TextEditingController billAmountController;
  final TextEditingController stationController;
  final bool isLocked;
  final ValueChanged<String> onChanged;
  final String? Function(String? value) fuelValidator;
  final String? Function(String? value) billValidator;
  final String? Function(String? value) stationValidator;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 560;
                final fuelField = TextFormField(
                  controller: fuelAmountController,
                  enabled: !isLocked,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Fuel amount',
                    hintText: 'Litres',
                    suffixText: 'L',
                    prefixIcon: Icon(Icons.local_gas_station_outlined),
                  ),
                  validator: fuelValidator,
                  onChanged: onChanged,
                );
                final billField = TextFormField(
                  controller: billAmountController,
                  enabled: !isLocked,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Bill amount',
                    hintText: 'Amount',
                    prefixText: 'INR ',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: billValidator,
                  onChanged: onChanged,
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: fuelField),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: billField),
                    ],
                  );
                }

                return Column(
                  children: [
                    fuelField,
                    const SizedBox(height: AppSpacing.md),
                    billField,
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: stationController,
              enabled: !isLocked,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Fuel station',
                hintText: 'Station name and area',
                prefixIcon: Icon(Icons.store_mall_directory_outlined),
              ),
              validator: stationValidator,
            ),
          ],
        ),
      ),
    );
  }
}

class _BillUploadCard extends StatelessWidget {
  const _BillUploadCard({
    required this.hasBillUpload,
    required this.billPath,
    required this.isLocked,
    required this.onAttachBill,
    required this.onRemoveBill,
  });

  final bool hasBillUpload;
  final String? billPath;
  final bool isLocked;
  final VoidCallback onAttachBill;
  final VoidCallback onRemoveBill;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Bill upload',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusBadge(
                  label: hasBillUpload ? 'Uploaded' : 'Required',
                  tone: hasBillUpload
                      ? StatusBadgeTone.completed
                      : StatusBadgeTone.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 154,
              width: double.infinity,
              decoration: BoxDecoration(
                color: hasBillUpload
                    ? AppColors.success.withValues(alpha: 0.08)
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(
                  color: hasBillUpload
                      ? AppColors.success.withValues(alpha: 0.35)
                      : AppColors.border,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasBillUpload
                          ? Icons.check_circle_rounded
                          : Icons.upload_file_outlined,
                      color: hasBillUpload
                          ? AppColors.success
                          : AppColors.textSecondary,
                      size: 38,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      hasBillUpload
                          ? _fileName(billPath ?? '')
                          : 'No fuel bill uploaded',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Upload a receipt image from this device.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLocked ? null : onAttachBill,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(hasBillUpload ? 'Replace bill' : 'Upload bill'),
                  ),
                ),
                if (hasBillUpload) ...[
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    tooltip: 'Remove bill',
                    onPressed: isLocked ? null : onRemoveBill,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitFuelRequestButton extends StatelessWidget {
  const _SubmitFuelRequestButton({
    required this.status,
    required this.isLoading,
    required this.canSubmit,
    required this.onPressed,
  });

  final _FuelRequestStatus status;
  final bool isLoading;
  final bool canSubmit;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isPending = status == _FuelRequestStatus.pending;

    return ElevatedButton.icon(
      onPressed: isPending ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textInverse,
              ),
            )
          : Icon(isPending ? Icons.check_rounded : Icons.send_rounded),
      label: Text(
        isPending
            ? 'Request submitted'
            : isLoading
            ? 'Submitting request...'
            : canSubmit
            ? 'Submit fuel request'
            : 'Complete fuel request',
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

String _fileName(String path) {
  final parts = path.split(RegExp(r'[\\/]+'));
  return parts.isEmpty || parts.last.isEmpty ? 'Bill attached' : parts.last;
}

String _xFileName(XFile file) {
  final name = file.name.trim();
  if (name.isNotEmpty) {
    return name;
  }
  return _fileName(file.path);
}

enum _FuelRequestStatus {
  draft(
    'Draft',
    'Complete the form and upload the bill to request review.',
    Icons.edit_note_rounded,
    AppColors.primaryBlue,
    StatusBadgeTone.neutral,
  ),
  needsBill(
    'Bill required',
    'Upload a fuel bill before submitting this request.',
    Icons.receipt_long_outlined,
    AppColors.warning,
    StatusBadgeTone.warning,
  ),
  pending(
    'Pending review',
    'Fleet desk review is pending.',
    Icons.hourglass_top_rounded,
    AppColors.success,
    StatusBadgeTone.completed,
  );

  const _FuelRequestStatus(
    this.label,
    this.description,
    this.icon,
    this.color,
    this.tone,
  );

  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final StatusBadgeTone tone;
}
