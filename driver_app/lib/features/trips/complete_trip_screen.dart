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
import '../../core/widgets/trip_card.dart';
import 'data/driver_trip_api.dart';
import 'data/driver_trip_models.dart';

class CompleteTripScreen extends ConsumerStatefulWidget {
  const CompleteTripScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  ConsumerState<CompleteTripScreen> createState() => _CompleteTripScreenState();
}

class _CompleteTripScreenState extends ConsumerState<CompleteTripScreen> {
  _CompleteTripMock? _trip;
  final Set<_CompletionChecklistItem> _checkedItems = {};
  bool _isEndingTrip = false;
  bool _isCompleted = false;
  var _isLoading = true;
  String? _errorMessage;

  DriverTripApi get _api => ref.read(driverTripApiProvider);

  bool get _isChecklistComplete {
    return _checkedItems.length == _CompletionChecklistItem.values.length;
  }

  bool get _canEndTrip =>
      _isChecklistComplete && !_isEndingTrip && !_isCompleted;

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
        _trip = _CompleteTripMock.fromApi(details);
        _isCompleted = details.trip.assignmentStatus == 'completed';
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

  void _toggleChecklistItem(_CompletionChecklistItem item, bool? value) {
    if (_isEndingTrip || _isCompleted) {
      return;
    }

    setState(() {
      if (value ?? false) {
        _checkedItems.add(item);
      } else {
        _checkedItems.remove(item);
      }
    });
  }

  Future<void> _endTrip() async {
    final trip = _trip;
    if (!_canEndTrip || trip == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('End trip?'),
          content: Text('This will mark ${trip.shipmentId} as completed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('End trip'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isEndingTrip = true);
    try {
      await _api.completeTrip(
        trip.assignmentId,
        notes: 'Driver completed the trip after proof review.',
        locationText: trip.deliveryLocation,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isEndingTrip = false;
        _isCompleted = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${trip.shipmentId} completed.')));
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isEndingTrip = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;

    return CommonAppScaffold(
      title: 'Complete trip',
      subtitle:
          'Review proof, distance, and handoff checklist before ending the trip.',
      bottomNavigationIndex: 1,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const LoadingWidget(message: 'Loading trip completion')
          else if (_errorMessage != null)
            ErrorStateWidget(
              title: 'Could not load completion',
              message: _errorMessage!,
              onRetry: _loadTrip,
            )
          else if (trip != null) ...[
            if (_isCompleted) ...[
              _TripCompletedSuccessCard(trip: trip),
              const SizedBox(height: AppSpacing.lg),
            ],
            _CompleteTripHeader(trip: trip, isCompleted: _isCompleted),
            const SizedBox(height: AppSpacing.lg),
            TripCard(trip: trip.summaryTrip),
            const SizedBox(height: AppSpacing.lg),
            _DistanceTimeCard(trip: trip),
            const SizedBox(height: AppSpacing.lg),
            _ProofCards(trip: trip),
            const SizedBox(height: AppSpacing.lg),
            _CompletionChecklistCard(
              checkedItems: _checkedItems,
              isLocked: _isEndingTrip || _isCompleted,
              onChanged: _toggleChecklistItem,
            ),
            const SizedBox(height: AppSpacing.lg),
            _EndTripButton(
              isCompleted: _isCompleted,
              isLoading: _isEndingTrip,
              canSubmit: _canEndTrip,
              onPressed: _endTrip,
            ),
            if (_isCompleted) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.dashboard),
                icon: const Icon(Icons.dashboard_outlined),
                label: const Text('Back to dashboard'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CompleteTripHeader extends StatelessWidget {
  const _CompleteTripHeader({required this.trip, required this.isCompleted});

  final _CompleteTripMock trip;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.success : AppColors.primaryNavy,
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
              isCompleted ? Icons.verified_rounded : Icons.fact_check_outlined,
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
                  isCompleted ? 'Trip completed' : 'Ready for completion',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${trip.shipmentId} has pickup and delivery proof ready for final review.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.surfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: isCompleted ? 'Completed' : 'Final check',
            tone: isCompleted
                ? StatusBadgeTone.completed
                : StatusBadgeTone.warning,
          ),
        ],
      ),
    );
  }
}

class _TripCompletedSuccessCard extends StatelessWidget {
  const _TripCompletedSuccessCard({required this.trip});

  final _CompleteTripMock trip;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 34,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Completion recorded',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${trip.shipmentId} is now marked completed with proof references and payout ${trip.payout}.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const StatusBadge(
                    label: 'Success state',
                    tone: StatusBadgeTone.completed,
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

class _DistanceTimeCard extends StatelessWidget {
  const _DistanceTimeCard({required this.trip});

  final _CompleteTripMock trip;

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
                const Icon(Icons.route_outlined, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Trip distance and time',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const StatusBadge(
                  label: 'Recorded',
                  tone: StatusBadgeTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 560;
                final metrics = [
                  _MetricItem(
                    icon: Icons.social_distance_rounded,
                    label: 'Distance covered',
                    value: trip.totalDistance,
                  ),
                  _MetricItem(
                    icon: Icons.timer_outlined,
                    label: 'Drive time',
                    value: trip.driveTime,
                  ),
                  _MetricItem(
                    icon: Icons.schedule_rounded,
                    label: 'Delivered at',
                    value: trip.deliveryTimestamp,
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: [
                      for (var index = 0; index < metrics.length; index++) ...[
                        Expanded(child: metrics[index]),
                        if (index != metrics.length - 1)
                          const SizedBox(width: AppSpacing.md),
                      ],
                    ],
                  );
                }

                return Column(
                  children: [
                    for (var index = 0; index < metrics.length; index++) ...[
                      metrics[index],
                      if (index != metrics.length - 1)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofCards extends StatelessWidget {
  const _ProofCards({required this.trip});

  final _CompleteTripMock trip;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _ProofCard(
            icon: Icons.inventory_2_outlined,
            title: 'Pickup proof',
            reference: trip.pickupProofReference,
            timestamp: trip.pickupTimestamp,
            location: trip.pickupLocation,
          ),
          _ProofCard(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Delivery proof',
            reference: trip.deliveryProofReference,
            timestamp: trip.deliveryTimestamp,
            location: trip.deliveryLocation,
          ),
        ];

        if (constraints.maxWidth >= 620) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards.first),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: cards.last),
            ],
          );
        }

        return Column(
          children: [
            cards.first,
            const SizedBox(height: AppSpacing.md),
            cards.last,
          ],
        );
      },
    );
  }
}

