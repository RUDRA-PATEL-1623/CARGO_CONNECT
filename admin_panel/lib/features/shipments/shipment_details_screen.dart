import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/mock_admin_data.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/admin_dialog.dart';
import '../../core/widgets/admin_state_widgets.dart';
import '../../core/widgets/admin_status_badge.dart';
import 'widgets/shipment_decision_dialogs.dart';

class ShipmentDetailsScreen extends ConsumerStatefulWidget {
  const ShipmentDetailsScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  ConsumerState<ShipmentDetailsScreen> createState() =>
      _ShipmentDetailsScreenState();
}

class _ShipmentDetailsScreenState extends ConsumerState<ShipmentDetailsScreen> {
  AdminShipmentDetailsData? _data;
  bool _isLoading = true;
  String? _errorMessage;
  String? _statusOverride;
  String? _decisionAudit;

  AdminShipmentManagementMock? get _shipment => _data?.shipment;

  AdminShipmentDetailMock? get _detail => _data?.detail;

  String get _currentStatus =>
      _statusOverride ?? _shipment?.status ?? 'Unknown';

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
      final data = await ref
          .read(adminApiServiceProvider)
          .fetchShipmentDetails(widget.shipmentId);
      if (!mounted) {
        return;
      }
      setState(() {
        _data = data;
        _statusOverride = null;
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

  void _updateStatus(String status, {String? auditMessage}) {
    setState(() {
      _statusOverride = status;
      if (auditMessage != null) {
        _decisionAudit = auditMessage;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          auditMessage == null || auditMessage.isEmpty
              ? '${widget.shipmentId} marked as $status.'
              : '${widget.shipmentId} marked as $status. $auditMessage',
        ),
      ),
    );
  }

  Future<void> _approveShipment(
    AdminShipmentManagementMock shipment,
    AdminShipmentDetailMock detail,
  ) async {
    final result = await showShipmentApprovalDialog(
      context: context,
      shipmentId: shipment.id,
      customerName: detail.customerName,
    );
    if (!mounted || result == null) {
      return;
    }

    try {
      final updatedShipment = await ref
          .read(adminApiServiceProvider)
          .approveShipment(shipment: shipment, notes: result.notes);
      if (!mounted) {
        return;
      }
      setState(() {
        _data = AdminShipmentDetailsData(
          shipment: updatedShipment,
          detail: detail,
          proofs: _data?.proofs ?? const [],
          tripLogs: _data?.tripLogs ?? const [],
        );
      });
      _updateStatus(
        updatedShipment.status,
        auditMessage: result.notes.isEmpty
            ? 'Approved without extra notes.'
            : 'Notes: ${result.notes}',
      );
    } on ApiException catch (error) {
      _showApiError(error.message);
    }
  }

  Future<void> _cancelShipment(
    AdminShipmentManagementMock shipment,
    AdminShipmentDetailMock detail,
  ) async {
    final isPendingShipment = _currentStatus == 'Pending';
    final result = await showShipmentCancellationDialog(
      context: context,
      shipmentId: shipment.id,
      customerName: detail.customerName,
      isPendingShipment: isPendingShipment,
    );
    if (!mounted || result == null) {
      return;
    }

    final notes = result.notes.isEmpty ? '' : ' Notes: ${result.notes}';
    try {
      final service = ref.read(adminApiServiceProvider);
      final updatedShipment = isPendingShipment
          ? await service.rejectShipment(
              shipment: shipment,
              reason: result.reason,
            )
          : await service.cancelShipment(
              shipment: shipment,
              reason: result.reason,
            );
      if (!mounted) {
        return;
      }
      setState(() {
        _data = AdminShipmentDetailsData(
          shipment: updatedShipment,
          detail: detail,
          proofs: _data?.proofs ?? const [],
          tripLogs: _data?.tripLogs ?? const [],
        );
      });
      _updateStatus(
        updatedShipment.status,
        auditMessage: 'Reason: ${result.reason}.$notes',
      );
    } on ApiException catch (error) {
      _showApiError(error.message);
    }
  }

  void _showActionPlaceholder(String title, String message, IconData icon) {
    showAdminDialog(
      context: context,
      title: title,
      message: message,
      icon: icon,
    );
  }

  void _showApiError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.danger, content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shipment = _shipment;
    final detail = _detail;

    if (_isLoading) {
      return const AdminLoadingState(message: 'Loading shipment details...');
    }

    if (_errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.shipments),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to shipments'),
          ),
          const SizedBox(height: AppSpacing.lg),
          AdminErrorState(
            title: 'Shipment details unavailable',
            message: _errorMessage!,
            onRetry: _loadDetails,
          ),
        ],
      );
    }

    if (shipment == null || detail == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.shipments),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to shipments'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AdminEmptyState(
            title: 'Shipment not found',
            message: 'Select a shipment from the management list.',
            icon: Icons.inventory_2_outlined,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShipmentDetailsHeader(
          shipment: shipment,
          status: _currentStatus,
          onBack: () => context.go(AppRoutes.shipments),
        ),
        const SizedBox(height: AppSpacing.lg),
        _StatusTimeline(currentStatus: _currentStatus),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final primaryColumn = Column(
              children: [
                _PartyDetailsCard(detail: detail),
                const SizedBox(height: AppSpacing.md),
                _RouteDetailsCard(detail: detail),
                const SizedBox(height: AppSpacing.md),
                _PackageDetailsCard(shipment: shipment, detail: detail),
              ],
            );

            final sideColumn = Column(
              children: [
                _PaymentInvoiceCard(shipment: shipment, detail: detail),
                const SizedBox(height: AppSpacing.md),
                _ProofPlaceholders(
                  shipment: shipment,
                  currentStatus: _currentStatus,
                  proofs: _data?.proofs ?? const [],
                ),
                const SizedBox(height: AppSpacing.md),
                _AdminActionsCard(
                  status: _currentStatus,
                  notes: _decisionAudit == null
                      ? detail.adminNotes
                      : '${detail.adminNotes}\n\nDecision log: $_decisionAudit',
                  onApprove: () => _approveShipment(shipment, detail),
                  onAssign: () =>
                      context.go(AppRoutes.shipmentAssignmentFor(shipment.id)),
                  onCancel: () => _cancelShipment(shipment, detail),
                  onInvoice: () => context.go(AppRoutes.invoices),
                  onMessageCustomer: () => _showActionPlaceholder(
                    'Customer messaging unavailable',
                    'Messaging is not available in the local backend. Use the customer contact details on this screen.',
                    Icons.mark_email_unread_outlined,
                  ),
                ),
              ],
            );

            if (constraints.maxWidth >= 1040) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: primaryColumn),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: sideColumn),
                ],
              );
            }

            return Column(
              children: [
                primaryColumn,
                const SizedBox(height: AppSpacing.md),
                sideColumn,
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ShipmentDetailsHeader extends StatelessWidget {
  const _ShipmentDetailsHeader({
    required this.shipment,
    required this.status,
    required this.onBack,
  });

  final AdminShipmentManagementMock shipment;
  final String status;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final title = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to shipments'),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      shipment.id,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    AdminStatusBadge.fromStatus(status),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${shipment.route} - ${shipment.category}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            );

            final summary = Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _HeaderMetric(label: 'Driver', value: shipment.driver),
                _HeaderMetric(label: 'Vehicle', value: shipment.vehicle),
                _HeaderMetric(label: 'Amount', value: shipment.amount),
              ],
            );

            if (constraints.maxWidth >= 920) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: title),
                  const SizedBox(width: AppSpacing.lg),
                  summary,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: AppSpacing.lg),
                summary,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _PartyDetailsCard extends StatelessWidget {
  const _PartyDetailsCard({required this.detail});

  final AdminShipmentDetailMock detail;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Customer and receiver',
      icon: Icons.people_alt_outlined,
      children: [
        _InfoRow(label: 'Customer', value: detail.customerName),
        _InfoRow(label: 'Customer email', value: detail.customerEmail),
        _InfoRow(label: 'Customer phone', value: detail.customerPhone),
        const Divider(height: AppSpacing.lg),
        _InfoRow(label: 'Receiver', value: detail.receiverName),
        _InfoRow(label: 'Receiver phone', value: detail.receiverPhone),
      ],
    );
  }
}

