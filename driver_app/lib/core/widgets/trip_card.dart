import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_shadows.dart';
import '../constants/app_spacing.dart';
import '../utils/mock_driver_data.dart';
import 'status_badge.dart';

class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.trip,
    this.onTap,
    this.primaryActionLabel,
    this.onPrimaryAction,
  });

  final DriverTripMock trip;
  final VoidCallback? onTap;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 560;
              final details = _TripRouteDetails(trip: trip);
              final metrics = _TripMetrics(trip: trip);

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
                              trip.id,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              '${trip.package} - ${trip.vehicle}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      StatusBadge.fromTripStatus(trip.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: details),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(flex: 2, child: metrics),
                      ],
                    )
                  else ...[
                    details,
                    const SizedBox(height: AppSpacing.md),
                    metrics,
                  ],
                  if (primaryActionLabel != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onPrimaryAction,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(primaryActionLabel!),
                      ),
                    ),
                  ],
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

  final DriverTripMock trip;

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

class _TripMetrics extends StatelessWidget {
  const _TripMetrics({required this.trip});

  final DriverTripMock trip;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _MetricRow(
              icon: Icons.social_distance_rounded,
              label: 'Distance',
              value: trip.distance,
            ),
            const Divider(height: AppSpacing.lg),
            _MetricRow(
              icon: Icons.schedule_rounded,
              label: 'ETA',
              value: trip.eta,
            ),
            const Divider(height: AppSpacing.lg),
            _MetricRow(
              icon: Icons.payments_outlined,
              label: 'Payout',
              value: trip.payout,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
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