class _ProofCard extends StatelessWidget {
  const _ProofCard({
    required this.icon,
    required this.title,
    required this.reference,
    required this.timestamp,
    required this.location,
  });

  final IconData icon;
  final String title;
  final String reference;
  final String timestamp;
  final String location;

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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Icon(icon, color: AppColors.success),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusBadge(
                  label: reference == 'Pending' ? 'Pending' : 'Uploaded',
                  tone: reference == 'Pending'
                      ? StatusBadgeTone.warning
                      : StatusBadgeTone.completed,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _ProofPhotoPlaceholder(icon: icon),
            const SizedBox(height: AppSpacing.md),
            _InfoRow(
              icon: Icons.confirmation_number_outlined,
              label: 'Proof ref',
              value: reference,
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.schedule_rounded,
              label: 'Time',
              value: timestamp,
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: location,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProofPhotoPlaceholder extends StatelessWidget {
  const _ProofPhotoPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _ProofPatternPainter())),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppColors.primaryBlue),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Proof image stored',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionChecklistCard extends StatelessWidget {
  const _CompletionChecklistCard({
    required this.checkedItems,
    required this.isLocked,
    required this.onChanged,
  });

  final Set<_CompletionChecklistItem> checkedItems;
  final bool isLocked;
  final void Function(_CompletionChecklistItem item, bool? value) onChanged;