class _RouteDetailsCard extends StatelessWidget {
  const _RouteDetailsCard({required this.detail});

  final AdminShipmentDetailMock detail;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Pickup and delivery',
      icon: Icons.route_outlined,
      children: [
        _RoutePoint(
          icon: Icons.my_location_rounded,
          label: 'Pickup',
          address: detail.pickupAddress,
          color: AppColors.primaryBlue,
        ),
        const SizedBox(height: AppSpacing.md),
        _RoutePoint(
          icon: Icons.location_on_outlined,
          label: 'Delivery',
          address: detail.deliveryAddress,
          color: AppColors.accentOrange,
        ),
      ],
    );
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.icon,
    required this.label,
    required this.address,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String address;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSpacing.xxs),
              Text(address, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _PackageDetailsCard extends StatelessWidget {
  const _PackageDetailsCard({required this.shipment, required this.detail});

  final AdminShipmentManagementMock shipment;
  final AdminShipmentDetailMock detail;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Package and shipment',
      icon: Icons.inventory_2_outlined,
      children: [
        _InfoRow(label: 'Category', value: shipment.category),
        _InfoRow(label: 'Package', value: detail.packageType),
        _InfoRow(label: 'Weight', value: detail.weight),
        _InfoRow(label: 'Dimensions', value: detail.dimensions),
        _InfoRow(label: 'Pickup date', value: shipment.pickupDate),
        _InfoRow(label: 'Vehicle preference', value: shipment.vehicle),
      ],
    );
  }
}

