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
import '../trips/data/driver_trip_api.dart';
import 'data/driver_request_api.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  _EmergencyType? _selectedType = _EmergencyType.breakdown;
  DriverTripMock? _selectedTrip;
  var _availableTrips = <DriverTripMock>[];
  bool _hasPhotoAttachment = false;
  String? _photoAttachmentPath;
  Uint8List? _photoAttachmentBytes;
  String? _photoAttachmentName;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  var _isLoadingTrips = true;
  String? _loadError;

  DriverTripApi get _tripApi => ref.read(driverTripApiProvider);
  DriverRequestApi get _requestApi => ref.read(driverRequestApiProvider);
  final _imagePicker = ImagePicker();

  bool get _canSubmit {
    return _selectedType != null &&
        _selectedTrip != null &&
        !_isSubmitting &&
        !_isSubmitted;
  }

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
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

  String? _validateDescription(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Describe the emergency';
    }
    if (input.length < 15) {
      return 'Add at least 15 characters for dispatch context';
    }
    if (input.length > 300) {
      return 'Description must be 300 characters or fewer';
    }
    return null;
  }

  Future<void> _selectPhoto() async {
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
        _photoAttachmentPath = fileName;
        _photoAttachmentBytes = bytes;
        _photoAttachmentName = fileName;
        _hasPhotoAttachment = true;
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

  void _removePhoto() {
    setState(() {
      _hasPhotoAttachment = false;
      _photoAttachmentPath = null;
      _photoAttachmentBytes = null;
      _photoAttachmentName = null;
    });
  }

  Future<void> _submitReport() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || !_canSubmit) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _requestApi.createEmergencyReport(
        reportType: _selectedType!.reportType,
        severity: _selectedType!.severity,
        description: _descriptionController.text,
        assignmentId: _selectedTrip?.assignmentId,
        vehicleId: _selectedTrip?.vehicleId,
        locationText: _selectedTrip == null
            ? null
            : '${_selectedTrip!.pickup} to ${_selectedTrip!.delivery} corridor',
        attachmentPath: _photoAttachmentPath,
        attachmentBytes: _photoAttachmentBytes,
        attachmentName: _photoAttachmentName,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selectedType!.label} report submitted.')),
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

  void _resetReport() {
    setState(() {
      _descriptionController.clear();
      _selectedType = _EmergencyType.breakdown;
      _selectedTrip = _availableTrips.isNotEmpty ? _availableTrips.first : null;
      _hasPhotoAttachment = false;
      _photoAttachmentPath = null;
      _photoAttachmentBytes = null;
      _photoAttachmentName = null;
      _isSubmitted = false;
    });
  }

  void _showContactMessage(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action is not available in this local build.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppScaffold(
      title: 'Emergency report',
      subtitle: 'Report urgent trip, vehicle, route, or cargo incidents.',
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EmergencyHeader(isSubmitted: _isSubmitted),
            const SizedBox(height: AppSpacing.lg),
            if (_isLoadingTrips) ...[
              const LoadingWidget(message: 'Loading driver trips'),
              const SizedBox(height: AppSpacing.lg),
            ] else if (_loadError != null) ...[
              ErrorStateWidget(
                title: 'Could not load trips',
                message: _loadError!,
                onRetry: _loadTrips,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (_isSubmitted) ...[
              _SuccessStateCard(
                type: _selectedType!,
                trip: _selectedTrip!,
                onNewReport: _resetReport,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _EmergencyTypeSelector(
              selectedType: _selectedType,
              isLocked: _isSubmitting || _isSubmitted,
              onChanged: (value) => setState(() => _selectedType = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            _CurrentTripSelector(
              trips: _availableTrips,
              selectedTrip: _selectedTrip,
              isLocked: _isSubmitting || _isSubmitted,
              onChanged: (value) => setState(() => _selectedTrip = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            _LocationPlaceholder(trip: _selectedTrip),
            const SizedBox(height: AppSpacing.lg),
            _PhotoAttachmentCard(
              hasPhotoAttachment: _hasPhotoAttachment,
              attachmentPath: _photoAttachmentPath,
              isLocked: _isSubmitting || _isSubmitted,
              onAttachPhoto: _selectPhoto,
              onRemovePhoto: _removePhoto,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _descriptionController,
              enabled: !_isSubmitting && !_isSubmitted,
              maxLines: 5,
              maxLength: 300,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Emergency description',
                hintText:
                    'Explain what happened, current risk, and support needed',
                prefixIcon: Icon(Icons.report_problem_outlined),
                alignLabelWithHint: true,
              ),
              validator: _validateDescription,
            ),
            const SizedBox(height: AppSpacing.md),
            _UrgentSubmitButton(
              isSubmitted: _isSubmitted,
              isLoading: _isSubmitting,
              canSubmit: _canSubmit,
              onPressed: _submitReport,
            ),
            const SizedBox(height: AppSpacing.lg),
            _ContactAdminCard(
              onCallPressed: () => _showContactMessage('Fleet desk call'),
              onMessagePressed: () =>
                  _showContactMessage('Admin priority message'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyHeader extends StatelessWidget {
  const _EmergencyHeader({required this.isSubmitted});

  final bool isSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isSubmitted ? AppColors.success : AppColors.danger,
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
              isSubmitted
                  ? Icons.verified_rounded
                  : Icons.emergency_share_rounded,
              color: AppColors.textInverse,
              size: 34,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSubmitted ? 'Emergency logged' : 'Urgent driver support',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  isSubmitted
                      ? 'Fleet desk has the report details for review.'
                      : 'Use this for breakdowns, accidents, cargo risk, or route safety issues.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textInverse.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: isSubmitted ? 'Logged' : 'SOS',
            tone: isSubmitted
                ? StatusBadgeTone.completed
                : StatusBadgeTone.emergency,
          ),
        ],
      ),
    );
  }
}

class _SuccessStateCard extends StatelessWidget {
  const _SuccessStateCard({
    required this.type,
    required this.trip,
    required this.onNewReport,
  });

  final _EmergencyType type;
  final DriverTripMock trip;
  final VoidCallback onNewReport;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report submitted',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${type.label} report for ${trip.id} is ready for admin review.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: onNewReport,
                    icon: const Icon(Icons.add_alert_outlined),
                    label: const Text('Create another report'),
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

class _EmergencyTypeSelector extends StatelessWidget {
  const _EmergencyTypeSelector({
    required this.selectedType,
    required this.isLocked,
    required this.onChanged,
  });

  final _EmergencyType? selectedType;
  final bool isLocked;
  final ValueChanged<_EmergencyType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: DropdownButtonFormField<_EmergencyType>(
          initialValue: selectedType,
          decoration: const InputDecoration(
            labelText: 'Emergency type',
            prefixIcon: Icon(Icons.warning_amber_rounded),
          ),
          items: [
            for (final type in _EmergencyType.values)
              DropdownMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(type.icon, size: 20, color: AppColors.danger),
                    const SizedBox(width: AppSpacing.sm),
                    Text(type.label),
                  ],
                ),
              ),
          ],
          onChanged: isLocked ? null : onChanged,
          validator: (value) => value == null ? 'Select emergency type' : null,
        ),
      ),
    );
  }
}

class _CurrentTripSelector extends StatelessWidget {
  const _CurrentTripSelector({
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
                labelText: 'Current trip',
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
              validator: (value) =>
                  value == null ? 'Select current trip' : null,
            ),
            if (selectedTrip != null) ...[
              const SizedBox(height: AppSpacing.md),
              _TripRoutePreview(trip: selectedTrip!),
            ],
          ],
        ),
      ),
    );
  }
}

