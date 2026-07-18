import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../shipment/data/customer_shipment_api.dart';
import 'data/customer_support_api.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String _selectedShipmentKey = '';
  String _issueType = 'delay';
  String _priority = 'medium';
  bool _hasAttachmentIntent = false;
  bool _isSubmitting = false;
  bool _isLoading = true;
  String? _loadError;
  String? _submitError;

  var _shipmentOptions = <_ShipmentOption>[];
  var _issues = <CustomerSupportIssue>[];

  static const _issueTypes = [
    _SupportOption(label: 'Booking question', value: 'booking'),
    _SupportOption(label: 'Payment or invoice', value: 'payment'),
    _SupportOption(label: 'Driver communication', value: 'driver'),
    _SupportOption(label: 'Delay or ETA', value: 'delay'),
    _SupportOption(label: 'Damage or proof document', value: 'damage'),
    _SupportOption(label: 'Invoice correction', value: 'invoice'),
    _SupportOption(label: 'Other issue', value: 'other'),
  ];

  static const _priorities = [
    _SupportOption(label: 'Low', value: 'low'),
    _SupportOption(label: 'Medium', value: 'medium'),
    _SupportOption(label: 'High', value: 'high'),
    _SupportOption(label: 'Urgent', value: 'urgent'),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadSupportData());
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSupportData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final history = await ref
          .read(customerShipmentApiProvider)
          .listShipmentHistory(limit: 50);
      final issues = await ref
          .read(customerSupportApiProvider)
          .listIssues(limit: 5);

      if (!mounted) {
        return;
      }

      final shipmentOptions = history.shipments
          .map(
            (shipment) => _ShipmentOption(
              key: shipment.id.toString(),
              label:
                  '${shipment.shipmentCode} - ${_shortAddress(shipment.pickupAddress)} to ${_shortAddress(shipment.deliveryAddress)}',
              shipmentId: shipment.id,
            ),
          )
          .toList(growable: false);

      setState(() {
        _shipmentOptions = [
          const _ShipmentOption(
            key: '',
            label: 'General support request',
            shipmentId: null,
          ),
          ...shipmentOptions,
        ];
        if (!_shipmentOptions.any(
          (option) => option.key == _selectedShipmentKey,
        )) {
          _selectedShipmentKey = _shipmentOptions.first.key;
        }
        _issues = issues.issues;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      _setLoadError(error.message);
    } catch (_) {
      _setLoadError('Unable to load support data.');
    }
  }

  void _setLoadError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _loadError = message;
    });
  }

  String? _requiredSelection(String? value, String label) {
    if (label == 'shipment') {
      return null;
    }
    if (value == null || value.trim().isEmpty) {
      return 'Select $label';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter issue description';
    }
    if (input.length < 20) {
      return 'Description must be at least 20 characters';
    }
    if (input.length > 500) {
      return 'Keep description under 500 characters';
    }
    return null;
  }

  Future<void> _submitIssue() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final shipment = _shipmentOptions.firstWhere(
      (option) => option.key == _selectedShipmentKey,
      orElse: () => const _ShipmentOption(
        key: '',
        label: 'General support request',
        shipmentId: null,
      ),
    );
    final issueLabel = _labelFor(_issueTypes, _issueType);

    try {
      final issue = await ref
          .read(customerSupportApiProvider)
          .createIssue(
            CustomerSupportIssueRequest(
              shipmentId: shipment.shipmentId,
              issueType: _issueType,
              priority: _priority,
              subject: shipment.shipmentId == null
                  ? issueLabel
                  : '$issueLabel for ${shipment.label.split(' - ').first}',
              description: _descriptionController.text,
            ),
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _descriptionController.clear();
        _hasAttachmentIntent = false;
        _issues = [issue, ..._issues.where((item) => item.id != issue.id)];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Support issue ${issue.issueCode} submitted.')),
      );
    } on ApiException catch (error) {
      _setSubmitError(error.message);
    } catch (_) {
      _setSubmitError('Unable to submit support issue.');
    }
  }

  void _setSubmitError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isSubmitting = false;
      _submitError = message;
    });
  }

  void _toggleAttachment() {
    setState(() => _hasAttachmentIntent = !_hasAttachmentIntent);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _hasAttachmentIntent
              ? 'Attachment upload is not available in the customer API yet. The issue will submit without a file.'
              : 'Attachment removed from this issue draft.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppScaffold(
      title: 'Support',
      subtitle: 'Raise an issue for shipment assistance.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SupportHeader(),
          const SizedBox(height: AppSpacing.lg),
          if (_isLoading)
            const LoadingWidget(message: 'Loading support options')
          else if (_loadError != null)
            ErrorStateWidget(
              title: 'Support unavailable',
              message: _loadError!,
              onRetry: _loadSupportData,
            )
          else ...[
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: _IssueFormCard(
                selectedShipmentKey: _selectedShipmentKey,
                issueType: _issueType,
                priority: _priority,
                shipments: _shipmentOptions,
                issueTypes: _issueTypes,
                priorities: _priorities,
                descriptionController: _descriptionController,
                hasAttachmentIntent: _hasAttachmentIntent,
                isSubmitting: _isSubmitting,
                submitError: _submitError,
                onShipmentChanged: (value) =>
                    setState(() => _selectedShipmentKey = value ?? ''),
                onIssueTypeChanged: (value) =>
                    setState(() => _issueType = value ?? _issueType),
                onPriorityChanged: (value) =>
                    setState(() => _priority = value ?? _priority),
                onAttachmentToggle: _toggleAttachment,
                onSubmit: _submitIssue,
                selectionValidator: _requiredSelection,
                descriptionValidator: _validateDescription,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _RecentIssuesCard(issues: _issues),
          ],
          const SizedBox(height: AppSpacing.lg),
          const _ContactAdminCard(),
          const SizedBox(height: AppSpacing.lg),
          const _FaqSection(),
        ],
      ),
    );
  }
}