class _PaymentInvoiceCard extends StatelessWidget {
  const _PaymentInvoiceCard({required this.shipment, required this.detail});

  final AdminShipmentManagementMock shipment;
  final AdminShipmentDetailMock detail;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Payment and invoice',
      icon: Icons.receipt_long_outlined,
      children: [
        _InfoRow(label: 'Payment method', value: detail.paymentMethod),
        _BadgeInfoRow(
          label: 'Payment status',
          badge: AdminStatusBadge.fromStatus(detail.paymentStatus),
        ),
        _InfoRow(label: 'Invoice', value: detail.invoiceNumber),
        _BadgeInfoRow(
          label: 'Invoice status',
          badge: AdminStatusBadge.fromStatus(detail.invoiceStatus),
        ),
        _InfoRow(label: 'Total amount', value: shipment.amount),
      ],
    );
  }
}

class _ProofPlaceholders extends StatelessWidget {
  const _ProofPlaceholders({
    required this.shipment,
    required this.currentStatus,
    required this.proofs,
  });

  final AdminShipmentManagementMock shipment;
  final String currentStatus;
  final List<Map<String, dynamic>> proofs;

  @override
  Widget build(BuildContext context) {
    final statusIndex = _statusIndex(currentStatus);
    final pickupReady = statusIndex >= 4 || currentStatus == 'Delivered';
    final deliveryReady = statusIndex >= 6 || currentStatus == 'Completed';
    final pickupProof = _proofFor(proofs, 'pickup');
    final deliveryProof = _proofFor(proofs, 'delivery');

    return _SectionCard(
      title: 'Proof uploads',
      icon: Icons.image_search_outlined,
      children: [
        _ProofTile(
          title: 'Pickup proof',
          available: pickupProof.isNotEmpty || pickupReady,
          uploadedBy: _proofText(
            pickupProof,
            'uploadedByName',
            fallback: shipment.driver,
          ),
          timestamp: _proofTime(
            pickupProof,
            fallback: pickupReady ? 'Pickup proof recorded' : 'Awaiting upload',
          ),
          location: _proofLocation(
            pickupProof,
            fallback: pickupReady
                ? 'Pickup proof recorded'
                : 'Location pending',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _ProofTile(
          title: 'Delivery proof',
          available: deliveryProof.isNotEmpty || deliveryReady,
          uploadedBy: _proofText(
            deliveryProof,
            'uploadedByName',
            fallback: shipment.driver,
          ),
          timestamp: _proofTime(
            deliveryProof,
            fallback: deliveryReady
                ? 'Delivery proof recorded'
                : 'Awaiting upload',
          ),
          location: _proofLocation(
            deliveryProof,
            fallback: deliveryReady
                ? 'Delivery proof recorded'
                : 'Location pending',
          ),
        ),
      ],
    );
  }
}

class _ProofTile extends StatelessWidget {
  const _ProofTile({
    required this.title,
    required this.available,
    required this.uploadedBy,
    required this.timestamp,
    required this.location,
  });

  final String title;
  final bool available;
  final String uploadedBy;
  final String timestamp;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: available
            ? AppColors.success.withValues(alpha: 0.06)
            : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: available
              ? AppColors.success.withValues(alpha: 0.22)
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              available ? Icons.verified_outlined : Icons.image_outlined,
              color: available ? AppColors.success : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    AdminStatusBadge(
                      label: available ? 'Verified' : 'Pending',
                      tone: available
                          ? AdminStatusTone.success
                          : AdminStatusTone.warning,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Uploaded by: $uploadedBy'),
                Text(timestamp, style: Theme.of(context).textTheme.bodySmall),
                Text(location, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminActionsCard extends StatelessWidget {
  const _AdminActionsCard({
    required this.status,
    required this.notes,
    required this.onApprove,
    required this.onAssign,
    required this.onCancel,
    required this.onInvoice,
    required this.onMessageCustomer,
  });

  final String status;
  final String notes;
  final VoidCallback onApprove;
  final VoidCallback onAssign;
  final VoidCallback onCancel;
  final VoidCallback onInvoice;
  final VoidCallback onMessageCustomer;

  @override
  Widget build(BuildContext context) {
    final terminal =
        status == 'Delivered' ||
        status == 'Completed' ||
        status == 'Cancelled' ||
        status == 'Rejected';

    return _SectionCard(
      title: 'Admin actions',
      icon: Icons.admin_panel_settings_outlined,
      children: [
        Text(notes, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ElevatedButton.icon(
              onPressed: status == 'Pending' ? onApprove : null,
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Approve'),
            ),
            OutlinedButton.icon(
              onPressed: terminal ? null : onAssign,
              icon: const Icon(Icons.assignment_ind_outlined),
              label: const Text('Assign'),
            ),
            OutlinedButton.icon(
              onPressed: terminal ? null : onCancel,
              icon: const Icon(Icons.cancel_outlined),
              label: Text(status == 'Pending' ? 'Reject' : 'Cancel'),
            ),
            OutlinedButton.icon(
              onPressed: onInvoice,
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Invoice'),
            ),
            OutlinedButton.icon(
              onPressed: onMessageCustomer,
              icon: const Icon(Icons.mark_email_unread_outlined),
              label: const Text('Message'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.currentStatus});

  final String currentStatus;

  @override
  Widget build(BuildContext context) {
    final stopped = currentStatus == 'Cancelled' || currentStatus == 'Rejected';
    final statuses = stopped
        ? ['Pending', currentStatus]
        : const [
            'Pending',
            'Approved',
            'Assigned',
            'Accepted',
            'Pickup Completed',
            'In Transit',
            'Delivered',
            'Completed',
          ];
    final currentIndex = stopped
        ? 1
        : _statusIndex(currentStatus).clamp(0, statuses.length - 1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current status timeline',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var index = 0; index < statuses.length; index++) ...[
                        Expanded(
                          child: _TimelineStep(
                            label: statuses[index],
                            state: _timelineState(index, currentIndex),
                            timestamp: _timelineTimestamp(index, currentIndex),
                          ),
                        ),
                        if (index != statuses.length - 1)
                          const SizedBox(width: AppSpacing.sm),
                      ],
                    ],
                  );
                }

                return Column(
                  children: [
                    for (var index = 0; index < statuses.length; index++) ...[
                      _TimelineStep(
                        label: statuses[index],
                        state: _timelineState(index, currentIndex),
                        timestamp: _timelineTimestamp(index, currentIndex),
                        compact: false,
                      ),
                      if (index != statuses.length - 1)
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

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.state,
    required this.timestamp,
    this.compact = true,
  });

  final String label;
  final _TimelineStepState state;
  final String timestamp;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _TimelineStepState.completed => AppColors.success,
      _TimelineStepState.current => AppColors.primaryBlue,
      _TimelineStepState.pending => AppColors.textSecondary,
    };
    final icon = switch (state) {
      _TimelineStepState.completed => Icons.check_rounded,
      _TimelineStepState.current => Icons.radio_button_checked_rounded,
      _TimelineStepState.pending => Icons.radio_button_unchecked_rounded,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: compact
          ? Column(
              children: [
                Icon(icon, color: color),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  timestamp,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            )
          : Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        timestamp,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
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
            width: 132,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _BadgeInfoRow extends StatelessWidget {
  const _BadgeInfoRow({required this.label, required this.badge});

  final String label;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 132,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: badge),
          ),
        ],
      ),
    );
  }
}

enum _TimelineStepState { completed, current, pending }

int _statusIndex(String status) {
  return switch (status) {
    'Pending' => 0,
    'Approved' => 1,
    'Assigned' => 2,
    'Accepted' => 3,
    'Pickup Completed' => 4,
    'In Transit' => 5,
    'Delivered' => 6,
    'Completed' => 7,
    _ => 0,
  };
}

_TimelineStepState _timelineState(int index, int currentIndex) {
  if (index < currentIndex) {
    return _TimelineStepState.completed;
  }
  if (index == currentIndex) {
    return _TimelineStepState.current;
  }
  return _TimelineStepState.pending;
}

String _timelineTimestamp(int index, int currentIndex) {
  if (index > currentIndex) {
    return 'Pending';
  }

  const timestamps = [
    'Apr 28, 09:10 AM',
    'Apr 28, 09:35 AM',
    'Apr 28, 10:05 AM',
    'Apr 28, 10:28 AM',
    'Apr 28, 02:15 PM',
    'Apr 28, 03:00 PM',
    'Apr 28, 06:40 PM',
    'Apr 28, 07:05 PM',
  ];

  if (index >= timestamps.length) {
    return 'Just now';
  }

  return timestamps[index];
}

Map<String, dynamic> _proofFor(
  List<Map<String, dynamic>> proofs,
  String proofType,
) {
  final normalized = proofType.toLowerCase();
  for (final proof in proofs) {
    final value = proof['proofType']?.toString().toLowerCase() ?? '';
    if (value.contains(normalized)) {
      return proof;
    }
  }
  return const <String, dynamic>{};
}

String _proofText(
  Map<String, dynamic> proof,
  String key, {
  required String fallback,
}) {
  final value = proof[key]?.toString().trim();
  return value == null || value.isEmpty ? fallback : value;
}

String _proofTime(Map<String, dynamic> proof, {required String fallback}) {
  final value = proof['uploadedAt'] ?? proof['createdAt'];
  final parsed = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (parsed == null) {
    return fallback;
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final suffix = parsed.hour >= 12 ? 'PM' : 'AM';
  return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year} - $hour:$minute $suffix';
}

String _proofLocation(Map<String, dynamic> proof, {required String fallback}) {
  final location = proof['locationText']?.toString().trim();
  if (location != null && location.isNotEmpty) {
    return location;
  }
  final lat = proof['latitude']?.toString().trim();
  final lng = proof['longitude']?.toString().trim();
  if (lat != null && lat.isNotEmpty && lng != null && lng.isNotEmpty) {
    return '$lat, $lng';
  }
  return fallback;
}