  @override
  Widget build(BuildContext context) {
    final completeCount = checkedItems.length;
    final totalCount = _CompletionChecklistItem.values.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.checklist_rtl_rounded,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Completion checklist',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusBadge(
                  label: '$completeCount/$totalCount',
                  tone: completeCount == totalCount
                      ? StatusBadgeTone.completed
                      : StatusBadgeTone.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final item in _CompletionChecklistItem.values)
              CheckboxListTile(
                value: checkedItems.contains(item),
                onChanged: isLocked ? null : (value) => onChanged(item, value),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(item.label),
                subtitle: Text(item.description),
              ),
          ],
        ),
      ),
    );
  }
}

class _EndTripButton extends StatelessWidget {
  const _EndTripButton({
    required this.isCompleted,
    required this.isLoading,
    required this.canSubmit,
    required this.onPressed,
  });

  final bool isCompleted;
  final bool isLoading;
  final bool canSubmit;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: canSubmit ? onPressed : null,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textInverse,
              ),
            )
          : Icon(isCompleted ? Icons.verified_rounded : Icons.flag_rounded),
      label: Text(
        isCompleted
            ? 'Trip completed'
            : isLoading
            ? 'Ending trip...'
            : canSubmit
            ? 'End trip'
            : 'Complete checklist to end trip',
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
        Icon(icon, size: 19, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProofPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.65)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final routePaint = Paint()
      ..color = AppColors.primaryBlue.withValues(alpha: 0.18)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.68)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.2,
        size.width * 0.65,
        size.height * 0.82,
        size.width * 0.82,
        size.height * 0.3,
      );
    canvas.drawPath(path, routePaint);

    final markerPaint = Paint()..color = AppColors.roadYellow;
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.68),
      7,
      markerPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.3),
      7,
      markerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _CompletionChecklistItem {
  pickupProof(
    'Pickup proof reviewed',
    'Pickup condition photo and location metadata are available.',
  ),
  deliveryProof(
    'Delivery proof reviewed',
    'Receiver confirmation and delivery photo are attached.',
  ),
  cargoHandoff(
    'Cargo handoff confirmed',
    'No pending receiver dispute is recorded.',
  ),
  expenseNotes(
    'Trip notes checked',
    'Distance, drive time, and payout details look correct.',
  );

  const _CompletionChecklistItem(this.label, this.description);

  final String label;
  final String description;
}

class _CompleteTripMock {
  const _CompleteTripMock({
    required this.assignmentId,
    required this.shipmentId,
    required this.summaryTrip,
    required this.totalDistance,
    required this.driveTime,
    required this.pickupTimestamp,
    required this.deliveryTimestamp,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.pickupProofReference,
    required this.deliveryProofReference,
    required this.payout,
  });

  factory _CompleteTripMock.fromApi(DriverTripDetail details) {
    final trip = details.trip;
    final pickupProof = _proofOfType(details.proofs, 'pickup');
    final deliveryProof = _proofOfType(details.proofs, 'delivery');
    return _CompleteTripMock(
      assignmentId: trip.id,
      shipmentId: trip.displayId,
      summaryTrip: trip.toTripCardModel(),
      totalDistance: trip.distanceLabel,
      driveTime: trip.durationLabel,
      pickupTimestamp: pickupProof?.timestampLabel ?? 'Pickup proof pending',
      deliveryTimestamp:
          deliveryProof?.timestampLabel ?? 'Delivery proof pending',
      pickupLocation: pickupProof?.locationText ?? trip.pickupAddress,
      deliveryLocation: deliveryProof?.locationText ?? trip.deliveryAddress,
      pickupProofReference: pickupProof?.proofCode ?? 'Pending',
      deliveryProofReference: deliveryProof?.proofCode ?? 'Pending',
      payout: trip.payoutLabel,
    );
  }

  final int assignmentId;
  final String shipmentId;
  final DriverTripMock summaryTrip;
  final String totalDistance;
  final String driveTime;
  final String pickupTimestamp;
  final String deliveryTimestamp;
  final String pickupLocation;
  final String deliveryLocation;
  final String pickupProofReference;
  final String deliveryProofReference;
  final String payout;
}

DriverProof? _proofOfType(List<DriverProof> proofs, String proofType) {
  for (final proof in proofs) {
    if (proof.proofType == proofType) {
      return proof;
    }
  }
  return null;
}
