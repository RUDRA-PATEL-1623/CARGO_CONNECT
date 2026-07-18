import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/mock_driver_data.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/trip_timeline_widget.dart';
import 'data/driver_trip_api.dart';
import 'data/driver_trip_models.dart';
import 'widgets/trip_decision_dialogs.dart';

class TripDetailsScreen extends ConsumerStatefulWidget {
  const TripDetailsScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  ConsumerState<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends ConsumerState<TripDetailsScreen> {
  _DriverTripDetails? _details;
  var _isLoading = true;
  String? _errorMessage;

  DriverTripApi get _api => ref.read(driverTripApiProvider);

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = await _api.resolveTripDetails(widget.shipmentId);
      if (!mounted) {
        return;
      }
      setState(() {
        _details = _DriverTripDetails.fromApi(details);
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

  Future<void> _acceptTrip() async {
    final details = _details;
    if (details == null) {
      return;
    }
    final confirmed = await showTripAcceptConfirmation(
      context,
      shipmentId: details.shipmentId,
      pickup: details.pickupAddress,
      delivery: details.deliveryAddress,
    );
    if (!mounted || !confirmed) {
      return;
    }

    try {
      final updated = await _api.acceptTrip(details.assignmentId);
      if (!mounted) {
        return;
      }
      setState(() => _details = details.copyWithTrip(updated));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${details.shipmentId} accepted.')),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _rejectTrip() async {
    final details = _details;
    if (details == null) {
      return;
    }
    final result = await showTripRejectReasonSheet(
      context,
      shipmentId: details.shipmentId,
      pickup: details.pickupAddress,
      delivery: details.deliveryAddress,
    );
    if (!mounted || result == null) {
      return;
    }

    try {
      final updated = await _api.rejectTrip(
        assignmentId: details.assignmentId,
        reason: result.reason,
      );
      if (!mounted) {
        return;
      }
      setState(() => _details = details.copyWithTrip(updated));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${details.shipmentId} rejected: ${result.reason}.'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = _details;

    return CommonAppScaffold(
      title: 'Trip details',
      subtitle: 'Review shipment, route, customer, and vehicle information.',
      bottomNavigationIndex: 1,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const LoadingWidget(message: 'Loading trip details')
          else if (_errorMessage != null)
            ErrorStateWidget(
              title: 'Could not load trip',
              message: _errorMessage!,
              onRetry: _loadDetails,
            )
          else if (details != null) ...[
            _TripDetailsHero(details: details),
            const SizedBox(height: AppSpacing.lg),
            _DecisionActions(
              canRespond: details.canRespond,
              statusLabel: details.status.label,
              onAccept: _acceptTrip,
              onReject: _rejectTrip,
            ),
            const SizedBox(height: AppSpacing.lg),
            _ResponsiveDetailsGrid(
              sections: [
                _DetailsSection(
                  title: 'Customer',
                  icon: Icons.person_outline_rounded,
                  rows: [
                    _DetailsRow(label: 'Name', value: details.customerName),
                    _DetailsRow(label: 'Phone', value: details.customerPhone),
                    _DetailsRow(label: 'Email', value: details.customerEmail),
                  ],
                ),
                _DetailsSection(
                  title: 'Receiver',
                  icon: Icons.person_pin_circle_outlined,
                  rows: [
                    _DetailsRow(label: 'Name', value: details.receiverName),
                    _DetailsRow(label: 'Phone', value: details.receiverPhone),
                    _DetailsRow(label: 'Window', value: details.receiverWindow),
                  ],
                ),
                _DetailsSection(
                  title: 'Pickup and delivery',
                  icon: Icons.route_rounded,
                  rows: [
                    _DetailsRow(label: 'Pickup', value: details.pickupAddress),
                    _DetailsRow(
                      label: 'Delivery',
                      value: details.deliveryAddress,
                    ),
                    _DetailsRow(
                      label: 'Scheduled',
                      value: details.scheduledTime,
                    ),
                  ],
                ),
                _DetailsSection(
                  title: 'Package info',
                  icon: Icons.inventory_2_outlined,
                  rows: [
                    _DetailsRow(label: 'Type', value: details.packageType),
                    _DetailsRow(label: 'Weight', value: details.weight),
                    _DetailsRow(label: 'Dimensions', value: details.dimensions),
                    _DetailsRow(label: 'Handling', value: details.handling),
                  ],
                ),
                _DetailsSection(
                  title: 'Vehicle info',
                  icon: Icons.local_shipping_outlined,
                  rows: [
                    _DetailsRow(label: 'Vehicle', value: details.vehicle),
                    _DetailsRow(label: 'Plate', value: details.vehicleNumber),
                    _DetailsRow(label: 'Distance', value: details.distance),
                  ],
                ),
                _DetailsSection(
                  title: 'Notes',
                  icon: Icons.notes_rounded,
                  rows: [
                    _DetailsRow(label: 'Driver note', value: details.notes),
                    _DetailsRow(label: 'Admin note', value: details.adminNote),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TripTimelineWidget(items: details.timeline),
          ],
        ],
      ),
    );
  }
}

class _TripDetailsHero extends StatelessWidget {
  const _TripDetailsHero({required this.details});

  final _DriverTripDetails details;

  @override
  Widget build(BuildContext context) {
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
                  Icons.assignment_rounded,
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
                      details.shipmentId,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textInverse,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${details.packageType} - ${details.vehicle}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.surfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: details.status.label,
                tone: details.status.tone,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _HeroMetric(label: 'Scheduled', value: details.scheduledTime),
              _HeroMetric(label: 'Distance', value: details.distance),
              _HeroMetric(label: 'Payout', value: details.payout),
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

class _DecisionActions extends StatelessWidget {
  const _DecisionActions({
    required this.canRespond,
    required this.statusLabel,
    required this.onAccept,
    required this.onReject,
  });

  final bool canRespond;
  final String statusLabel;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver decision',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              canRespond
                  ? 'Accept or reject this assignment before dispatch starts the route.'
                  : 'Actions are locked because this trip is currently $statusLabel.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canRespond ? onReject : null,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canRespond ? onAccept : null,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Accept'),
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

class _ResponsiveDetailsGrid extends StatelessWidget {
  const _ResponsiveDetailsGrid({required this.sections});

  final List<_DetailsSection> sections;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 2 : 1;
        final width =
            (constraints.maxWidth - (AppSpacing.md * (columns - 1))) / columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final section in sections)
              SizedBox(
                width: width,
                child: _DetailsCard(section: section),
              ),
          ],
        );
      },
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.section});

  final _DetailsSection section;

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
                Icon(section.icon, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            for (final row in section.rows) _DetailsLine(row: row),
          ],
        ),
      ),
    );
  }
}

