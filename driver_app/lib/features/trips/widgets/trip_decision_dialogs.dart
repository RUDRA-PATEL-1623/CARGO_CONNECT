import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class TripRejectionResult {
  const TripRejectionResult({required this.reason, required this.notes});

  final String reason;
  final String notes;
}

Future<bool> showTripAcceptConfirmation(
  BuildContext context, {
  required String shipmentId,
  required String pickup,
  required String delivery,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Accept trip?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accepting confirms this backend assignment and updates dispatch.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            _TripDecisionSummary(
              shipmentId: shipmentId,
              pickup: pickup,
              delivery: delivery,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Accept'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

Future<TripRejectionResult?> showTripRejectReasonSheet(
  BuildContext context, {
  required String shipmentId,
  required String pickup,
  required String delivery,
}) {
  return showModalBottomSheet<TripRejectionResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _RejectReasonSheet(
        shipmentId: shipmentId,
        pickup: pickup,
        delivery: delivery,
      );
    },
  );
}

class _TripDecisionSummary extends StatelessWidget {
  const _TripDecisionSummary({
    required this.shipmentId,
    required this.pickup,
    required this.delivery,
  });

  final String shipmentId;
  final String pickup;
  final String delivery;

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
          Text(shipmentId, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _SummaryLine(label: 'Pickup', value: pickup),
          const SizedBox(height: AppSpacing.xs),
          _SummaryLine(label: 'Delivery', value: delivery),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 66,
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _RejectReasonSheet extends StatefulWidget {
  const _RejectReasonSheet({
    required this.shipmentId,
    required this.pickup,
    required this.delivery,
  });

  final String shipmentId;
  final String pickup;
  final String delivery;

  @override
  State<_RejectReasonSheet> createState() => _RejectReasonSheetState();
}

class _RejectReasonSheetState extends State<_RejectReasonSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String? _selectedReason;

  static const _reasons = [
    'Vehicle unavailable',
    'Route timing conflict',
    'Load requirements mismatch',
    'Safety concern',
    'Other',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String? _validateReason(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Select a rejection reason';
    }
    return null;
  }

  String? _validateNotes(String? value) {
    final input = value?.trim() ?? '';
    if (input.length > 180) {
      return 'Notes must be 180 characters or fewer';
    }
    return null;
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      TripRejectionResult(
        reason: _selectedReason!,
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.lg,
          AppSpacing.screenPadding,
          AppSpacing.lg + bottomInset,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reject assignment',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            widget.shipmentId,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _TripDecisionSummary(
                  shipmentId: widget.shipmentId,
                  pickup: widget.pickup,
                  delivery: widget.delivery,
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: _selectedReason,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    prefixIcon: Icon(Icons.report_problem_outlined),
                  ),
                  items: [
                    for (final reason in _reasons)
                      DropdownMenuItem(value: reason, child: Text(reason)),
                  ],
                  validator: _validateReason,
                  onChanged: (value) => setState(() => _selectedReason = value),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  maxLength: 180,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Add optional dispatch notes',
                    prefixIcon: Icon(Icons.notes_rounded),
                    alignLabelWithHint: true,
                  ),
                  validator: _validateNotes,
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: AppColors.textInverse,
                  ),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Submit rejection'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