class _SupportHeader extends StatelessWidget {
  const _SupportHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.textInverse.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
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
                  'Issue support desk',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Share shipment context so operations can respond faster.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.surfaceMuted,
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

class _IssueFormCard extends StatelessWidget {
  const _IssueFormCard({
    required this.selectedShipmentKey,
    required this.issueType,
    required this.priority,
    required this.shipments,
    required this.issueTypes,
    required this.priorities,
    required this.descriptionController,
    required this.hasAttachmentIntent,
    required this.isSubmitting,
    required this.submitError,
    required this.onShipmentChanged,
    required this.onIssueTypeChanged,
    required this.onPriorityChanged,
    required this.onAttachmentToggle,
    required this.onSubmit,
    required this.selectionValidator,
    required this.descriptionValidator,
  });

  final String selectedShipmentKey;
  final String issueType;
  final String priority;
  final List<_ShipmentOption> shipments;
  final List<_SupportOption> issueTypes;
  final List<_SupportOption> priorities;
  final TextEditingController descriptionController;
  final bool hasAttachmentIntent;
  final bool isSubmitting;
  final String? submitError;
  final ValueChanged<String?> onShipmentChanged;
  final ValueChanged<String?> onIssueTypeChanged;
  final ValueChanged<String?> onPriorityChanged;
  final VoidCallback onAttachmentToggle;
  final VoidCallback onSubmit;
  final String? Function(String?, String) selectionValidator;
  final FormFieldValidator<String> descriptionValidator;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.report_problem_outlined,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Create issue',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            if (submitError != null) ...[
              _InlineError(message: submitError!),
              const SizedBox(height: AppSpacing.md),
            ],
            DropdownButtonFormField<String>(
              initialValue: selectedShipmentKey,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Shipment',
                prefixIcon: Icon(Icons.local_shipping_outlined),
              ),
              items: [
                for (final shipment in shipments)
                  DropdownMenuItem(
                    value: shipment.key,
                    child: Text(shipment.label),
                  ),
              ],
              onChanged: isSubmitting ? null : onShipmentChanged,
              validator: (value) => selectionValidator(value, 'shipment'),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final useRow = constraints.maxWidth >= 620;
                final issueField = DropdownButtonFormField<String>(
                  initialValue: issueType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Issue type',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    for (final issue in issueTypes)
                      DropdownMenuItem(
                        value: issue.value,
                        child: Text(issue.label),
                      ),
                  ],
                  onChanged: isSubmitting ? null : onIssueTypeChanged,
                  validator: (value) => selectionValidator(value, 'issue type'),
                );
                final priorityField = DropdownButtonFormField<String>(
                  initialValue: priority,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    prefixIcon: Icon(Icons.priority_high_rounded),
                  ),
                  items: [
                    for (final item in priorities)
                      DropdownMenuItem(
                        value: item.value,
                        child: Text(item.label),
                      ),
                  ],
                  onChanged: isSubmitting ? null : onPriorityChanged,
                  validator: (value) => selectionValidator(value, 'priority'),
                );

                if (!useRow) {
                  return Column(
                    children: [
                      issueField,
                      const SizedBox(height: AppSpacing.md),
                      priorityField,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: issueField),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: priorityField),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: descriptionController,
              enabled: !isSubmitting,
              minLines: 4,
              maxLines: 6,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
                hintText:
                    'Describe the issue, shipment impact, and preferred resolution.',
              ),
              validator: descriptionValidator,
            ),
            const SizedBox(height: AppSpacing.md),
            _AttachmentFallback(
              hasAttachmentIntent: hasAttachmentIntent,
              isSubmitting: isSubmitting,
              onToggle: onAttachmentToggle,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.textInverse,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(isSubmitting ? 'Submitting...' : 'Submit issue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentFallback extends StatelessWidget {
  const _AttachmentFallback({
    required this.hasAttachmentIntent,
    required this.isSubmitting,
    required this.onToggle,
  });

  final bool hasAttachmentIntent;
  final bool isSubmitting;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final color = hasAttachmentIntent
        ? AppColors.warning
        : AppColors.primaryBlue;

    return InkWell(
      onTap: isSubmitting ? null : onToggle,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Icon(
              hasAttachmentIntent
                  ? Icons.info_outline_rounded
                  : Icons.upload_file_outlined,
              color: color,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasAttachmentIntent
                        ? 'Attachment noted'
                        : 'Attachment unavailable',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    hasAttachmentIntent
                        ? 'The current customer API has no file upload for issues, so this request will submit without a file.'
                        : 'Tap to see the current attachment fallback.',
                    style: Theme.of(context).textTheme.bodyMedium,
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

class _RecentIssuesCard extends StatelessWidget {
  const _RecentIssuesCard({required this.issues});

  final List<CustomerSupportIssue> issues;

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
                const Icon(Icons.history_rounded, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Recent issues',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            if (issues.isEmpty)
              const EmptyStateWidget(
                icon: Icons.support_agent_outlined,
                title: 'No support issues',
                message:
                    'Submitted shipment, payment, and delivery issues will appear here.',
              )
            else
              for (final issue in issues) ...[
                _IssueTile(issue: issue),
                if (issue != issues.last) const Divider(height: AppSpacing.lg),
              ],
          ],
        ),
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue});

  final CustomerSupportIssue issue;

  @override
  Widget build(BuildContext context) {
    final color = switch (issue.priority) {
      'urgent' || 'high' => AppColors.danger,
      'medium' => AppColors.warning,
      _ => AppColors.info,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: Icon(Icons.report_problem_outlined, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                issue.subject,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${issue.issueCode}${issue.shipmentCode == null ? '' : ' - ${issue.shipmentCode}'}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                issue.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (issue.adminResponse?.isNotEmpty ?? false) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Admin response: ${issue.adminResponse}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _MiniBadge(label: _titleCase(issue.issueStatus), color: color),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.24)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.danger,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.color});

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

class _ContactAdminCard extends StatelessWidget {
  const _ContactAdminCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: const Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.accentOrange,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact admin',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'CargoConnect Operations Desk',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'support@cargoconnect.local | +91 22 4000 2403',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Use the support form above to create a tracked admin request.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.support_agent_rounded),
                    label: const Text('Contact operations'),
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

class _FaqSection extends StatelessWidget {
  const _FaqSection();

  static const _faqs = [
    _FaqItem(
      question: 'How quickly will support respond?',
      answer:
          'Urgent issues are visible to admins immediately through the backend support queue.',
    ),
    _FaqItem(
      question: 'Can I attach delivery proof?',
      answer:
          'Customer issue file upload is not exposed yet. Driver proof files remain available from shipment details.',
    ),
    _FaqItem(
      question: 'Will this change my shipment status?',
      answer:
          'No. Support issues create a tracked operations request without changing shipment flow.',
    ),
  ];

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
                const Icon(Icons.quiz_outlined, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.sm),
                Text('FAQ', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final faq in _faqs)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
                title: Text(faq.question),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      faq.answer,
                      style: Theme.of(context).textTheme.bodyMedium,
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

class _SupportOption {
  const _SupportOption({required this.label, required this.value});

  final String label;
  final String value;
}

class _ShipmentOption {
  const _ShipmentOption({
    required this.key,
    required this.label,
    required this.shipmentId,
  });

  final String key;
  final String label;
  final int? shipmentId;
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

String _labelFor(List<_SupportOption> options, String value) {
  return options
      .firstWhere(
        (option) => option.value == value,
        orElse: () => _SupportOption(label: _titleCase(value), value: value),
      )
      .label;
}

String _shortAddress(String value) {
  final firstPart = value.split(',').first.trim();
  return firstPart.isEmpty ? 'Address pending' : firstPart;
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
