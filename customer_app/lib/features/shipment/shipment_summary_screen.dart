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
import 'data/customer_shipment_api.dart';

class ShipmentSummaryScreen extends ConsumerStatefulWidget {
  const ShipmentSummaryScreen({
    super.key,
    required this.shipmentId,
    required this.packageType,
  });

  final String shipmentId;
  final String packageType;

  @override
  ConsumerState<ShipmentSummaryScreen> createState() =>
      _ShipmentSummaryScreenState();
}

class _ShipmentSummaryScreenState extends ConsumerState<ShipmentSummaryScreen> {
  late Future<ShipmentSummaryData> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
  }

  Future<ShipmentSummaryData> _loadSummary() async {
    final api = ref.read(customerShipmentApiProvider);
    final shipmentId = await api.resolveShipmentId(widget.shipmentId);
    return api.getShipmentSummary(shipmentId);
  }

  void _retry() {
    setState(() => _summaryFuture = _loadSummary());
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppScaffold(
      title: 'Shipment summary',
      subtitle: 'Review the booking details before checkout.',
      body: FutureBuilder<ShipmentSummaryData>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading shipment summary');
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error! as ApiException).message
                : 'Unable to load shipment summary.';

            return ErrorStateWidget(
              title: 'Summary unavailable',
              message: message,
              onRetry: _retry,
            );
          }

          final summary = snapshot.data!;
          final shipment = summary.shipment;
          final total = summary.priceEstimate.breakdown.totalAmount.round();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryHero(
                shipmentId: shipment.shipmentCode,
                packageType: shipment.packageType,
                total: total,
              ),
              const SizedBox(height: AppSpacing.lg),
              _SummarySection(
                title: 'Pickup and delivery',
                icon: Icons.route_rounded,
                onEdit: () => context.go(
                  Uri(
                    path: AppRoutes.createShipment,
                    queryParameters: {
                      if (shipment.categoryName?.isNotEmpty == true)
                        'category': shipment.categoryName!,
                      if (shipment.categoryCode?.isNotEmpty == true)
                        'categoryCode': shipment.categoryCode!,
                    },
                  ).toString(),
                ),
                children: [
                  _SummaryLine(
                    label: 'Pickup',
                    value: shipment.pickupAddress,
                    icon: Icons.my_location_rounded,
                  ),
                  _SummaryLine(
                    label: 'Delivery',
                    value: shipment.deliveryAddress,
                    icon: Icons.location_on_outlined,
                  ),
                  _SummaryLine(
                    label: 'Pickup slot',
                    value: _formatDateTime(shipment.pickupDateTime),
                    icon: Icons.event_available_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _SummarySection(
                title: 'Package details',
                icon: Icons.inventory_2_rounded,
                onEdit: () => context.go(
                  Uri(
                    path: AppRoutes.createShipment,
                    queryParameters: {
                      if (shipment.categoryName?.isNotEmpty == true)
                        'category': shipment.categoryName!,
                      if (shipment.categoryCode?.isNotEmpty == true)
                        'categoryCode': shipment.categoryCode!,
                    },
                  ).toString(),
                ),
                children: [
                  _SummaryLine(
                    label: 'Package type',
                    value: shipment.packageType,
                    icon: Icons.category_outlined,
                  ),
                  _SummaryLine(
                    label: 'Weight',
                    value: '${_number(shipment.packageWeightKg)} kg',
                    icon: Icons.scale_outlined,
                  ),
                  _SummaryLine(
                    label: 'Dimensions',
                    value: _dimensions(shipment),
                    icon: Icons.straighten_rounded,
                  ),
                  _SummaryLine(
                    label: 'Vehicle preference',
                    value: _vehicleLabel(shipment.vehiclePreference),
                    icon: Icons.local_shipping_outlined,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _SummarySection(
                title: 'Receiver details',
                icon: Icons.person_pin_circle_outlined,
                onEdit: () => context.go(
                  Uri(
                    path: AppRoutes.createShipment,
                    queryParameters: {
                      if (shipment.categoryName?.isNotEmpty == true)
                        'category': shipment.categoryName!,
                      if (shipment.categoryCode?.isNotEmpty == true)
                        'categoryCode': shipment.categoryCode!,
                    },
                  ).toString(),
                ),
                children: [
                  _SummaryLine(
                    label: 'Receiver',
                    value: shipment.receiverName,
                    icon: Icons.badge_outlined,
                  ),
                  _SummaryLine(
                    label: 'Phone',
                    value: shipment.receiverPhone,
                    icon: Icons.phone_outlined,
                  ),
                  _SummaryLine(
                    label: 'Delivery notes',
                    value: shipment.deliveryNotes?.isNotEmpty == true
                        ? shipment.deliveryNotes!
                        : 'No delivery notes added.',
                    icon: Icons.notes_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DistanceTimeCard(summary: summary),
              const SizedBox(height: AppSpacing.md),
              _PriceBreakdown(breakdown: summary.priceEstimate.breakdown),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () {
                  context.go(
                    Uri(
                      path: AppRoutes.payment,
                      queryParameters: {'shipmentId': shipment.id.toString()},
                    ).toString(),
                  );
                },
                icon: const Icon(Icons.payment_rounded),
                label: const Text('Proceed to checkout'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({
    required this.shipmentId,
    required this.packageType,
    required this.total,
  });

  final String shipmentId;
  final String packageType;
  final int total;

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
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.textInverse.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
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
                      shipmentId,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textInverse,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '$packageType shipment draft',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.surfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Estimated total',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.surfaceMuted),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            _money(total),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppColors.textInverse),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.title,
    required this.icon,
    required this.children,
    required this.onEdit,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
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
      ),
    );
  }
}

class _DistanceTimeCard extends StatelessWidget {
  const _DistanceTimeCard({required this.summary});

  final ShipmentSummaryData summary;

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
          Expanded(
            child: _MetricBlock(
              icon: Icons.social_distance_rounded,
              label: 'Estimated distance',
              value: '${_number(summary.priceEstimate.estimatedDistanceKm)} km',
            ),
          ),
          Container(width: 1, height: 48, color: AppColors.border),
          Expanded(
            child: _MetricBlock(
              icon: Icons.schedule_rounded,
              label: 'Estimated time',
              value: _duration(summary.priceEstimate.estimatedDurationMinutes),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryBlue),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _PriceBreakdown extends StatelessWidget {
  const _PriceBreakdown({required this.breakdown});

  final PriceBreakdownData breakdown;

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
                  Icons.receipt_long_rounded,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Price breakdown',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _PriceLine(label: 'Base fare', amount: breakdown.basePrice.round()),
            _PriceLine(
              label: 'Distance charge',
              amount: breakdown.distanceCharge.round(),
            ),
            _PriceLine(
              label: 'Handling fee',
              amount: breakdown.handlingAmount.round(),
            ),
            _PriceLine(
              label: 'Service fee',
              amount: breakdown.feeAmount.round(),
            ),
            _PriceLine(
              label: 'GST and platform taxes',
              amount: breakdown.taxAmount.round(),
            ),
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total payable',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  _money(breakdown.totalAmount.round()),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryNavy,
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

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(_money(amount), style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

String _formatDateTime(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value.isEmpty ? 'Pickup slot pending' : value;
  }

  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final year = parsed.year.toString();
  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final period = parsed.hour >= 12 ? 'PM' : 'AM';
  return '$day/$month/$year, $hour:$minute $period';
}

String _dimensions(CustomerShipment shipment) {
  final length = shipment.packageLengthCm;
  final width = shipment.packageWidthCm;
  final height = shipment.packageHeightCm;

  if (length == null || width == null || height == null) {
    return 'Not specified';
  }

  return '${_number(length)} x ${_number(width)} x ${_number(height)} cm';
}

String _duration(int minutes) {
  if (minutes < 60) {
    return '$minutes min';
  }

  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (remaining == 0) {
    return '$hours hr';
  }
  return '$hours hr $remaining min';
}

String _vehicleLabel(String value) {
  return switch (value) {
    'bike' => 'Bike or mini van',
    'mini_truck' => 'Pickup truck',
    'truck' => '14 ft truck',
    'heavy_truck' => '32 ft container',
    'refrigerated_truck' => 'Reefer vehicle',
    'van' => 'Cushioned van',
    _ => value.replaceAll('_', ' '),
  };
}

String _number(double value) {
  if (value % 1 == 0) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}

String _money(int value) {
  final text = value.toString();
  if (text.length <= 3) {
    return 'INR $text';
  }

  final lastThree = text.substring(text.length - 3);
  var leading = text.substring(0, text.length - 3);
  final groups = <String>[];

  while (leading.length > 2) {
    groups.insert(0, leading.substring(leading.length - 2));
    leading = leading.substring(0, leading.length - 2);
  }

  if (leading.isNotEmpty) {
    groups.insert(0, leading);
  }

  return 'INR ${[...groups, lastThree].join(',')}';
}
