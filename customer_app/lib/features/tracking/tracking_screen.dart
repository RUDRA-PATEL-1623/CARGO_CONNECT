import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../shipment/data/customer_shipment_api.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, this.shipmentId});

  final String? shipmentId;

  Future<_TrackingViewData> _loadTracking(WidgetRef ref) async {
    final api = ref.read(customerShipmentApiProvider);
    final resolvedId = await api.resolveShipmentId(shipmentId ?? '');
    final tracking = await api.getShipmentTracking(resolvedId);
    final timeline = await api.getShipmentTimeline(resolvedId);

    return _TrackingViewData(
      shipmentId: resolvedId,
      tracking: tracking,
      timeline: timeline,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<_TrackingViewData>(
      future: _loadTracking(ref),
      builder: (context, snapshot) {
        final viewData = snapshot.data;

        return CommonAppScaffold(
          title: 'Live tracking',
          subtitle: viewData == null
              ? 'Loading shipment tracking.'
              : '${viewData.tracking.currentStatus.label} shipment updates.',
          bottomNavigationIndex: 2,
          body: Builder(
            builder: (context) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget(message: 'Loading live tracking');
              }

              if (snapshot.hasError || viewData == null) {
                return ErrorStateWidget(
                  title: 'Tracking unavailable',
                  message: _errorMessage(snapshot.error),
                  onRetry: () => context.go(AppRoutes.shipmentHistory),
                );
              }

              return _TrackingBody(viewData: viewData);
            },
          ),
        );
      },
    );
  }
}

class _TrackingBody extends StatelessWidget {
  const _TrackingBody({required this.viewData});

  final _TrackingViewData viewData;