class _TripRoutePreview extends StatelessWidget {
  const _TripRoutePreview({required this.trip});

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

class _LocationPlaceholder extends StatelessWidget {
  const _LocationPlaceholder({required this.trip});

  final DriverTripMock? trip;

  @override
  Widget build(BuildContext context) {
    final selectedTrip = trip;
    final locationValue = selectedTrip == null
        ? 'Select a trip to preview location context.'
        : '${selectedTrip.pickup} to ${selectedTrip.delivery} corridor - GPS pending';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.gps_fixed_rounded,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const StatusBadge(
                  label: 'GPS pending',
                  tone: StatusBadgeTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoLine(
              icon: Icons.pin_drop_outlined,
              label: 'Current location',
              value: locationValue,
            ),
            const SizedBox(height: AppSpacing.sm),
            const _InfoLine(
              icon: Icons.schedule_rounded,
              label: 'Timestamp',
              value: 'Apr 28, 2026, 12:04 PM IST',
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoAttachmentCard extends StatelessWidget {
  const _PhotoAttachmentCard({
    required this.hasPhotoAttachment,
    required this.attachmentPath,
    required this.isLocked,
    required this.onAttachPhoto,
    required this.onRemovePhoto,
  });

  final bool hasPhotoAttachment;
  final String? attachmentPath;
  final bool isLocked;
  final VoidCallback onAttachPhoto;
  final VoidCallback onRemovePhoto;

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
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Photo attachment',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusBadge(
                  label: hasPhotoAttachment ? 'Attached' : 'Optional',
                  tone: hasPhotoAttachment
                      ? StatusBadgeTone.completed
                      : StatusBadgeTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: hasPhotoAttachment
                    ? AppColors.danger.withValues(alpha: 0.06)
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(
                  color: hasPhotoAttachment
                      ? AppColors.danger.withValues(alpha: 0.28)
                      : AppColors.border,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasPhotoAttachment
                          ? Icons.image_rounded
                          : Icons.image_outlined,
                      color: hasPhotoAttachment
                          ? AppColors.danger
                          : AppColors.textSecondary,
                      size: 38,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      hasPhotoAttachment
                          ? _fileName(attachmentPath ?? '')
                          : 'Attach photo placeholder',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'JPG, PNG, or WEBP image attachment.',
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
                    onPressed: isLocked ? null : onAttachPhoto,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      hasPhotoAttachment ? 'Replace photo' : 'Attach photo',
                    ),
                  ),
                ),
                if (hasPhotoAttachment) ...[
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    tooltip: 'Remove photo',
                    onPressed: isLocked ? null : onRemovePhoto,
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

String _fileName(String path) {
  final parts = path.split(RegExp(r'[\\/]+'));
  return parts.isEmpty || parts.last.isEmpty
      ? 'Attachment selected'
      : parts.last;
}

String _xFileName(XFile file) {
  final name = file.name.trim();
  if (name.isNotEmpty) {
    return name;
  }
  return _fileName(file.path);
}

class _UrgentSubmitButton extends StatelessWidget {
  const _UrgentSubmitButton({
    required this.isSubmitted,
    required this.isLoading,
    required this.canSubmit,
    required this.onPressed,
  });

  final bool isSubmitted;
  final bool isLoading;
  final bool canSubmit;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: canSubmit ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSubmitted ? AppColors.success : AppColors.danger,
        foregroundColor: AppColors.textInverse,
      ),
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textInverse,
              ),
            )
          : Icon(isSubmitted ? Icons.check_rounded : Icons.sos_rounded),
      label: Text(
        isSubmitted
            ? 'Emergency report submitted'
            : isLoading
            ? 'Submitting urgent report...'
            : 'Submit urgent report',
      ),
    );
  }
}

