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
import '../trips/data/driver_trip_models.dart';
import 'data/driver_request_api.dart';

class BreakdownReportScreen extends ConsumerStatefulWidget {
  const BreakdownReportScreen({super.key});

  @override
  ConsumerState<BreakdownReportScreen> createState() =>
      _BreakdownReportScreenState();
}

class _BreakdownReportScreenState extends ConsumerState<BreakdownReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  _BreakdownVehicle? _selectedVehicle;
  var _vehicles = <_BreakdownVehicle>[];
  _BreakdownIssueType? _selectedIssueType = _BreakdownIssueType.engine;
  _BreakdownSeverity _selectedSeverity = _BreakdownSeverity.high;
  bool _hasAttachment = false;
  String? _attachmentPath;
  Uint8List? _attachmentBytes;
  String? _attachmentName;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  var _isLoadingVehicles = true;
  String? _loadError;

  DriverTripApi get _tripApi => ref.read(driverTripApiProvider);
  DriverRequestApi get _requestApi => ref.read(driverRequestApiProvider);
  final _imagePicker = ImagePicker();

  bool get _canSubmit {
    return _selectedVehicle != null &&
        _selectedIssueType != null &&
        !_isSubmitting &&
        !_isSubmitted;
  }

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoadingVehicles = true;
      _loadError = null;
    });

    try {
      final result = await _tripApi.listTrips(limit: 50);
      if (!mounted) {
        return;
      }
      final vehicles = result.trips
          .where((trip) => trip.vehicle.id > 0)
          .map(_BreakdownVehicle.fromApi)
          .toList();
      setState(() {
        _vehicles = vehicles;
        _selectedVehicle = vehicles.isNotEmpty ? vehicles.first : null;
        _isLoadingVehicles = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = error.message;
        _isLoadingVehicles = false;
      });
    }
  }

  String? _validateDescription(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Describe the breakdown';
    }
    if (input.length < 15) {
      return 'Add at least 15 characters for assistance context';
    }
    if (input.length > 280) {
      return 'Description must be 280 characters or fewer';
    }
    return null;
  }

  Future<void> _attachFile() async {
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
        _attachmentPath = fileName;
        _attachmentBytes = bytes;
        _attachmentName = fileName;
        _hasAttachment = true;
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

  void _removeFile() {
    setState(() {
      _hasAttachment = false;
      _attachmentPath = null;
      _attachmentBytes = null;
      _attachmentName = null;
    });
  }

  Future<void> _requestAssistance() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || !_canSubmit) {
      return;
    }
    if (_selectedVehicle?.vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a backend vehicle assignment.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _requestApi.createBreakdownReport(
        vehicleId: _selectedVehicle!.vehicleId!,
        assignmentId: _selectedVehicle!.assignedTrip.assignmentId,
        issueType: _selectedIssueType!.apiValue,
        severity: _selectedSeverity.apiValue,
        description: _descriptionController.text,
        locationText:
            '${_selectedVehicle!.assignedTrip.pickup} to ${_selectedVehicle!.assignedTrip.delivery} corridor',
        attachmentPath: _attachmentPath,
        attachmentBytes: _attachmentBytes,
        attachmentName: _attachmentName,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedIssueType!.label} assistance requested.'),
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

  void _resetReport() {
    setState(() {
      _descriptionController.clear();
      _selectedVehicle = _vehicles.isNotEmpty ? _vehicles.first : null;
      _selectedIssueType = _BreakdownIssueType.engine;
      _selectedSeverity = _BreakdownSeverity.high;
      _hasAttachment = false;
      _attachmentPath = null;
      _attachmentBytes = null;
      _attachmentName = null;
      _isSubmitted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppScaffold(
      title: 'Breakdown report',
      subtitle:
          'Request roadside or fleet assistance with assigned vehicle data.',
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BreakdownHeader(
              severity: _selectedSeverity,
              isSubmitted: _isSubmitted,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isLoadingVehicles) ...[
              const LoadingWidget(message: 'Loading assigned vehicles'),
              const SizedBox(height: AppSpacing.lg),
            ] else if (_loadError != null) ...[
              ErrorStateWidget(
                title: 'Could not load vehicles',
                message: _loadError!,
                onRetry: _loadVehicles,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (_isSubmitted) ...[
              _AssistanceRequestedCard(
                vehicle: _selectedVehicle!,
                issueType: _selectedIssueType!,
                onNewRequest: _resetReport,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _VehicleSelector(
              vehicles: _vehicles,
              selectedVehicle: _selectedVehicle,
              isLocked: _isSubmitting || _isSubmitted,
              onChanged: (value) => setState(() => _selectedVehicle = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            _IssueTypeSelector(
              selectedIssueType: _selectedIssueType,
              isLocked: _isSubmitting || _isSubmitted,
              onChanged: (value) => setState(() => _selectedIssueType = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SeveritySelector(
              selectedSeverity: _selectedSeverity,
              isLocked: _isSubmitting || _isSubmitted,
              onChanged: (value) => setState(() => _selectedSeverity = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            _LocationPlaceholder(vehicle: _selectedVehicle),
            const SizedBox(height: AppSpacing.lg),
            _AttachmentCard(
              hasAttachment: _hasAttachment,
              attachmentPath: _attachmentPath,
              isLocked: _isSubmitting || _isSubmitted,
              onAttach: _attachFile,
              onRemove: _removeFile,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _descriptionController,
              enabled: !_isSubmitting && !_isSubmitted,
              maxLines: 5,
              maxLength: 280,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Breakdown description',
                hintText:
                    'Describe symptoms, road condition, cargo risk, and support needed',
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
              validator: _validateDescription,
            ),
            const SizedBox(height: AppSpacing.md),
            _RequestAssistanceButton(
              severity: _selectedSeverity,
              isSubmitted: _isSubmitted,
              isLoading: _isSubmitting,
              canSubmit: _canSubmit,
              onPressed: _requestAssistance,
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownHeader extends StatelessWidget {
  const _BreakdownHeader({required this.severity, required this.isSubmitted});

  final _BreakdownSeverity severity;
  final bool isSubmitted;

  @override
  Widget build(BuildContext context) {
    final color = isSubmitted ? AppColors.success : severity.color;

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
              isSubmitted ? Icons.verified_rounded : Icons.build_rounded,
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
                  isSubmitted ? 'Assistance requested' : 'Vehicle breakdown',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  isSubmitted
                      ? 'Fleet support has the breakdown report.'
                      : 'Capture vehicle issue, severity, location, and attachment.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textInverse.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: isSubmitted ? 'Requested' : severity.label,
            tone: isSubmitted ? StatusBadgeTone.completed : severity.tone,
          ),
        ],
      ),
    );
  }
}

class _AssistanceRequestedCard extends StatelessWidget {
  const _AssistanceRequestedCard({
    required this.vehicle,
    required this.issueType,
    required this.onNewRequest,
  });

  final _BreakdownVehicle vehicle;
  final _BreakdownIssueType issueType;
  final VoidCallback onNewRequest;

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
                    'Support request logged',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${issueType.label} reported for ${vehicle.plateNumber}. Fleet assistance is queued.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: onNewRequest,
                    icon: const Icon(Icons.add_road_outlined),
                    label: const Text('Create another request'),
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

class _VehicleSelector extends StatelessWidget {
  const _VehicleSelector({
    required this.vehicles,
    required this.selectedVehicle,
    required this.isLocked,
    required this.onChanged,
  });

  final List<_BreakdownVehicle> vehicles;
  final _BreakdownVehicle? selectedVehicle;
  final bool isLocked;
  final ValueChanged<_BreakdownVehicle?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<_BreakdownVehicle>(
              initialValue: selectedVehicle,
              decoration: const InputDecoration(
                labelText: 'Vehicle',
                prefixIcon: Icon(Icons.local_shipping_outlined),
              ),
              items: [
                for (final vehicle in vehicles)
                  DropdownMenuItem(
                    value: vehicle,
                    child: Text('${vehicle.plateNumber} - ${vehicle.type}'),
                  ),
              ],
              onChanged: isLocked ? null : onChanged,
              validator: (value) => value == null ? 'Select vehicle' : null,
            ),
            if (selectedVehicle != null) ...[
              const SizedBox(height: AppSpacing.md),
              _VehiclePreview(vehicle: selectedVehicle!),
            ],
          ],
        ),
      ),
    );
  }
}

class _VehiclePreview extends StatelessWidget {
  const _VehiclePreview({required this.vehicle});

  final _BreakdownVehicle vehicle;

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
                  vehicle.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusBadge(label: vehicle.status, tone: StatusBadgeTone.warning),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          _InfoLine(
            icon: Icons.confirmation_number_outlined,
            label: 'Plate',
            value: vehicle.plateNumber,
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoLine(
            icon: Icons.assignment_outlined,
            label: 'Assigned trip',
            value: vehicle.assignedTrip.id,
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoLine(
            icon: Icons.route_outlined,
            label: 'Route',
            value:
                '${vehicle.assignedTrip.pickup} to ${vehicle.assignedTrip.delivery}',
          ),
        ],
      ),
    );
  }
}

class _IssueTypeSelector extends StatelessWidget {
  const _IssueTypeSelector({
    required this.selectedIssueType,
    required this.isLocked,
    required this.onChanged,
  });

  final _BreakdownIssueType? selectedIssueType;
  final bool isLocked;
  final ValueChanged<_BreakdownIssueType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: DropdownButtonFormField<_BreakdownIssueType>(
          initialValue: selectedIssueType,
          decoration: const InputDecoration(
            labelText: 'Issue type',
            prefixIcon: Icon(Icons.car_repair_outlined),
          ),
          items: [
            for (final issue in _BreakdownIssueType.values)
              DropdownMenuItem(
                value: issue,
                child: Row(
                  children: [
                    Icon(issue.icon, size: 20, color: AppColors.primaryBlue),
                    const SizedBox(width: AppSpacing.sm),
                    Text(issue.label),
                  ],
                ),
              ),
          ],
          onChanged: isLocked ? null : onChanged,
          validator: (value) => value == null ? 'Select issue type' : null,
        ),
      ),
    );
  }
}

class _SeveritySelector extends StatelessWidget {
  const _SeveritySelector({
    required this.selectedSeverity,
    required this.isLocked,
    required this.onChanged,
  });

  final _BreakdownSeverity selectedSeverity;
  final bool isLocked;
  final ValueChanged<_BreakdownSeverity> onChanged;

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
                  Icons.priority_high_rounded,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Severity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final severity in _BreakdownSeverity.values)
                  ChoiceChip(
                    selected: selectedSeverity == severity,
                    label: Text(severity.label),
                    avatar: Icon(severity.icon, size: 18),
                    onSelected: isLocked ? null : (_) => onChanged(severity),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              selectedSeverity.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationPlaceholder extends StatelessWidget {
  const _LocationPlaceholder({required this.vehicle});

  final _BreakdownVehicle? vehicle;

  @override
  Widget build(BuildContext context) {
    final selectedVehicle = vehicle;
    final locationText = selectedVehicle == null
        ? 'Select a vehicle to preview route location context.'
        : '${selectedVehicle.assignedTrip.pickup} to ${selectedVehicle.assignedTrip.delivery} corridor - GPS pending';

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
              value: locationText,
            ),
            const SizedBox(height: AppSpacing.sm),
            const _InfoLine(
              icon: Icons.schedule_rounded,
              label: 'Reported at',
              value: 'Apr 28, 2026, 12:18 PM IST',
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({
    required this.hasAttachment,
    required this.attachmentPath,
    required this.isLocked,
    required this.onAttach,
    required this.onRemove,
  });

  final bool hasAttachment;
  final String? attachmentPath;
  final bool isLocked;
  final VoidCallback onAttach;
  final VoidCallback onRemove;

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
                  Icons.attach_file_rounded,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Attachment',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusBadge(
                  label: hasAttachment ? 'Attached' : 'Optional',
                  tone: hasAttachment
                      ? StatusBadgeTone.completed
                      : StatusBadgeTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 148,
              width: double.infinity,
              decoration: BoxDecoration(
                color: hasAttachment
                    ? AppColors.warning.withValues(alpha: 0.08)
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(
                  color: hasAttachment
                      ? AppColors.warning.withValues(alpha: 0.35)
                      : AppColors.border,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasAttachment
                          ? Icons.image_rounded
                          : Icons.add_photo_alternate_outlined,
                      color: hasAttachment
                          ? AppColors.warning
                          : AppColors.textSecondary,
                      size: 38,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      hasAttachment
                          ? _fileName(attachmentPath ?? '')
                          : 'Attach vehicle photo placeholder',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'JPG, PNG, WEBP, or PDF attachments are accepted by the backend.',
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
                    onPressed: isLocked ? null : onAttach,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(
                      hasAttachment ? 'Replace attachment' : 'Attach file',
                    ),
                  ),
                ),
                if (hasAttachment) ...[
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    tooltip: 'Remove attachment',
                    onPressed: isLocked ? null : onRemove,
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

class _RequestAssistanceButton extends StatelessWidget {
  const _RequestAssistanceButton({
    required this.severity,
    required this.isSubmitted,
    required this.isLoading,
    required this.canSubmit,
    required this.onPressed,
  });

  final _BreakdownSeverity severity;
  final bool isSubmitted;
  final bool isLoading;
  final bool canSubmit;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: canSubmit ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSubmitted ? AppColors.success : severity.color,
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
          : Icon(
              isSubmitted ? Icons.check_rounded : Icons.support_agent_rounded,
            ),
      label: Text(
        isSubmitted
            ? 'Assistance requested'
            : isLoading
            ? 'Requesting assistance...'
            : 'Request assistance',
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

enum _BreakdownIssueType {
  engine('Engine issue', Icons.settings_outlined),
  tyre('Tyre puncture or wheel issue', Icons.album_outlined),
  battery('Battery or electrical', Icons.battery_alert_outlined),
  brake('Brake or steering', Icons.warning_amber_rounded),
  cooling('Overheating or coolant leak', Icons.thermostat_outlined);

  const _BreakdownIssueType(this.label, this.icon);

  final String label;
  final IconData icon;

  String get apiValue {
    return switch (this) {
      _BreakdownIssueType.engine => 'engine',
      _BreakdownIssueType.tyre => 'tyre',
      _BreakdownIssueType.battery => 'battery',
      _BreakdownIssueType.brake => 'electrical',
      _BreakdownIssueType.cooling => 'cooling',
    };
  }
}

enum _BreakdownSeverity {
  low(
    'Low',
    'Vehicle can move slowly; assistance can be scheduled.',
    Icons.low_priority_rounded,
    AppColors.neutral,
    StatusBadgeTone.neutral,
  ),
  medium(
    'Medium',
    'Trip is delayed; vehicle needs support before continuing.',
    Icons.priority_high_rounded,
    AppColors.warning,
    StatusBadgeTone.warning,
  ),
  high(
    'High',
    'Vehicle is stopped or cargo schedule is at immediate risk.',
    Icons.report_problem_outlined,
    AppColors.accentOrange,
    StatusBadgeTone.warning,
  ),
  critical(
    'Critical',
    'Unsafe condition or major breakdown; urgent dispatch required.',
    Icons.emergency_share_rounded,
    AppColors.danger,
    StatusBadgeTone.emergency,
  );

  const _BreakdownSeverity(
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

  String get apiValue => label.toLowerCase();
}

class _BreakdownVehicle {
  const _BreakdownVehicle({
    required this.vehicleId,
    required this.displayName,
    required this.plateNumber,
    required this.type,
    required this.status,
    required this.assignedTrip,
  });

  factory _BreakdownVehicle.fromApi(DriverTripSummary trip) {
    return _BreakdownVehicle(
      vehicleId: trip.vehicle.id,
      displayName: trip.vehicleLabel,
      plateNumber: trip.vehicle.vehicleNumber.isEmpty
          ? trip.vehicle.registrationNumber
          : trip.vehicle.vehicleNumber,
      type: trip.vehicle.type,
      status: trip.statusLabel,
      assignedTrip: trip.toTripCardModel(),
    );
  }

  final int? vehicleId;
  final String displayName;
  final String plateNumber;
  final String type;
  final String status;
  final DriverTripMock assignedTrip;
}
