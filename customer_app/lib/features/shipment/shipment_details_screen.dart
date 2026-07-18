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
import 'data/customer_shipment_api.dart';

class ShipmentDetailsScreen extends ConsumerWidget {
  const ShipmentDetailsScreen({super.key, required this.shipmentId});

  final String shipmentId;

  Future<ShipmentDetailsData> _loadDetails(WidgetRef ref) async {
    final api = ref.read(customerShipmentApiProvider);
    final resolvedId = await api.resolveShipmentId(shipmentId);
    return api.getShipmentDetails(resolvedId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<ShipmentDetailsData>(
      future: _loadDetails(ref),
      builder: (context, snapshot) {
        final data = snapshot.data;

        return CommonAppScaffold(
          title: 'Shipment details',
          subtitle: data == null
              ? 'Loading shipment record.'
              : 'Operational record for ${data.shipment.shipmentCode}.',
          bottomNavigationIndex: 1,
          body: Builder(
            builder: (context) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget(message: 'Loading shipment details');
              }

              if (snapshot.hasError || data == null) {
                return ErrorStateWidget(
                  title: 'Details unavailable',
                  message: _errorMessage(snapshot.error),
                  onRetry: () => context.go(AppRoutes.shipmentHistory),
                );
              }

              return _DetailsBody(data: data);
            },
          ),
        );
      },
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.data});

  final ShipmentDetailsData data;

  @override
  Widget build(BuildContext context) {
    final shipment = data.shipment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailsHero(data: data),
        const SizedBox(height: AppSpacing.lg),
        _FullShipmentInfo(data: data),
        const SizedBox(height: AppSpacing.md),
        _PaymentAndInvoiceSection(data: data),
        const SizedBox(height: AppSpacing.md),
        _ProofSection(data: data),
        const SizedBox(height: AppSpacing.md),
        _ReceiverInfo(shipment: shipment),
        const SizedBox(height: AppSpacing.md),
        _AdminNotes(status: shipment.shipmentStatus),
        const SizedBox(height: AppSpacing.lg),
        _DetailsActions(
          onTrack: () => context.go(
            Uri(
              path: AppRoutes.tracking,
              queryParameters: {'shipmentId': shipment.id.toString()},
            ).toString(),
          ),
          onInvoice: data.invoice == null
              ? null
              : () => context.go(
                  Uri(
                    path: AppRoutes.invoice,
                    queryParameters: {'invoiceId': data.invoice!.id.toString()},
                  ).toString(),
                ),
          onSupport: () => context.go(AppRoutes.support),
        ),
      ],
    );
  }
}

class _DetailsHero extends StatelessWidget {
  const _DetailsHero({required this.data});

  final ShipmentDetailsData data;