class _ContactAdminCard extends StatelessWidget {
  const _ContactAdminCard({
    required this.onCallPressed,
    required this.onMessagePressed,
  });

  final VoidCallback onCallPressed;
  final VoidCallback onMessagePressed;

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
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact admin',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Fleet desk priority support for emergency workflows.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCallPressed,
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Call admin'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onMessagePressed,
                    icon: const Icon(Icons.mark_unread_chat_alt_outlined),
                    label: const Text('Message'),
                  ),
                ),
              ],
            ),
          ],
        ),
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

enum _EmergencyType {
  breakdown('Vehicle breakdown', Icons.build_outlined),
  accident('Accident or collision', Icons.car_crash_outlined),
  cargoRisk('Cargo damage or theft risk', Icons.inventory_2_outlined),
  medical('Medical emergency', Icons.medical_services_outlined),
  routeSafety('Route safety issue', Icons.route_outlined);

  const _EmergencyType(this.label, this.icon);

  final String label;
  final IconData icon;

  String get reportType {
    return switch (this) {
      _EmergencyType.accident => 'accident',
      _EmergencyType.medical => 'medical',
      _EmergencyType.routeSafety => 'route_blocked',
      _EmergencyType.cargoRisk => 'security',
      _EmergencyType.breakdown => 'other',
    };
  }

  String get severity {
    return switch (this) {
      _EmergencyType.accident ||
      _EmergencyType.medical ||
      _EmergencyType.routeSafety => 'critical',
      _EmergencyType.cargoRisk => 'high',
      _EmergencyType.breakdown => 'medium',
    };
  }
}
