import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class ShipmentApprovalResult {
  const ShipmentApprovalResult({required this.notes});

  final String notes;
}

class ShipmentCancellationResult {
  const ShipmentCancellationResult({required this.reason, required this.notes});

  final String reason;
  final String notes;
}

Future<ShipmentApprovalResult?> showShipmentApprovalDialog({
  required BuildContext context,
  required String shipmentId,
  required String customerName,
}) {
  return showDialog<ShipmentApprovalResult>(
    context: context,
    builder: (context) {
      return _ApprovalDialog(
        shipmentId: shipmentId,
        customerName: customerName,
      );
    },
  );
}

Future<ShipmentCancellationResult?> showShipmentCancellationDialog({
  required BuildContext context,
  required String shipmentId,
  required String customerName,
  required bool isPendingShipment,
}) {
  return showDialog<ShipmentCancellationResult>(
    context: context,
    builder: (context) {
      return _CancellationDialog(
        shipmentId: shipmentId,
        customerName: customerName,
        isPendingShipment: isPendingShipment,
      );
    },
  );
}

class _ApprovalDialog extends StatefulWidget {
  const _ApprovalDialog({required this.shipmentId, required this.customerName});

  final String shipmentId;
  final String customerName;

  @override
  State<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<_ApprovalDialog> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: _DialogTitle(
        icon: Icons.verified_outlined,
        title: 'Approve shipment',
        color: AppColors.success,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShipmentSummary(
              shipmentId: widget.shipmentId,
              customerName: widget.customerName,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Approval notes',
                hintText: 'Add optional dispatch or handling notes',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(
              context,
            ).pop(ShipmentApprovalResult(notes: _notesController.text.trim()));
          },
          icon: const Icon(Icons.check_rounded),
          label: const Text('Approve'),
        ),
      ],
    );
  }
}

class _CancellationDialog extends StatefulWidget {
  const _CancellationDialog({
    required this.shipmentId,
    required this.customerName,
    required this.isPendingShipment,
  });

  final String shipmentId;
  final String customerName;
  final bool isPendingShipment;

  @override
  State<_CancellationDialog> createState() => _CancellationDialogState();
}

class _CancellationDialogState extends State<_CancellationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String? _reason;

  static const _rejectionReasons = [
    'Invalid shipment details',
    'Unsupported route',
    'Vehicle unavailable',
    'Payment issue',
    'Customer requested cancellation',
    'Other',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionText = widget.isPendingShipment ? 'Reject' : 'Cancel';

    return AlertDialog(
      title: _DialogTitle(
        icon: Icons.cancel_outlined,
        title: '$actionText shipment',
        color: AppColors.danger,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShipmentSummary(
                shipmentId: widget.shipmentId,
                customerName: widget.customerName,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _reason,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  prefixIcon: Icon(Icons.report_problem_outlined),
                ),
                items: [
                  for (final reason in _rejectionReasons)
                    DropdownMenuItem(
                      value: reason,
                      child: Text(
                        reason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                validator: (value) => value == null ? 'Select a reason' : null,
                onChanged: (value) => setState(() => _reason = value),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _notesController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Add optional context for operations',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop(
              ShipmentCancellationResult(
                reason: _reason!,
                notes: _notesController.text.trim(),
              ),
            );
          },
          icon: const Icon(Icons.block_rounded),
          label: Text(actionText),
        ),
      ],
    );
  }
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(title)),
      ],
    );
  }
}

class _ShipmentSummary extends StatelessWidget {
  const _ShipmentSummary({
    required this.shipmentId,
    required this.customerName,
  });

  final String shipmentId;
  final String customerName;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(shipmentId, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(customerName, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