  @override
  Widget build(BuildContext context) {
    final tracking = viewData.tracking;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MapPlaceholder(data: tracking),
        const SizedBox(height: AppSpacing.lg),
        _CurrentStatusCard(status: tracking.currentStatus),
        const SizedBox(height: AppSpacing.lg),
        _EtaAndRouteSummary(data: tracking),
        const SizedBox(height: AppSpacing.lg),
        _DriverAndVehicleSection(assignment: tracking.assignment),
        const SizedBox(height: AppSpacing.lg),
        _TrackingActions(
          canCallDriver: tracking.actions.callDriverEnabled,
          onCallDriver: () => _showDriverCallFallback(context),
          onDetails: () => context.go(
            Uri(
              path: AppRoutes.shipmentDetails,
              queryParameters: {'shipmentId': viewData.shipmentId.toString()},
            ).toString(),
          ),
          onSupport: () => context.push(AppRoutes.support),
        ),
        const SizedBox(height: AppSpacing.lg),
        _TimelinePreview(
          steps: viewData.timeline.steps,
          onOpenTimeline: () => context.go(
            Uri(
              path: AppRoutes.shipmentTimeline,
              queryParameters: {'shipmentId': viewData.shipmentId.toString()},
            ).toString(),
          ),
        ),
      ],
    );
  }

  void _showDriverCallFallback(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Driver calling will be available after verified contact details are assigned.',
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.data});

  final ShipmentTrackingData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: const _RouteMapPainter(),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            top: AppSpacing.md,
            child: _MapBadge(
              icon: Icons.my_location_rounded,
              label: 'Route preview from backend data',
              color: AppColors.primaryBlue,
            ),
          ),
          const Positioned(
            left: 34,
            bottom: 38,
            child: _MapPin(label: 'Pickup', icon: Icons.inventory_2_rounded),
          ),
          const Positioned(
            right: 28,
            top: 70,
            child: _MapPin(label: 'Drop', icon: Icons.flag_rounded),
          ),
          Positioned(
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: _MapBadge(
              icon: Icons.route_rounded,
              label:
                  '${data.routeSummary.estimatedDistanceKm.toStringAsFixed(1)} km route',
              color: AppColors.accentOrange,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentStatusCard extends StatelessWidget {
  const _CurrentStatusCard({required this.status});

  final TrackingStatus status;

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
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current status',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        status.label.isEmpty
                            ? 'Shipment status is being updated'
                            : status.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: _statusFromApi(status.status)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            Text(
              status.locationText?.isNotEmpty ?? false
                  ? 'Last checkpoint: ${status.locationText} at ${_formatDateTime(status.updatedAt)}'
                  : 'Last updated: ${_formatDateTime(status.updatedAt)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _EtaAndRouteSummary extends StatelessWidget {
  const _EtaAndRouteSummary({required this.data});

  final ShipmentTrackingData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.schedule_rounded,
                label: 'ETA',
                value: _formatDateTime(data.eta.estimatedDeliveryAt),
                helper: 'Estimated delivery',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricCard(
                icon: Icons.speed_rounded,
                label: 'Duration',
                value: _durationLabel(data.eta.estimatedDurationMinutes),
                helper: 'Approx. trip time',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _RouteSummaryCard(data: data),
      ],
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({required this.data});

  final ShipmentTrackingData data;

  @override
  Widget build(BuildContext context) {
    final current = data.map.currentLocation?.locationText;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.alt_route_rounded, color: AppColors.info),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Route summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _RoutePoint(
              color: AppColors.success,
              title: 'Pickup',
              value: data.routeSummary.pickupAddress,
            ),
            const _RouteConnector(),
            _RoutePoint(
              color: AppColors.primaryBlue,
              title: 'Current checkpoint',
              value: current?.isNotEmpty ?? false
                  ? current!
                  : 'Driver location pending',
            ),
            const _RouteConnector(),
            _RoutePoint(
              color: AppColors.accentOrange,
              title: 'Delivery',
              value: data.routeSummary.deliveryAddress,
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverAndVehicleSection extends StatelessWidget {
  const _DriverAndVehicleSection({required this.assignment});

  final ShipmentAssignment? assignment;

  @override
  Widget build(BuildContext context) {
    final driver = assignment?.driver;
    final vehicle = assignment?.vehicle;

    return Column(
      children: [
        _InfoCard(
          icon: Icons.account_circle_rounded,
          title: 'Driver details',
          rows: [
            _InfoRow(label: 'Name', value: driver?.name ?? 'Not assigned yet'),
            _InfoRow(
              label: 'Rating',
              value: driver?.rating == null
                  ? 'Rating pending'
                  : '${driver!.rating!.toStringAsFixed(1)} / 5.0',
            ),
            _InfoRow(
              label: 'Phone',
              value: driver?.phoneMasked ?? 'Hidden until assigned',
            ),
            _InfoRow(
              label: 'Trips',
              value: '${driver?.completedTrips ?? 0} completed',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _InfoCard(
          icon: Icons.fire_truck_rounded,
          title: 'Vehicle details',
          rows: [
            _InfoRow(
              label: 'Vehicle',
              value: vehicle?.vehicleType ?? 'Pending',
            ),
            _InfoRow(
              label: 'Plate',
              value: vehicle?.registrationNumber ?? 'Not assigned yet',
            ),
            _InfoRow(
              label: 'Capacity',
              value: vehicle?.capacityKg == null
                  ? 'Capacity pending'
                  : '${vehicle!.capacityKg!.toStringAsFixed(0)} kg',
            ),
            _InfoRow(label: 'Model', value: vehicle?.model ?? 'Model pending'),
          ],
        ),
      ],
    );
  }
}

class _TrackingActions extends StatelessWidget {
  const _TrackingActions({
    required this.canCallDriver,
    required this.onCallDriver,
    required this.onDetails,
    required this.onSupport,
  });

  final bool canCallDriver;
  final VoidCallback onCallDriver;
  final VoidCallback onDetails;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: canCallDriver ? onCallDriver : null,
              icon: const Icon(Icons.call_rounded),
              label: Text(
                canCallDriver ? 'Call driver' : 'Call driver unavailable',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onDetails,
              icon: const Icon(Icons.description_outlined),
              label: const Text('View shipment details'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onSupport,
              icon: const Icon(Icons.support_agent_rounded),
              label: const Text('Contact support'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelinePreview extends StatelessWidget {
  const _TimelinePreview({required this.steps, required this.onOpenTimeline});

  final List<ShipmentTimelineStep> steps;
  final VoidCallback onOpenTimeline;

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
                  Icons.timeline_rounded,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Shipment timeline',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: onOpenTimeline,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Open'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Status flow: Pending to Completed',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            for (var index = 0; index < steps.length; index++)
              _TimelineItem(
                item: steps[index],
                isLast: index == steps.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryBlue),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(helper, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final List<_InfoRow> rows;

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
                Icon(icon, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final row in rows) ...[
              row,
              if (row != rows.last) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.color,
    required this.title,
    required this.value,
  });

  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteConnector extends StatelessWidget {
  const _RouteConnector();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(
        left: 7,
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: SizedBox(
        height: 24,
        child: VerticalDivider(width: 2, thickness: 2, color: AppColors.border),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.item, required this.isLast});

  final ShipmentTimelineStep item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.state) {
      'completed' => AppColors.success,
      'current' => AppColors.primaryBlue,
      _ => AppColors.textSecondary,
    };
    final icon = switch (item.state) {
      'completed' => Icons.check_rounded,
      'current' => Icons.local_shipping_rounded,
      _ => Icons.schedule_rounded,
    };
    final badgeLabel = switch (item.state) {
      'completed' => 'Completed',
      'current' => 'Current',
      _ => 'Pending',
    };
    final badgeColor = switch (item.state) {
      'completed' => const Color(0xFFE8F7ED),
      'current' => const Color(0xFFEAF2FF),
      _ => AppColors.surfaceMuted,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.textInverse, size: 16),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 76,
                color: item.state == 'pending'
                    ? AppColors.border
                    : color.withValues(alpha: 0.35),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    _TimelineStateBadge(
                      label: badgeLabel,
                      foreground: color,
                      background: badgeColor,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  _formatDateTime(item.timestamp),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  item.description?.isNotEmpty ?? false
                      ? item.description!
                      : '${item.label} status update.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineStateBadge extends StatelessWidget {
  const _TimelineStateBadge({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            boxShadow: AppShadows.card,
          ),
          child: Icon(icon, color: AppColors.roadYellow, size: 20),
        ),
        const SizedBox(height: AppSpacing.xxs),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.xs),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            child: Text(label, style: Theme.of(context).textTheme.labelSmall),
          ),
        ),
      ],
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  const _RouteMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFEAF2FF);
    canvas.drawRect(Offset.zero & size, background);

    final gridPaint = Paint()
      ..color = AppColors.textInverse.withValues(alpha: 0.72)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final routePath = Path()
      ..moveTo(size.width * 0.18, size.height * 0.76)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.44,
        size.width * 0.52,
        size.height * 0.72,
        size.width * 0.66,
        size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.74,
        size.height * 0.26,
        size.width * 0.84,
        size.height * 0.34,
        size.width * 0.88,
        size.height * 0.26,
      );

    final routeShadow = Paint()
      ..color = AppColors.primaryNavy.withValues(alpha: 0.16)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(routePath, routeShadow);

    final routePaint = Paint()
      ..color = AppColors.primaryBlue
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(routePath, routePaint);

    final progressPaint = Paint()
      ..color = AppColors.accentOrange
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final progressPath = Path()
      ..moveTo(size.width * 0.18, size.height * 0.76)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.44,
        size.width * 0.52,
        size.height * 0.72,
        size.width * 0.66,
        size.height * 0.42,
      );
    canvas.drawPath(progressPath, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrackingViewData {
  const _TrackingViewData({
    required this.shipmentId,
    required this.tracking,
    required this.timeline,
  });

  final int shipmentId;
  final ShipmentTrackingData tracking;
  final ShipmentTimelineData timeline;
}

ShipmentStatus _statusFromApi(String status) {
  return switch (status) {
    'in_transit' => ShipmentStatus.inTransit,
    'delivered' || 'completed' => ShipmentStatus.delivered,
    'cancelled' || 'rejected' => ShipmentStatus.cancelled,
    _ => ShipmentStatus.booked,
  };
}

String _durationLabel(int? minutes) {
  if (minutes == null || minutes <= 0) {
    return 'Pending';
  }
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (hours == 0) {
    return '$remaining min';
  }
  return remaining == 0 ? '$hours hr' : '$hours hr $remaining min';
}

String _formatDateTime(String? value) {
  final date = DateTime.tryParse(value ?? '');
  if (date == null) {
    return 'Pending';
  }

  final hour = date.hour > 12 ? date.hour - 12 : date.hour;
  final displayHour = hour == 0 ? 12 : hour;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${date.day}/${date.month}/${date.year}, $displayHour:$minute $period';
}

String _errorMessage(Object? error) {
  if (error is ApiException) {
    return error.message;
  }
  return 'Unable to load shipment tracking.';
}
