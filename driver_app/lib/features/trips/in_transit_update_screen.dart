import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/mock_driver_data.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/trip_timeline_widget.dart';
import '../emergency/data/driver_request_api.dart';
import 'data/driver_trip_api.dart';
import 'data/driver_trip_models.dart';

class InTransitUpdateScreen extends ConsumerStatefulWidget {
  const InTransitUpdateScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  ConsumerState<InTransitUpdateScreen> createState() =>
      _InTransitUpdateScreenState();
}

class _InTransitUpdateScreenState extends ConsumerState<InTransitUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _etaController = TextEditingController(text: '8:45 PM');
  final _issueNotesController = TextEditingController();

  _InTransitTripInfo? _trip;
  var _timeline = activeTripTimeline;
  var _assignmentStatus = 'in_transit';
  var _status = _InTransitStatus.inTransit;
  var _isDelayed = false;
  var _issueType = _IssueType.traffic;
  var _lastEta = '8:45 PM';
  var _isLoading = true;
  var _isSubmitting = false;
  String? _errorMessage;

  DriverTripApi get _tripApi => ref.read(driverTripApiProvider);
  DriverRequestApi get _requestApi => ref.read(driverRequestApiProvider);

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  @override
  void dispose() {
    _etaController.dispose();
    _issueNotesController.dispose();
    super.dispose();
  }

  String? _validateEta(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter an ETA';
    }
    if (input.length < 4) {
      return 'Enter a clear ETA, for example 8:45 PM';
    }
    return null;
  }

  String? _validateIssueNotes(String? value) {
    final input = value?.trim() ?? '';
    if (input.length > 180) {
      return 'Issue notes must be 180 characters or fewer';
    }
    return null;
  }

  Future<void> _loadTrip() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = await _tripApi.resolveTripDetails(widget.shipmentId);
      if (!mounted) {
        return;
      }
      setState(() {
        _trip = _InTransitTripInfo.fromApi(details.trip);
        _assignmentStatus = details.trip.assignmentStatus;
        _status = _statusFromAssignment(details.trip.assignmentStatus);
        _lastEta = details.trip.durationLabel;
        _etaController.text = _lastEta;
        _timeline = details.timeline.toTimelineMocks();
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    }
  }

  Future<void> _updateStatus(_InTransitStatus status) async {
    FocusScope.of(context).unfocus();
    final trip = _trip;
    if (trip == null) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_assignmentStatus == 'pickup_completed' &&
          (status == _InTransitStatus.inTransit ||
              status == _InTransitStatus.nearDelivery ||
              status == _InTransitStatus.delivered)) {
        final updated = await _tripApi.markInTransit(
          trip.assignmentId,
          notes: 'ETA updated to ${_etaController.text.trim()}.',
          locationText: trip.currentLocation,
          etaMinutes: _parseEtaMinutes(_etaController.text),
        );
        _assignmentStatus = updated.assignmentStatus;
      } else {
        await _tripApi.updateTripStatus(
          trip.assignmentId,
          status: 'in_transit',
          notes: status == _InTransitStatus.delivered
              ? 'Driver is ready to upload delivery proof.'
              : '${status.label} update saved with ETA ${_etaController.text.trim()}.',
          locationText: trip.currentLocation,
          etaMinutes: _parseEtaMinutes(_etaController.text),
        );
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _status = status;
        _lastEta = _etaController.text.trim();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == _InTransitStatus.delivered
                ? 'Upload delivery proof to mark delivered.'
                : '${status.label} update saved.',
          ),
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

  void _toggleDelay(bool value) {
    setState(() => _isDelayed = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Delay/report issue option enabled.'
              : 'Delay/report issue option cleared.',
        ),
      ),
    );
  }

  Future<void> _submitIssueReport() async {
    FocusScope.of(context).unfocus();
    final trip = _trip;
    if (trip == null) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _requestApi.createEmergencyReport(
        reportType: _issueType.reportType,
        severity: 'medium',
        description: _issueNotesController.text.trim().isEmpty
            ? '${_issueType.label} reported with ETA ${_etaController.text.trim()}.'
            : _issueNotesController.text.trim(),
        assignmentId: trip.assignmentId,
        vehicleId: trip.vehicleId,
        locationText: trip.currentLocation,
      );
      await _tripApi.updateTripStatus(
        trip.assignmentId,
        status: 'delayed',
        delayReason: _issueNotesController.text.trim().isEmpty
            ? _issueType.label
            : _issueNotesController.text.trim(),
        notes: 'ETA revised to ${_etaController.text.trim()}.',
        locationText: trip.currentLocation,
        etaMinutes: _parseEtaMinutes(_etaController.text),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _isDelayed = true;
        _status = _InTransitStatus.delayed;
        _lastEta = _etaController.text.trim();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${_issueType.label} reported.')));
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

  @override
  Widget build(BuildContext context) {
    final trip = _trip;

    return CommonAppScaffold(
      title: 'In-transit update',
      subtitle: 'Update live shipment progress from the driver app.',
      bottomNavigationIndex: 1,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const LoadingWidget(message: 'Loading trip progress')
            else if (_errorMessage != null)
              ErrorStateWidget(
                title: 'Could not load trip progress',
                message: _errorMessage!,
                onRetry: _loadTrip,
              )
            else if (trip != null) ...[
              _CurrentTripStatusCard(
                trip: trip,
                status: _status,
                eta: _lastEta,
                isDelayed: _isDelayed,
              ),
              const SizedBox(height: AppSpacing.lg),
              _TransitMapPlaceholder(trip: trip),
              const SizedBox(height: AppSpacing.lg),
              _EtaUpdateField(
                controller: _etaController,
                validator: _validateEta,
              ),
              const SizedBox(height: AppSpacing.lg),
              _StatusUpdateButtons(
                selectedStatus: _status,
                onStatusSelected: _updateStatus,
                isSubmitting: _isSubmitting,
              ),
              if (_status == _InTransitStatus.delivered) ...[
                const SizedBox(height: AppSpacing.lg),
                _DeliveryProofCta(
                  shipmentId: trip.shipmentId,
                  onPressed: () {
                    context.go(
                      Uri(
                        path: AppRoutes.deliveryProof,
                        queryParameters: {
                          'assignmentId': trip.assignmentId.toString(),
                          'shipmentId': trip.shipmentId,
                        },
                      ).toString(),
                    );
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _DelayIssueCard(
                isDelayed: _isDelayed,
                issueType: _issueType,
                notesController: _issueNotesController,
                notesValidator: _validateIssueNotes,
                onDelayedChanged: _toggleDelay,
                onIssueTypeChanged: (value) =>
                    setState(() => _issueType = value),
                onSubmitIssue: _submitIssueReport,
              ),
              const SizedBox(height: AppSpacing.lg),
              TripTimelineWidget(
                items: _isDelayed
                    ? _timelineFor(trip, _status, _isDelayed, _lastEta)
                    : _timeline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CurrentTripStatusCard extends StatelessWidget {
  const _CurrentTripStatusCard({
    required this.trip,
    required this.status,
    required this.eta,
    required this.isDelayed,
  });

  final _InTransitTripInfo trip;
  final _InTransitStatus status;
  final String eta;
  final bool isDelayed;

  @override
  Widget build(BuildContext context) {
    final badgeTone = isDelayed ? StatusBadgeTone.warning : status.tone;
    final badgeLabel = isDelayed ? 'Delayed' : status.label;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.textInverse.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
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
                      trip.shipmentId,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textInverse,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${trip.packageType} - ${trip.vehicle}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.surfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(label: badgeLabel, tone: badgeTone),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _HeroMetric(label: 'Current ETA', value: eta),
              _HeroMetric(label: 'Distance left', value: trip.distanceLeft),
              _HeroMetric(label: 'Next stop', value: trip.nextStop),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.textInverse.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: AppColors.textInverse.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.surfaceMuted),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textInverse),
          ),
        ],
      ),
    );
  }
}

class _TransitMapPlaceholder extends StatelessWidget {
  const _TransitMapPlaceholder({required this.trip});

  final _InTransitTripInfo trip;

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
                const Icon(Icons.map_outlined, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Live route preview',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const StatusBadge(
                  label: 'Route',
                  tone: StatusBadgeTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              height: 210,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _TransitMapPainter()),
                  ),
                  const Positioned(
                    left: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                    child: _MapChip(
                      icon: Icons.warehouse_rounded,
                      label: 'Pickup',
                    ),
                  ),
                  const Positioned(
                    right: AppSpacing.lg,
                    top: AppSpacing.lg,
                    child: _MapChip(
                      icon: Icons.flag_rounded,
                      label: 'Delivery',
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 88,
                    child: Center(
                      child: _MapChip(
                        icon: Icons.local_shipping_rounded,
                        label: trip.currentLocation,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _RouteLine(
              icon: Icons.my_location_rounded,
              label: 'From',
              value: trip.pickup,
            ),
            const SizedBox(height: AppSpacing.sm),
            _RouteLine(
              icon: Icons.location_on_rounded,
              label: 'To',
              value: trip.delivery,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryBlue),
          const SizedBox(width: AppSpacing.xxs),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({
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

class _EtaUpdateField extends StatelessWidget {
  const _EtaUpdateField({required this.controller, required this.validator});

  final TextEditingController controller;
  final String? Function(String? value) validator;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: TextFormField(
          controller: controller,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'ETA update',
            hintText: 'Example: 8:45 PM',
            prefixIcon: Icon(Icons.schedule_rounded),
          ),
          validator: validator,
        ),
      ),
    );
  }
}

class _StatusUpdateButtons extends StatelessWidget {
  const _StatusUpdateButtons({
    required this.selectedStatus,
    required this.onStatusSelected,
    required this.isSubmitting,
  });

  final _InTransitStatus selectedStatus;
  final ValueChanged<_InTransitStatus> onStatusSelected;
  final bool isSubmitting;

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
                const Icon(Icons.sync_rounded, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Update status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final status in _inTransitUpdateStatuses)
                  _StatusButton(
                    status: status,
                    isSelected: selectedStatus == status,
                    onPressed: isSubmitting
                        ? null
                        : () => onStatusSelected(status),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.status,
    required this.isSelected,
    required this.onPressed,
  });

  final _InTransitStatus status;
  final bool isSelected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      child: isSelected
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(status.icon),
              label: Text(status.label),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(status.icon),
              label: Text(status.label),
            ),
    );
  }
}

class _DeliveryProofCta extends StatelessWidget {
  const _DeliveryProofCta({required this.shipmentId, required this.onPressed});

  final String shipmentId;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: const Icon(
                Icons.assignment_turned_in_outlined,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery proof required',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Complete receiver handoff proof for $shipmentId.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Upload delivery proof',
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _DelayIssueCard extends StatelessWidget {
  const _DelayIssueCard({
    required this.isDelayed,
    required this.issueType,
    required this.notesController,
    required this.notesValidator,
    required this.onDelayedChanged,
    required this.onIssueTypeChanged,
    required this.onSubmitIssue,
  });

  final bool isDelayed;
  final _IssueType issueType;
  final TextEditingController notesController;
  final String? Function(String? value) notesValidator;
  final ValueChanged<bool> onDelayedChanged;
  final ValueChanged<_IssueType> onIssueTypeChanged;
  final VoidCallback onSubmitIssue;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: isDelayed,
              onChanged: onDelayedChanged,
              title: Text(
                'Delayed or report issue',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: const Text(
                'Use this for traffic, route, or vehicle issues.',
              ),
              secondary: const Icon(
                Icons.report_problem_outlined,
                color: AppColors.warning,
              ),
            ),
            if (isDelayed) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final issue in _IssueType.values)
                    ChoiceChip(
                      selected: issue == issueType,
                      label: Text(issue.label),
                      avatar: Icon(issue.icon, size: 18),
                      onSelected: (_) => onIssueTypeChanged(issue),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: notesController,
                maxLines: 3,
                maxLength: 180,
                decoration: const InputDecoration(
                  labelText: 'Issue notes',
                  hintText: 'Add optional details for dispatch',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
                validator: notesValidator,
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: onSubmitIssue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: AppColors.textInverse,
                ),
                icon: const Icon(Icons.send_rounded),
                label: const Text('Report issue'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TransitMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var x = 18.0; x < size.width; x += 38) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 18.0; y < size.height; y += 38) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final completedPaint = Paint()
      ..color = AppColors.success
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final pendingPaint = Paint()
      ..color = AppColors.primaryBlue.withValues(alpha: 0.4)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final completedPath = Path()
      ..moveTo(48, size.height - 46)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.74,
        size.width * 0.34,
        size.height * 0.42,
        size.width * 0.5,
        size.height * 0.5,
      );
    canvas.drawPath(completedPath, completedPaint);

    final pendingPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.5)
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.56,
        size.width * 0.72,
        size.height * 0.18,
        size.width - 48,
        48,
      );
    canvas.drawPath(pendingPath, pendingPaint);

    final truckPaint = Paint()..color = AppColors.roadYellow;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      8,
      truckPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _InTransitStatus {
  pickupCompleted(
    'Pickup Completed',
    Icons.inventory_2_rounded,
    StatusBadgeTone.pickup,
  ),
  inTransit(
    'In Transit',
    Icons.local_shipping_rounded,
    StatusBadgeTone.transit,
  ),
  nearDelivery('Near Delivery', Icons.flag_rounded, StatusBadgeTone.accepted),
  delivered('Delivered', Icons.done_all_rounded, StatusBadgeTone.delivered),
  delayed('Delayed', Icons.report_problem_outlined, StatusBadgeTone.warning);

  const _InTransitStatus(this.label, this.icon, this.tone);

  final String label;
  final IconData icon;
  final StatusBadgeTone tone;
}

