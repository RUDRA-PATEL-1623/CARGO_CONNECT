import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/status_badge.dart';
import 'data/driver_trip_api.dart';
import 'data/driver_trip_models.dart';
import 'widgets/trip_decision_dialogs.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  var _selectedFilter = _TripFilter.newTrip;
  var _trips = <_AssignedTrip>[];
  var _isLoading = true;
  String? _errorMessage;

  DriverTripApi get _api => ref.read(driverTripApiProvider);

  List<_AssignedTrip> get _visibleTrips {
    return _trips.where((trip) => trip.filter == _selectedFilter).toList();
  }

  int _countFor(_TripFilter filter) {
    return _trips.where((trip) => trip.filter == filter).length;
  }

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _api.listTrips(limit: 50);
      if (!mounted) {
        return;
      }
      setState(() {
        _trips = result.trips.map(_AssignedTrip.fromApi).toList();
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

  Future<void> _acceptTrip(_AssignedTrip trip) async {
    final confirmed = await showTripAcceptConfirmation(
      context,
      shipmentId: trip.shipmentId,
      pickup: trip.pickup,
      delivery: trip.delivery,
    );
    if (!mounted || !confirmed) {
      return;
    }

    try {
      final updatedTrip = await _api.acceptTrip(trip.assignmentId);
      if (!mounted) {
        return;
      }
      setState(() {
        final index = _trips.indexWhere(
          (item) => item.assignmentId == trip.assignmentId,
        );
        if (index != -1) {
          _trips[index] = _AssignedTrip.fromApi(updatedTrip);
        }
        _selectedFilter = _TripFilter.accepted;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${trip.shipmentId} accepted.')));
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _rejectTrip(_AssignedTrip trip) async {
    final result = await showTripRejectReasonSheet(
      context,
      shipmentId: trip.shipmentId,
      pickup: trip.pickup,
      delivery: trip.delivery,
    );
    if (!mounted || result == null) {
      return;
    }

    try {
      await _api.rejectTrip(
        assignmentId: trip.assignmentId,
        reason: result.reason,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _trips.removeWhere((item) => item.assignmentId == trip.assignmentId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${trip.shipmentId} rejected: ${result.reason}.'),
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

  void _openTripDetails(_AssignedTrip trip) {
    context.go(
      Uri(
        path: AppRoutes.tripDetails,
        queryParameters: {
          'assignmentId': trip.assignmentId.toString(),
          'shipmentId': trip.shipmentId,
        },
      ).toString(),
    );
  }

  void _openStartTrip(_AssignedTrip trip) {
    context.go(
      Uri(
        path: AppRoutes.startTrip,
        queryParameters: {
          'assignmentId': trip.assignmentId.toString(),
          'shipmentId': trip.shipmentId,
        },
      ).toString(),
    );
  }

  void _openInTransitUpdate(_AssignedTrip trip) {
    context.go(
      Uri(
        path: AppRoutes.inTransitUpdate,
        queryParameters: {
          'assignmentId': trip.assignmentId.toString(),
          'shipmentId': trip.shipmentId,
        },
      ).toString(),
    );
  }

  void _openProofUpload(_AssignedTrip trip) {
    context.go(
      Uri(
        path: AppRoutes.proofUpload,
        queryParameters: {
          'assignmentId': trip.assignmentId.toString(),
          'shipmentId': trip.shipmentId,
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleTrips = _visibleTrips;
    final uploadCandidate = _trips.where((trip) => trip.canUploadPickupProof);

    return CommonAppScaffold(
      title: 'Assigned trips',
      subtitle: 'Review shipment assignments and respond to dispatch.',
      bottomNavigationIndex: 1,
      actions: [
        IconButton(
          tooltip: 'Upload active pickup proof',
          onPressed: uploadCandidate.isEmpty
              ? null
              : () => _openProofUpload(uploadCandidate.first),
          icon: const Icon(Icons.cloud_upload_outlined),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading) ...[
            const LoadingWidget(message: 'Loading assigned trips'),
          ] else if (_errorMessage != null) ...[
            ErrorStateWidget(
              title: 'Could not load trips',
              message: _errorMessage!,
              onRetry: _loadTrips,
            ),
          ] else ...[
            _TripsHeader(
              totalTrips: _trips.length,
              activeFilter: _selectedFilter,
            ),
            const SizedBox(height: AppSpacing.lg),
            _FilterChips(
              selectedFilter: _selectedFilter,
              countFor: _countFor,
              onChanged: (filter) => setState(() => _selectedFilter = filter),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (visibleTrips.isEmpty)
              EmptyStateWidget(
                title: 'No ${_selectedFilter.label.toLowerCase()} trips',
                message:
                    'Shipments matching this status will appear here once dispatch assigns them.',
                icon: Icons.route_outlined,
              )
            else
              Column(
                children: [
                  for (final trip in visibleTrips) ...[
                    _AssignedTripCard(
                      trip: trip,
                      onOpenDetails: () => _openTripDetails(trip),
                      onStartTrip: trip.canStart
                          ? () => _openStartTrip(trip)
                          : null,
                      onUpdateTrip: trip.canUpdate
                          ? () => _openInTransitUpdate(trip)
                          : null,
                      onAccept: trip.canRespond
                          ? () => _acceptTrip(trip)
                          : null,
                      onReject: trip.canRespond
                          ? () => _rejectTrip(trip)
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _TripsHeader extends StatelessWidget {
  const _TripsHeader({required this.totalTrips, required this.activeFilter});

  final int totalTrips;
  final _TripFilter activeFilter;

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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.textInverse.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: const Icon(
              Icons.route_rounded,
              color: AppColors.roadYellow,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalTrips assigned shipments',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${activeFilter.label} queue from dispatch',
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

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selectedFilter,
    required this.countFor,
    required this.onChanged,
  });

  final _TripFilter selectedFilter;
  final int Function(_TripFilter filter) countFor;
  final ValueChanged<_TripFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final filter in _TripFilter.values)
          FilterChip(
            selected: selectedFilter == filter,
            label: Text('${filter.label} (${countFor(filter)})'),
            avatar: Icon(filter.icon, size: 18),
            onSelected: (_) => onChanged(filter),
          ),
      ],
    );
  }
}

class _AssignedTripCard extends StatelessWidget {
  const _AssignedTripCard({
    required this.trip,
    required this.onOpenDetails,
    required this.onStartTrip,
    required this.onUpdateTrip,
    required this.onAccept,
    required this.onReject,
  });

  final _AssignedTrip trip;
  final VoidCallback onOpenDetails;
  final VoidCallback? onStartTrip;
  final VoidCallback? onUpdateTrip;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpenDetails,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 560;
              final routeDetails = _TripRouteDetails(trip: trip);
              final meta = _TripMetaPanel(trip: trip);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.shipmentId,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              trip.packageType,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: trip.status.label,
                        tone: trip.status.tone,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: routeDetails),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(flex: 2, child: meta),
                      ],
                    )
                  else ...[
                    routeDetails,
                    const SizedBox(height: AppSpacing.md),
                    meta,
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _TripActions(
                    canRespond: trip.canRespond,
                    canStart: trip.canStart,
                    canUpdate: trip.canUpdate,
                    onOpenDetails: onOpenDetails,
                    onStartTrip: onStartTrip,
                    onUpdateTrip: onUpdateTrip,
                    onAccept: onAccept,
                    onReject: onReject,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TripRouteDetails extends StatelessWidget {
  const _TripRouteDetails({required this.trip});

  final _AssignedTrip trip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RouteLine(
          icon: Icons.my_location_rounded,
          label: 'Pickup',
          value: trip.pickup,
        ),
        const SizedBox(height: AppSpacing.sm),
        _RouteLine(
          icon: Icons.location_on_rounded,
          label: 'Delivery',
          value: trip.delivery,
        ),
      ],
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

class _TripMetaPanel extends StatelessWidget {
  const _TripMetaPanel({required this.trip});

  final _AssignedTrip trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _MetaLine(
            icon: Icons.schedule_rounded,
            label: 'Scheduled time',
            value: trip.scheduledTime,
          ),
          const Divider(height: AppSpacing.lg),
          _MetaLine(
            icon: Icons.social_distance_rounded,
            label: 'Distance',
            value: trip.distance,
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
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
      children: [
        Icon(icon, size: 20, color: AppColors.primaryBlue),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}

class _TripActions extends StatelessWidget {
  const _TripActions({
    required this.canRespond,
    required this.canStart,
    required this.canUpdate,
    required this.onOpenDetails,
    required this.onStartTrip,
    required this.onUpdateTrip,
    required this.onAccept,
    required this.onReject,
  });

  final bool canRespond;
  final bool canStart;
  final bool canUpdate;
  final VoidCallback onOpenDetails;
  final VoidCallback? onStartTrip;
  final VoidCallback? onUpdateTrip;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'View trip details',
          onPressed: onOpenDetails,
          icon: const Icon(Icons.article_outlined),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (canStart)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onStartTrip,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start trip'),
            ),
          )
        else if (canUpdate)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onUpdateTrip,
              icon: const Icon(Icons.near_me_rounded),
              label: const Text('Update trip'),
            ),
          )
        else ...[
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
      ],
    );
  }
}

enum _TripFilter {
  newTrip('New', Icons.fiber_new_rounded),
  accepted('Accepted', Icons.verified_rounded),
  inProgress('In Transit', Icons.local_shipping_rounded),
  completed('Completed', Icons.done_all_rounded);

  const _TripFilter(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum _TripStatus {
  newTrip('New', _TripFilter.newTrip, StatusBadgeTone.assigned),
  accepted('Accepted', _TripFilter.accepted, StatusBadgeTone.accepted),
  inProgress('In Transit', _TripFilter.inProgress, StatusBadgeTone.transit),
  completed('Completed', _TripFilter.completed, StatusBadgeTone.completed);

  const _TripStatus(this.label, this.filter, this.tone);

  factory _TripStatus.fromApi(String status) {
    return switch (status) {
      'assigned' => _TripStatus.newTrip,
      'accepted' => _TripStatus.accepted,
      'completed' => _TripStatus.completed,
      _ => _TripStatus.inProgress,
    };
  }

  final String label;
  final _TripFilter filter;
  final StatusBadgeTone tone;
}

class _AssignedTrip {
  const _AssignedTrip({
    required this.assignmentId,
    required this.shipmentId,
    required this.pickup,
    required this.delivery,
    required this.packageType,
    required this.scheduledTime,
    required this.status,
    required this.distance,
    required this.canUploadPickupProof,
  });

  factory _AssignedTrip.fromApi(DriverTripSummary trip) {
    return _AssignedTrip(
      assignmentId: trip.id,
      shipmentId: trip.displayId,
      pickup: trip.pickupAddress,
      delivery: trip.deliveryAddress,
      packageType: trip.packageInfo.type.isEmpty
          ? trip.shipment.category.name
          : trip.packageInfo.type,
      scheduledTime: trip.scheduledWindow,
      status: _TripStatus.fromApi(trip.assignmentStatus),
      distance: trip.distanceLabel,
      canUploadPickupProof: trip.actions.canUploadPickupProof,
    );
  }

  final int assignmentId;
  final String shipmentId;
  final String pickup;
  final String delivery;
  final String packageType;
  final String scheduledTime;
  final _TripStatus status;
  final String distance;
  final bool canUploadPickupProof;

  _TripFilter get filter => status.filter;
  bool get canRespond => status == _TripStatus.newTrip;
  bool get canStart => status == _TripStatus.accepted;
  bool get canUpdate => status == _TripStatus.inProgress;

  _AssignedTrip copyWith({_TripStatus? status}) {
    return _AssignedTrip(
      assignmentId: assignmentId,
      shipmentId: shipmentId,
      pickup: pickup,
      delivery: delivery,
      packageType: packageType,
      scheduledTime: scheduledTime,
      status: status ?? this.status,
      distance: distance,
      canUploadPickupProof: canUploadPickupProof,
    );
  }
}