class _DetailsLine extends StatelessWidget {
  const _DetailsLine({required this.row});

  final _DetailsRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(row.label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(row.value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _DetailsSection {
  const _DetailsSection({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_DetailsRow> rows;
}

class _DetailsRow {
  const _DetailsRow({required this.label, required this.value});

  final String label;
  final String value;
}

enum _TripDetailStatus {
  assigned('Assigned', StatusBadgeTone.assigned),
  accepted('Accepted', StatusBadgeTone.accepted),
  started('Started', StatusBadgeTone.accepted),
  pickupCompleted('Pickup Completed', StatusBadgeTone.pickup),
  inProgress('In Transit', StatusBadgeTone.transit),
  delivered('Delivered', StatusBadgeTone.delivered),
  completed('Completed', StatusBadgeTone.completed),
  rejected('Rejected', StatusBadgeTone.emergency);

  const _TripDetailStatus(this.label, this.tone);

  factory _TripDetailStatus.fromApi(String status) {
    return switch (status) {
      'assigned' => _TripDetailStatus.assigned,
      'accepted' => _TripDetailStatus.accepted,
      'started' => _TripDetailStatus.started,
      'pickup_completed' => _TripDetailStatus.pickupCompleted,
      'in_transit' => _TripDetailStatus.inProgress,
      'delivered' => _TripDetailStatus.delivered,
      'completed' => _TripDetailStatus.completed,
      'rejected' => _TripDetailStatus.rejected,
      _ => _TripDetailStatus.assigned,
    };
  }

  final String label;
  final StatusBadgeTone tone;
}

class _DriverTripDetails {
  const _DriverTripDetails({
    required this.assignmentId,
    required this.shipmentId,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverWindow,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.packageType,
    required this.weight,
    required this.dimensions,
    required this.handling,
    required this.notes,
    required this.adminNote,
    required this.vehicle,
    required this.vehicleNumber,
    required this.distance,
    required this.scheduledTime,
    required this.payout,
    required this.timeline,
  });

  factory _DriverTripDetails.fromApi(DriverTripDetail details) {
    final trip = details.trip;
    return _DriverTripDetails(
      assignmentId: trip.id,
      shipmentId: trip.displayId,
      status: _TripDetailStatus.fromApi(trip.assignmentStatus),
      customerName: trip.customer.name,
      customerPhone: trip.customer.phoneMasked,
      customerEmail: trip.customer.emailMasked,
      receiverName: trip.receiver.name,
      receiverPhone: trip.receiver.phone,
      receiverWindow: trip.scheduledWindow,
      pickupAddress: trip.pickupAddress,
      deliveryAddress: trip.deliveryAddress,
      packageType: trip.packageInfo.type.isEmpty
          ? trip.shipment.category.name
          : trip.packageInfo.type,
      weight: trip.packageInfo.weightLabel,
      dimensions: trip.packageInfo.dimensionsLabel,
      handling: trip.packageInfo.handlingLabel,
      notes: trip.packageInfo.deliveryNotes.isEmpty
          ? 'No driver notes from dispatch.'
          : trip.packageInfo.deliveryNotes,
      adminNote: trip.rejectionReason ?? 'Follow the CargoConnect status flow.',
      vehicle: trip.vehicleLabel,
      vehicleNumber: trip.vehicle.vehicleNumber.isEmpty
          ? trip.vehicle.registrationNumber
          : trip.vehicle.vehicleNumber,
      distance: trip.distanceLabel,
      scheduledTime: trip.scheduledWindow,
      payout: trip.payoutLabel,
      timeline: details.timeline.toTimelineMocks(),
    );
  }

  final int assignmentId;
  final String shipmentId;
  final _TripDetailStatus status;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String receiverName;
  final String receiverPhone;
  final String receiverWindow;
  final String pickupAddress;
  final String deliveryAddress;
  final String packageType;
  final String weight;
  final String dimensions;
  final String handling;
  final String notes;
  final String adminNote;
  final String vehicle;
  final String vehicleNumber;
  final String distance;
  final String scheduledTime;
  final String payout;
  final List<DriverTimelineMock> timeline;

  bool get canRespond => status == _TripDetailStatus.assigned;

  _DriverTripDetails copyWith({_TripDetailStatus? status}) {
    return _DriverTripDetails(
      assignmentId: assignmentId,
      shipmentId: shipmentId,
      status: status ?? this.status,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      receiverWindow: receiverWindow,
      pickupAddress: pickupAddress,
      deliveryAddress: deliveryAddress,
      packageType: packageType,
      weight: weight,
      dimensions: dimensions,
      handling: handling,
      notes: notes,
      adminNote: adminNote,
      vehicle: vehicle,
      vehicleNumber: vehicleNumber,
      distance: distance,
      scheduledTime: scheduledTime,
      payout: payout,
      timeline: _timelineFor(status ?? this.status, shipmentId),
    );
  }

  _DriverTripDetails copyWithTrip(DriverTripSummary trip) {
    return _DriverTripDetails(
      assignmentId: trip.id,
      shipmentId: trip.displayId,
      status: _TripDetailStatus.fromApi(trip.assignmentStatus),
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      receiverWindow: trip.scheduledWindow,
      pickupAddress: trip.pickupAddress,
      deliveryAddress: trip.deliveryAddress,
      packageType: packageType,
      weight: weight,
      dimensions: dimensions,
      handling: handling,
      notes: notes,
      adminNote: trip.rejectionReason ?? adminNote,
      vehicle: trip.vehicleLabel,
      vehicleNumber: trip.vehicle.vehicleNumber.isEmpty
          ? vehicleNumber
          : trip.vehicle.vehicleNumber,
      distance: trip.distanceLabel,
      scheduledTime: trip.scheduledWindow,
      payout: trip.payoutLabel,
      timeline: _timelineFor(
        _TripDetailStatus.fromApi(trip.assignmentStatus),
        trip.displayId,
      ),
    );
  }
}

List<DriverTimelineMock> _timelineFor(
  _TripDetailStatus status,
  String shipmentId,
) {
  final acceptedState = switch (status) {
    _TripDetailStatus.assigned ||
    _TripDetailStatus.rejected => DriverTimelineState.pending,
    _ => DriverTimelineState.completed,
  };
  final pickupState = switch (status) {
    _TripDetailStatus.started => DriverTimelineState.current,
    _TripDetailStatus.pickupCompleted => DriverTimelineState.completed,
    _TripDetailStatus.inProgress ||
    _TripDetailStatus.delivered ||
    _TripDetailStatus.completed => DriverTimelineState.completed,
    _TripDetailStatus.accepted => DriverTimelineState.current,
    _ => DriverTimelineState.pending,
  };
  final transitState = switch (status) {
    _TripDetailStatus.inProgress => DriverTimelineState.current,
    _TripDetailStatus.delivered ||
    _TripDetailStatus.completed => DriverTimelineState.completed,
    _ => DriverTimelineState.pending,
  };
  final deliveredState =
      status == _TripDetailStatus.completed ||
          status == _TripDetailStatus.delivered
      ? DriverTimelineState.completed
      : DriverTimelineState.pending;

  return [
    DriverTimelineMock(
      title: 'Assigned',
      subtitle: 'Fleet desk assigned $shipmentId to this driver profile.',
      time: '08:20 AM',
      state: DriverTimelineState.completed,
    ),
    DriverTimelineMock(
      title: 'Accepted',
      subtitle: 'Driver accepts the shipment and confirms vehicle readiness.',
      time: acceptedState == DriverTimelineState.pending
          ? 'Pending'
          : '08:27 AM',
      state: acceptedState,
    ),
    DriverTimelineMock(
      title: 'Pickup completed',
      subtitle: 'Pickup proof upload is required after collection.',
      time: pickupState == DriverTimelineState.pending ? 'Pending' : '10:42 AM',
      state: pickupState,
    ),
    DriverTimelineMock(
      title: 'In transit',
      subtitle: 'Location and route updates are recorded in the trip timeline.',
      time: transitState == DriverTimelineState.pending ? 'Pending' : 'Now',
      state: transitState,
    ),
    DriverTimelineMock(
      title: 'Delivered',
      subtitle: 'Delivery proof and receiver verification complete the trip.',
      time: deliveredState == DriverTimelineState.pending
          ? 'Pending'
          : '6:15 PM',
      state: deliveredState,
    ),
  ];
}