enum _IssueType {
  traffic('Traffic', Icons.traffic_rounded),
  vehicle('Vehicle', Icons.build_outlined),
  route('Route issue', Icons.alt_route_rounded),
  customer('Customer unavailable', Icons.person_off_outlined);

  const _IssueType(this.label, this.icon);

  final String label;
  final IconData icon;

  String get reportType {
    return switch (this) {
      _IssueType.traffic || _IssueType.route => 'route_blocked',
      _IssueType.vehicle => 'other',
      _IssueType.customer => 'other',
    };
  }
}

class _InTransitTripInfo {
  const _InTransitTripInfo({
    required this.assignmentId,
    required this.shipmentId,
    required this.vehicleId,
    required this.packageType,
    required this.vehicle,
    required this.pickup,
    required this.delivery,
    required this.currentLocation,
    required this.nextStop,
    required this.distanceLeft,
  });

  factory _InTransitTripInfo.fromApi(DriverTripSummary trip) {
    return _InTransitTripInfo(
      assignmentId: trip.id,
      shipmentId: trip.displayId,
      vehicleId: trip.vehicle.id == 0 ? null : trip.vehicle.id,
      packageType: trip.packageInfo.type.isEmpty
          ? trip.shipment.category.name
          : trip.packageInfo.type,
      vehicle: trip.vehicleLabel,
      pickup: trip.pickupAddress,
      delivery: trip.deliveryAddress,
      currentLocation: trip.pickupAddress,
      nextStop: trip.deliveryAddress,
      distanceLeft: trip.distanceLabel,
    );
  }

