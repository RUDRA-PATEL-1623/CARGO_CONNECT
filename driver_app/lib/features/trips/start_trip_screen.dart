import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/status_badge.dart';
import 'data/driver_trip_api.dart';
import 'data/driver_trip_models.dart';

class StartTripScreen extends ConsumerStatefulWidget {
  const StartTripScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  ConsumerState<StartTripScreen> createState() => _StartTripScreenState();
}

class _StartTripScreenState extends ConsumerState<StartTripScreen> {
  _AcceptedTripStartInfo? _trip;
  var _status = _StartTripStatus.accepted;
  final Set<_ChecklistItem> _checkedItems = {};
  var _isLoading = true;
  var _isStarting = false;
  String? _errorMessage;

  DriverTripApi get _api => ref.read(driverTripApiProvider);

  bool get _isChecklistComplete =>
      _checkedItems.length == _startChecklist.length;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  Future<void> _loadTrip() async {
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
        _trip = _AcceptedTripStartInfo.fromApi(details.trip);
        _status = details.trip.assignmentStatus == 'started'
            ? _StartTripStatus.started
            : _StartTripStatus.accepted;
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

  void _toggleChecklistItem(_ChecklistItem item, bool? value) {
    setState(() {
      if (value ?? false) {
        _checkedItems.add(item);
      } else {
        _checkedItems.remove(item);
      }
    });
  }

  Future<void> _startTrip() async {
    final trip = _trip;
    if (trip == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Start trip?'),
          content: Text(
            'This moves ${trip.shipmentId} from Accepted to Started.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start trip'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() => _isStarting = true);
    try {
      final updated = await _api.startTrip(
        trip.assignmentId,
        notes: 'Driver completed pre-start checklist.',
        locationText: trip.pickup,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _trip = _AcceptedTripStartInfo.fromApi(updated);
        _status = _StartTripStatus.started;
        _isStarting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${trip.shipmentId} started.')));
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isStarting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _openPickupProof() {
    final trip = _trip;
    if (trip == null) {
      return;
    }
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
    final trip = _trip;

    return CommonAppScaffold(
      title: 'Start trip',
      subtitle: 'Complete pre-start checks before moving to pickup.',
      bottomNavigationIndex: 1,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const LoadingWidget(message: 'Loading accepted trip')
          else if (_errorMessage != null)
            ErrorStateWidget(
              title: 'Could not load trip',
              message: _errorMessage!,
              onRetry: _loadTrip,
            )
          else if (trip != null) ...[
            _AcceptedTripCard(trip: trip, status: _status),
            const SizedBox(height: AppSpacing.lg),
            _StartChecklist(
              checkedItems: _checkedItems,
              onChanged: _status == _StartTripStatus.started || _isStarting
                  ? null
                  : _toggleChecklistItem,
            ),
            const SizedBox(height: AppSpacing.lg),
            _RouteMapPlaceholder(trip: trip),
            const SizedBox(height: AppSpacing.lg),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _status == _StartTripStatus.started
                  ? _PickupProofCta(
                      key: const ValueKey('pickup-proof-cta'),
                      shipmentId: trip.shipmentId,
                      onPressed: _openPickupProof,
                    )
                  : ElevatedButton.icon(
                      key: const ValueKey('start-trip-button'),
                      onPressed: !_isChecklistComplete || _isStarting
                          ? null
                          : _startTrip,
                      icon: _isStarting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textInverse,
                              ),
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        _isStarting
                            ? 'Starting trip...'
                            : _isChecklistComplete
                            ? 'Start trip'
                            : 'Complete checklist to start',
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PickupProofCta extends StatelessWidget {
  const _PickupProofCta({
    super.key,
    required this.shipmentId,
    required this.onPressed,
  });

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
                Icons.add_photo_alternate_outlined,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickup proof required',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Upload mandatory pickup proof for $shipmentId before moving in transit.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Open pickup proof',
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcceptedTripCard extends StatelessWidget {
  const _AcceptedTripCard({required this.trip, required this.status});

  final _AcceptedTripStartInfo trip;
  final _StartTripStatus status;

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
              StatusBadge(label: status.label, tone: status.tone),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _HeroMetric(label: 'Pickup', value: trip.pickupWindow),
              _HeroMetric(label: 'Distance', value: trip.distance),
              _HeroMetric(label: 'ETA', value: trip.eta),
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
      width: 144,
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

class _StartChecklist extends StatelessWidget {
  const _StartChecklist({required this.checkedItems, required this.onChanged});

  final Set<_ChecklistItem> checkedItems;
  final void Function(_ChecklistItem item, bool? value)? onChanged;

  @override
  Widget build(BuildContext context) {
    final completed = checkedItems.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.fact_check_outlined,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Pre-start checklist',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$completed/${_startChecklist.length}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Confirm these checks before starting the trip.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final item in _startChecklist)
              CheckboxListTile(
                value: checkedItems.contains(item),
                onChanged: onChanged == null
                    ? null
                    : (value) => onChanged!(item, value),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(item.title),
                subtitle: Text(item.subtitle),
              ),
          ],
        ),
      ),
    );
  }
}

class _RouteMapPlaceholder extends StatelessWidget {
  const _RouteMapPlaceholder({required this.trip});

  final _AcceptedTripStartInfo trip;

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
                    'Route preview',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const StatusBadge(
                  label: 'Map placeholder',
                  tone: StatusBadgeTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _RoutePainter())),
                  const Positioned(
                    left: AppSpacing.lg,
                    top: AppSpacing.lg,
                    child: _MapPin(label: 'Pickup'),
                  ),
                  const Positioned(
                    right: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                    child: _MapPin(label: 'Delivery'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.label});

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
          const Icon(
            Icons.location_on_rounded,
            size: 16,
            color: AppColors.primaryBlue,
          ),
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

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var x = 24.0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 24.0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final routePaint = Paint()
      ..color = AppColors.primaryBlue
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(58, 58)
      ..cubicTo(
        size.width * 0.32,
        28,
        size.width * 0.48,
        size.height * 0.72,
        size.width * 0.64,
        size.height * 0.52,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height * 0.36,
        size.width - 76,
        size.height - 62,
        size.width - 58,
        size.height - 58,
      );
    canvas.drawPath(path, routePaint);

    final pointPaint = Paint()..color = AppColors.roadYellow;
    canvas.drawCircle(const Offset(58, 58), 7, pointPaint);
    canvas.drawCircle(Offset(size.width - 58, size.height - 58), 7, pointPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _StartTripStatus {
  accepted('Accepted', StatusBadgeTone.accepted),
  started('Started', StatusBadgeTone.transit);

  const _StartTripStatus(this.label, this.tone);

  final String label;
  final StatusBadgeTone tone;
}

class _ChecklistItem {
  const _ChecklistItem({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

class _AcceptedTripStartInfo {
  const _AcceptedTripStartInfo({
    required this.assignmentId,
    required this.shipmentId,
    required this.packageType,
    required this.vehicle,
    required this.pickup,
    required this.delivery,
    required this.pickupWindow,
    required this.distance,
    required this.eta,
  });

  factory _AcceptedTripStartInfo.fromApi(DriverTripSummary trip) {
    return _AcceptedTripStartInfo(
      assignmentId: trip.id,
      shipmentId: trip.displayId,
      packageType: trip.packageInfo.type.isEmpty
          ? trip.shipment.category.name
          : trip.packageInfo.type,
      vehicle: trip.vehicleLabel,
      pickup: trip.pickupAddress,
      delivery: trip.deliveryAddress,
      pickupWindow: trip.scheduledWindow,
      distance: trip.distanceLabel,
      eta: trip.durationLabel,
    );
  }

  final int assignmentId;
  final String shipmentId;
  final String packageType;
  final String vehicle;
  final String pickup;
  final String delivery;
  final String pickupWindow;
  final String distance;
  final String eta;
}

const _startChecklist = [
  _ChecklistItem(
    title: 'Vehicle inspection complete',
    subtitle: 'Tyres, lights, fuel, and permit documents checked.',
  ),
  _ChecklistItem(
    title: 'Package count verified',
    subtitle: 'Load count matches the assigned shipment manifest.',
  ),
  _ChecklistItem(
    title: 'Pickup contact confirmed',
    subtitle: 'Warehouse or sender contact is reachable before arrival.',
  ),
  _ChecklistItem(
    title: 'Route reviewed',
    subtitle: 'Map preview, tolls, and estimated travel time checked.',
  ),
];