  @override
  Widget build(BuildContext context) {
    final shipment = data.shipment;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.textInverse.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
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
                      shipment.shipmentCode,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _routeLabel(shipment),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.surfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: _statusFromApi(shipment.shipmentStatus)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeroFact(
                  label: 'Pickup',
                  value: _formatDateTime(shipment.pickupDateTime),
                  icon: Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeroFact(
                  label: 'Amount',
                  value: _formatMoney(
                    data.payment?.totalAmount ?? shipment.estimatedPrice,
                  ),
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroFact extends StatelessWidget {
  const _HeroFact({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.textInverse.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: AppColors.textInverse.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.roadYellow, size: 20),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.surfaceMuted),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textInverse,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullShipmentInfo extends StatelessWidget {
  const _FullShipmentInfo({required this.data});

  final ShipmentDetailsData data;

  @override
  Widget build(BuildContext context) {
    final shipment = data.shipment;
    final assignment = data.assignment;

    return _DetailsSection(
      title: 'Shipment information',
      icon: Icons.inventory_2_outlined,
      children: [
        _InfoRow(label: 'Category', value: shipment.categoryName ?? 'Shipment'),
        _InfoRow(label: 'Package type', value: shipment.packageType),
        _InfoRow(
          label: 'Weight',
          value: '${shipment.packageWeightKg.toStringAsFixed(1)} kg',
        ),
        _InfoRow(label: 'Dimensions', value: _dimensionsLabel(shipment)),
        _InfoRow(label: 'Pickup', value: shipment.pickupAddress),
        _InfoRow(label: 'Delivery', value: shipment.deliveryAddress),
        _InfoRow(
          label: 'Pickup slot',
          value: _formatDateTime(shipment.pickupDateTime),
        ),
        _InfoRow(
          label: 'Distance',
          value: '${shipment.estimatedDistanceKm.toStringAsFixed(1)} km',
        ),
        _InfoRow(
          label: 'Vehicle',
          value: assignment?.vehicle?.vehicleType ?? shipment.vehiclePreference,
        ),
        _InfoRow(
          label: 'Vehicle plate',
          value: assignment?.vehicle?.registrationNumber ?? 'Not assigned yet',
        ),
        _InfoRow(
          label: 'Driver',
          value: assignment?.driver?.name ?? 'Not assigned yet',
        ),
        _InfoRow(
          label: 'Driver phone',
          value: assignment?.driver?.phoneMasked ?? 'Hidden until assigned',
        ),
      ],
    );
  }
}

class _PaymentAndInvoiceSection extends StatelessWidget {
  const _PaymentAndInvoiceSection({required this.data});

  final ShipmentDetailsData data;

  @override
  Widget build(BuildContext context) {
    final payment = data.payment;
    final invoice = data.invoice;
    final statusLabel = _titleCase(
      payment?.paymentStatus ?? data.shipment.paymentStatus,
    );

    return _DetailsSection(
      title: 'Payment and invoice',
      icon: Icons.receipt_long_rounded,
      trailing: _PaymentStatusBadge(
        label: statusLabel,
        color: statusLabel.toLowerCase() == 'paid'
            ? AppColors.success
            : AppColors.warning,
      ),
      children: [
        _InfoRow(label: 'Payment status', value: statusLabel),
        _InfoRow(
          label: 'Payment method',
          value: payment?.paymentMethod ?? 'Not captured yet',
        ),
        _InfoRow(
          label: 'Invoice number',
          value: invoice?.invoiceNumber ?? 'Not generated yet',
        ),
        _InfoRow(
          label: 'Total',
          value: _formatMoney(
            payment?.totalAmount ?? data.shipment.estimatedPrice,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: invoice == null
              ? null
              : () => context.go(
                  Uri(
                    path: AppRoutes.invoice,
                    queryParameters: {'invoiceId': invoice.id.toString()},
                  ).toString(),
                ),
          icon: const Icon(Icons.picture_as_pdf_rounded),
          label: Text(invoice == null ? 'Invoice unavailable' : 'Open invoice'),
        ),
      ],
    );
  }
}

class _ProofSection extends StatelessWidget {
  const _ProofSection({required this.data});

  final ShipmentDetailsData data;

  @override
  Widget build(BuildContext context) {
    return _DetailsSection(
      title: 'Proof documents',
      icon: Icons.fact_check_outlined,
      children: [
        if (data.proofs.isEmpty)
          Text(
            'Pickup and delivery proofs will appear after driver upload.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          for (final proof in data.proofs) ...[
            _ProofTile(proof: proof),
            if (proof != data.proofs.last)
              const SizedBox(height: AppSpacing.sm),
          ],
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => context.go(
            Uri(
              path: AppRoutes.shipmentProof,
              queryParameters: {'shipmentId': data.shipment.id.toString()},
            ).toString(),
          ),
          icon: const Icon(Icons.verified_user_outlined),
          label: const Text('View proof documents'),
        ),
      ],
    );
  }
}

class _ReceiverInfo extends StatelessWidget {
  const _ReceiverInfo({required this.shipment});

  final CustomerShipment shipment;

  @override
  Widget build(BuildContext context) {
    return _DetailsSection(
      title: 'Receiver information',
      icon: Icons.person_pin_circle_outlined,
      children: [
        _InfoRow(label: 'Receiver', value: shipment.receiverName),
        _InfoRow(label: 'Phone', value: shipment.receiverPhone),
        _InfoRow(label: 'Address', value: shipment.deliveryAddress),
        _InfoRow(
          label: 'Notes',
          value: shipment.deliveryNotes?.isEmpty ?? true
              ? 'No delivery notes added'
              : shipment.deliveryNotes!,
        ),
      ],
    );
  }
}

class _AdminNotes extends StatelessWidget {
  const _AdminNotes({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return _DetailsSection(
      title: 'Admin notes',
      icon: Icons.admin_panel_settings_outlined,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            'Operations status is ${_titleCase(status)}. Support can be contacted from this record if you need an update.',
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

class _DetailsActions extends StatelessWidget {
  const _DetailsActions({
    required this.onTrack,
    required this.onSupport,
    this.onInvoice,
  });

  final VoidCallback onTrack;
  final VoidCallback? onInvoice;
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
              onPressed: onTrack,
              icon: const Icon(Icons.route_rounded),
              label: const Text('Track shipment'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onInvoice,
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('View invoice'),
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

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

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
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ?trailing,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
      ),
    );
  }
}

class _ProofTile extends StatelessWidget {
  const _ProofTile({required this.proof});

  final ShipmentProofRecord proof;

  @override
  Widget build(BuildContext context) {
    final isVerified = proof.verificationStatus == 'verified';
    final color = isVerified ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            proof.proofType == 'delivery'
                ? Icons.assignment_turned_in_rounded
                : Icons.inventory_2_rounded,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_titleCase(proof.proofType)} proof',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    _PaymentStatusBadge(
                      label: _titleCase(proof.verificationStatus),
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  proof.notes?.isNotEmpty ?? false
                      ? proof.notes!
                      : 'Driver-uploaded proof metadata is available.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  const _PaymentStatusBadge({
    required this.label,
    this.color = AppColors.success,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

ShipmentStatus _statusFromApi(String status) {
  return switch (status) {
    'in_transit' => ShipmentStatus.inTransit,
    'delivered' || 'completed' => ShipmentStatus.delivered,
    'cancelled' || 'rejected' => ShipmentStatus.cancelled,
    _ => ShipmentStatus.booked,
  };
}

String _routeLabel(CustomerShipment shipment) {
  return '${_shortAddress(shipment.pickupAddress)} to ${_shortAddress(shipment.deliveryAddress)}';
}

String _shortAddress(String value) {
  final firstPart = value.split(',').first.trim();
  return firstPart.isEmpty ? 'Address pending' : firstPart;
}

String _dimensionsLabel(CustomerShipment shipment) {
  final length = shipment.packageLengthCm;
  final width = shipment.packageWidthCm;
  final height = shipment.packageHeightCm;
  if (length == null || width == null || height == null) {
    return 'Not provided';
  }
  return '${length.toStringAsFixed(0)} x ${width.toStringAsFixed(0)} x ${height.toStringAsFixed(0)} cm';
}

String _formatMoney(double value) {
  return 'INR ${value.toStringAsFixed(0)}';
}

String _formatDateTime(String? value) {
  final date = DateTime.tryParse(value ?? '');
  if (date == null) {
    return 'Schedule pending';
  }

  final hour = date.hour > 12 ? date.hour - 12 : date.hour;
  final displayHour = hour == 0 ? 12 : hour;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${date.day}/${date.month}/${date.year}, $displayHour:$minute $period';
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _errorMessage(Object? error) {
  if (error is ApiException) {
    return error.message;
  }
  return 'Unable to load this shipment record.';
}