  final int assignmentId;
  final String shipmentId;
  final int? vehicleId;
  final String packageType;
  final String vehicle;
  final String pickup;
  final String delivery;
  final String currentLocation;
  final String nextStop;
  final String distanceLeft;
}

const _inTransitUpdateStatuses = [
  _InTransitStatus.inTransit,
  _InTransitStatus.nearDelivery,
  _InTransitStatus.delivered,
];

_InTransitStatus _statusFromAssignment(String status) {
  return switch (status) {
    'pickup_completed' => _InTransitStatus.pickupCompleted,
    'delivered' || 'completed' => _InTransitStatus.delivered,
    _ => _InTransitStatus.inTransit,
  };
}

int? _parseEtaMinutes(String eta) {
  final hours = RegExp(r'(\d+)\s*h').firstMatch(eta.toLowerCase());
  final minutes = RegExp(r'(\d+)\s*m').firstMatch(eta.toLowerCase());
  final parsedHours = int.tryParse(hours?.group(1) ?? '') ?? 0;
  final parsedMinutes = int.tryParse(minutes?.group(1) ?? '') ?? 0;
  final total = parsedHours * 60 + parsedMinutes;
  return total > 0 ? total : null;
}

List<DriverTimelineMock> _timelineFor(
  _InTransitTripInfo trip,
  _InTransitStatus status,
  bool isDelayed,
  String eta,
) {
  final transitState = switch (status) {
    _InTransitStatus.pickupCompleted => DriverTimelineState.pending,
    _InTransitStatus.inTransit => DriverTimelineState.current,
    _InTransitStatus.nearDelivery ||
    _InTransitStatus.delivered ||
    _InTransitStatus.delayed => DriverTimelineState.completed,
  };
  final nearDeliveryState = switch (status) {
    _InTransitStatus.delivered => DriverTimelineState.completed,
    _InTransitStatus.nearDelivery => DriverTimelineState.current,
    _ => DriverTimelineState.pending,
  };
  final deliveredState = status == _InTransitStatus.delivered
      ? DriverTimelineState.current
      : DriverTimelineState.pending;

  return [
    DriverTimelineMock(
      title: 'Assigned',
      subtitle: 'Fleet desk assigned ${trip.shipmentId} to this driver.',
      time: '08:20 AM',
      state: DriverTimelineState.completed,
    ),
    const DriverTimelineMock(
      title: 'Pickup completed',
      subtitle: 'Pickup proof accepted for review.',
      time: '10:42 AM',
      state: DriverTimelineState.completed,
    ),
    DriverTimelineMock(
      title: 'In Transit',
      subtitle: isDelayed
          ? 'Trip remains in progress with updated ETA $eta.'
          : 'Driver update saved with ETA $eta.',
      time: transitState == DriverTimelineState.pending ? 'Pending' : 'Now',
      state: transitState,
    ),
    if (isDelayed)
      DriverTimelineMock(
        title: 'Delay reported',
        subtitle: 'Dispatch has an issue report with updated ETA $eta.',
        time: 'Now',
        state: DriverTimelineState.current,
      ),
    DriverTimelineMock(
      title: 'Near delivery',
      subtitle: 'Driver is approaching the destination hub.',
      time: nearDeliveryState == DriverTimelineState.pending
          ? 'Pending'
          : 'Now',
      state: nearDeliveryState,
    ),
    DriverTimelineMock(
      title: 'Delivered',
      subtitle: 'Delivery proof and receiver handoff are pending.',
      time: deliveredState == DriverTimelineState.pending ? 'Pending' : 'Now',
      state: deliveredState,
    ),
  ];
}
