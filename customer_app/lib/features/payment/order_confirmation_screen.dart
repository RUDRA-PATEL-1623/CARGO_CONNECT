import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({
    super.key,
    required this.bookingId,
    required this.estimatedPickup,
    this.shipmentId,
    this.invoiceId,
  });

  final String bookingId;
  final String estimatedPickup;
  final String? shipmentId;
  final String? invoiceId;

  @override
  Widget build(BuildContext context) {
    return CommonAppScaffold(
      title: 'Order confirmation',
      subtitle: 'Your shipment booking is confirmed.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ConfirmationHero(
            bookingId: bookingId,
            estimatedPickup: estimatedPickup,
          ),
          const SizedBox(height: AppSpacing.lg),
          _BookingDetailsCard(
            bookingId: bookingId,
            estimatedPickup: estimatedPickup,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () {
              final query = <String, String>{};
              if (shipmentId != null) {
                query['shipmentId'] = shipmentId!;
              }

              context.push(
                Uri(
                  path: AppRoutes.tracking,
                  queryParameters: query,
                ).toString(),
              );
            },
            icon: const Icon(Icons.route_rounded),
            label: const Text('Track shipment'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () {
              final query = <String, String>{};
              if (invoiceId != null) {
                query['invoiceId'] = invoiceId!;
              }

              context.push(
                Uri(path: AppRoutes.invoice, queryParameters: query).toString(),
              );
            },
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text('View invoice'),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.home),
            icon: const Icon(Icons.dashboard_rounded),
            label: const Text('Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationHero extends StatelessWidget {
  const _ConfirmationHero({
    required this.bookingId,
    required this.estimatedPickup,
  });

  final String bookingId;
  final String estimatedPickup;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryNavy, AppColors.primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          const _SuccessPulseIcon(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Shipment booked successfully',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textInverse,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Booking ID $bookingId is ready for pickup assignment.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.surfaceMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          const _PendingStatusBadge(),
          const SizedBox(height: AppSpacing.lg),
          _HeroMetric(
            icon: Icons.schedule_rounded,
            label: 'Estimated pickup',
            value: estimatedPickup,
          ),
        ],
      ),
    );
  }
}

class _SuccessPulseIcon extends StatelessWidget {
  const _SuccessPulseIcon();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.78, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.textInverse.withValues(alpha: 0.14),
          border: Border.all(
            color: AppColors.textInverse.withValues(alpha: 0.26),
            width: 8,
          ),
        ),
        child: const Icon(
          Icons.check_circle_rounded,
          color: AppColors.roadYellow,
          size: 58,
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
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
        color: AppColors.textInverse.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.textInverse.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.roadYellow),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.surfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w800,
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

class _BookingDetailsCard extends StatelessWidget {
  const _BookingDetailsCard({
    required this.bookingId,
    required this.estimatedPickup,
  });

  final String bookingId;
  final String estimatedPickup;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            _DetailRow(
              icon: Icons.confirmation_number_outlined,
              label: 'Booking ID',
              value: bookingId,
            ),
            const Divider(height: AppSpacing.lg),
            const _DetailRow(
              icon: Icons.pending_actions_rounded,
              label: 'Shipment status',
              valueWidget: _PendingStatusBadge(),
            ),
            const Divider(height: AppSpacing.lg),
            _DetailRow(
              icon: Icons.access_time_filled_rounded,
              label: 'Estimated pickup time',
              value: estimatedPickup,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppSpacing.xs),
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xxs),
              valueWidget ??
                  Text(
                    value ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PendingStatusBadge extends StatelessWidget {
  const _PendingStatusBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          'Pending',
          style: TextStyle(
            color: AppColors.warning,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}
