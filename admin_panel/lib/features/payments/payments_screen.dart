import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/mock_admin_data.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/widgets/admin_data_table.dart';
import '../../core/widgets/admin_stat_card.dart';
import '../../core/widgets/admin_state_widgets.dart';
import '../../core/widgets/admin_status_badge.dart';

String _formatDateTime(BuildContext context, DateTime date) {
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatMediumDate(date)} ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
}

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  static const _statusFilters = [
    'All statuses',
    'Paid',
    'Pending',
    'Processing',
    'Failed',
    'Refunded',
  ];
  static const _methodFilters = [
    'All methods',
    'UPI',
    'Card',
    'Corporate Wallet',
    'Cash on Delivery',
    'Bank Transfer',
    'Wallet',
    'Refund',
  ];
  static const _dateFilters = ['All dates', 'Today', 'This Week', 'This Month'];

  final _searchController = TextEditingController();
  List<AdminPaymentManagementMock> _payments = <AdminPaymentManagementMock>[];
  String _query = '';
  String _statusFilter = _statusFilters.first;
  String _methodFilter = _methodFilters.first;
  String _dateFilter = _dateFilters.first;
  bool _isLoading = true;
  bool _hasLoadError = false;

  List<AdminPaymentManagementMock> get _summaryPayments => _payments;

  List<AdminPaymentManagementMock> get _filteredPayments {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = _payments.where((payment) {
      final matchesSearch =
          normalizedQuery.isEmpty ||
          payment.id.toLowerCase().contains(normalizedQuery) ||
          payment.shipmentId.toLowerCase().contains(normalizedQuery) ||
          payment.customer.toLowerCase().contains(normalizedQuery) ||
          payment.amount.toLowerCase().contains(normalizedQuery) ||
          payment.method.toLowerCase().contains(normalizedQuery) ||
          payment.transactionReference.toLowerCase().contains(
            normalizedQuery,
          ) ||
          payment.invoiceNumber.toLowerCase().contains(normalizedQuery);
      final matchesStatus =
          _statusFilter == _statusFilters.first ||
          payment.status == _statusFilter;
      final matchesMethod =
          _methodFilter == _methodFilters.first ||
          payment.method == _methodFilter;
      final matchesDate =
          _dateFilter == _dateFilters.first ||
          payment.dateFilter == _dateFilter;
      return matchesSearch && matchesStatus && matchesMethod && matchesDate;
    }).toList();

    filtered.sort((left, right) => right.date.compareTo(left.date));
    return filtered;
  }

  int get _paidCount =>
      _summaryPayments.where((payment) => payment.status == 'Paid').length;

  int get _pendingCount => _summaryPayments
      .where(
        (payment) =>
            payment.status == 'Pending' || payment.status == 'Processing',
      )
      .length;

  int get _failedCount =>
      _summaryPayments.where((payment) => payment.status == 'Failed').length;

  int get _refundedCount =>
      _summaryPayments.where((payment) => payment.status == 'Refunded').length;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });

    try {
      final payments = await ref.read(adminApiServiceProvider).fetchPayments();
      if (!mounted) {
        return;
      }
      setState(() {
        _payments = payments;
        _isLoading = false;
        _hasLoadError = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasLoadError = true;
      });
      _showMessage(error.message);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _query = '';
      _statusFilter = _statusFilters.first;
      _methodFilter = _methodFilters.first;
      _dateFilter = _dateFilters.first;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showPaymentDetails(AdminPaymentManagementMock payment) async {
    AdminPaymentManagementMock detail = payment;
    try {
      detail = await ref
          .read(adminApiServiceProvider)
          .fetchPaymentDetails(payment);
    } on ApiException catch (error) {
      _showMessage(error.message);
    }

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => _PaymentDetailsDialog(payment: detail),
    );
  }

  void _showActionPlaceholder(AdminPaymentManagementMock payment) {
    final label = payment.status == 'Failed'
        ? 'Retry'
        : payment.status == 'Paid'
        ? 'Refund'
        : 'Reconcile';
    _showMessage('$label action selected for ${payment.id}.');
  }

  @override
  Widget build(BuildContext context) {
    final filteredPayments = _filteredPayments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PaymentsHeader(
          totalCount: _summaryPayments.length,
          paidCount: _paidCount,
          pendingCount: _pendingCount,
          failedCount: _failedCount,
        ),
        const SizedBox(height: AppSpacing.lg),
        _PaymentSummaryGrid(
          totalCount: _summaryPayments.length,
          paidCount: _paidCount,
          pendingCount: _pendingCount,
          failedCount: _failedCount,
          refundedCount: _refundedCount,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_isLoading)
          const AdminLoadingState(message: 'Loading payment ledger...')
        else if (_hasLoadError)
          AdminErrorState(
            title: 'Payment ledger unavailable',
            message:
                'Payment records could not be loaded from the backend API. Retry to restore the payment list.',
            onRetry: _loadPayments,
          )
        else ...[
          _PaymentFilterBar(
            controller: _searchController,
            statusFilters: _statusFilters,
            selectedStatusFilter: _statusFilter,
            methodFilters: _methodFilters,
            selectedMethodFilter: _methodFilter,
            dateFilters: _dateFilters,
            selectedDateFilter: _dateFilter,
            onSearchChanged: (value) => setState(() => _query = value),
            onStatusFilterChanged: (value) =>
                setState(() => _statusFilter = value),
            onMethodFilterChanged: (value) =>
                setState(() => _methodFilter = value),
            onDateFilterChanged: (value) => setState(() => _dateFilter = value),
            onClear: _clearFilters,
          ),
          const SizedBox(height: AppSpacing.md),
          _PaymentListMetaCard(
            visibleCount: filteredPayments.length,
            totalCount: _payments.length,
            statusFilter: _statusFilter,
            methodFilter: _methodFilter,
            dateFilter: _dateFilter,
          ),
          const SizedBox(height: AppSpacing.md),
          if (filteredPayments.isEmpty)
            const AdminEmptyState(
              title: 'No payments found',
              message:
                  'Try clearing search, status, method, or date filters to view the ledger.',
              icon: Icons.payments_outlined,
            )
          else
            AdminDataTable(
              dataRowMinHeight: 88,
              dataRowMaxHeight: 116,
              columns: const [
                AdminTableColumn('Payment ID'),
                AdminTableColumn('Shipment ID'),
                AdminTableColumn('Customer'),
                AdminTableColumn('Amount'),
                AdminTableColumn('Method'),
                AdminTableColumn('Status'),
                AdminTableColumn('Date'),
                AdminTableColumn('Actions'),
              ],
              rows: [
                for (final payment in filteredPayments)
                  [
                    _PaymentIdCell(payment: payment),
                    SizedBox(
                      width: 130,
                      child: Text(
                        payment.shipmentId,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    SizedBox(
                      width: 210,
                      child: Text(
                        payment.customer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(
                        payment.amount,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: Text(
                        payment.method,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    AdminStatusBadge.fromStatus(payment.status),
                    SizedBox(
                      width: 170,
                      child: Text(
                        _formatDateTime(context, payment.date),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    _PaymentActions(
                      payment: payment,
                      onView: () => _showPaymentDetails(payment),
                      onAction: () => _showActionPlaceholder(payment),
                    ),
                  ],
              ],
            ),
        ],
      ],
    );
  }
}

class _PaymentsHeader extends StatelessWidget {
  const _PaymentsHeader({
    required this.totalCount,
    required this.paidCount,
    required this.pendingCount,
    required this.failedCount,
  });

  final int totalCount;
  final int paidCount;
  final int pendingCount;
  final int failedCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment management',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Review shipment payments, reconciliation status, methods, and refund exposure from backend report data.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            );

            final badges = Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AdminStatusBadge(
                  label: '$totalCount payments',
                  tone: AdminStatusTone.primary,
                ),
                AdminStatusBadge(
                  label: '$paidCount paid',
                  tone: AdminStatusTone.success,
                ),
                AdminStatusBadge(
                  label: '$pendingCount pending',
                  tone: AdminStatusTone.warning,
                ),
                AdminStatusBadge(
                  label: '$failedCount failed',
                  tone: failedCount == 0
                      ? AdminStatusTone.success
                      : AdminStatusTone.danger,
                ),
              ],
            );

            if (constraints.maxWidth >= 920) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: AppSpacing.lg),
                  Flexible(child: badges),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.md),
                badges,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PaymentSummaryGrid extends StatelessWidget {
  const _PaymentSummaryGrid({
    required this.totalCount,
    required this.paidCount,
    required this.pendingCount,
    required this.failedCount,
    required this.refundedCount,
  });

  final int totalCount;
  final int paidCount;
  final int pendingCount;
  final int failedCount;
  final int refundedCount;

  @override
  Widget build(BuildContext context) {
    final cards = [
      AdminStatCard(
        label: 'Total payments',
        value: '$totalCount',
        delta: 'Ledger records',
        icon: Icons.receipt_long_outlined,
        isPositive: true,
        accentColor: AppColors.primaryBlue,
      ),
      AdminStatCard(
        label: 'Paid',
        value: '$paidCount',
        delta: 'Captured successfully',
        icon: Icons.task_alt_rounded,
        isPositive: true,
        accentColor: AppColors.success,
      ),
      AdminStatCard(
        label: 'Pending review',
        value: '$pendingCount',
        delta: 'Awaiting capture or COD',
        icon: Icons.pending_actions_outlined,
        isPositive: pendingCount == 0,
        accentColor: AppColors.warning,
      ),
      AdminStatCard(
        label: 'Failed/refunded',
        value: '${failedCount + refundedCount}',
        delta: 'Needs reconciliation visibility',
        icon: Icons.report_gmailerrorred_outlined,
        isPositive: failedCount == 0,
        accentColor: AppColors.danger,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1200
            ? 4
            : constraints.maxWidth >= 800
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          itemCount: cards.length,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            mainAxisExtent: 116,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

class _PaymentFilterBar extends StatelessWidget {
  const _PaymentFilterBar({
    required this.controller,
    required this.statusFilters,
    required this.selectedStatusFilter,
    required this.methodFilters,
    required this.selectedMethodFilter,
    required this.dateFilters,
    required this.selectedDateFilter,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.onMethodFilterChanged,
    required this.onDateFilterChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final List<String> statusFilters;
  final String selectedStatusFilter;
  final List<String> methodFilters;
  final String selectedMethodFilter;
  final List<String> dateFilters;
  final String selectedDateFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusFilterChanged;
  final ValueChanged<String> onMethodFilterChanged;
  final ValueChanged<String> onDateFilterChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasSearch = controller.text.trim().isNotEmpty;
    final hasFilters =
        selectedStatusFilter != 'All statuses' ||
        selectedMethodFilter != 'All methods' ||
        selectedDateFilter != 'All dates';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final search = TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Payment, shipment, customer, amount, invoice',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: hasSearch
                    ? IconButton(
                        tooltip: 'Clear search',
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
            );

            final statusFilter = _PaymentDropdown(
              key: ValueKey('payment-status-$selectedStatusFilter'),
              label: 'Status',
              icon: Icons.verified_outlined,
              value: selectedStatusFilter,
              options: statusFilters,
              onChanged: onStatusFilterChanged,
            );

            final methodFilter = _PaymentDropdown(
              key: ValueKey('payment-method-$selectedMethodFilter'),
              label: 'Method',
              icon: Icons.account_balance_wallet_outlined,
              value: selectedMethodFilter,
              options: methodFilters,
              onChanged: onMethodFilterChanged,
            );

            final dateFilter = _PaymentDropdown(
              key: ValueKey('payment-date-$selectedDateFilter'),
              label: 'Date',
              icon: Icons.event_outlined,
              value: selectedDateFilter,
              options: dateFilters,
              onChanged: onDateFilterChanged,
            );

            final resetButton = OutlinedButton.icon(
              onPressed: hasSearch || hasFilters ? onClear : null,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reset'),
            );

            if (constraints.maxWidth >= 1180) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: search),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: statusFilter),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: methodFilter),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: dateFilter),
                  const SizedBox(width: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: resetButton,
                  ),
                ],
              );
            }

            return Column(
              children: [
                search,
                const SizedBox(height: AppSpacing.md),
                statusFilter,
                const SizedBox(height: AppSpacing.md),
                methodFilter,
                const SizedBox(height: AppSpacing.md),
                dateFilter,
                const SizedBox(height: AppSpacing.md),
                Align(alignment: Alignment.centerLeft, child: resetButton),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PaymentDropdown extends StatelessWidget {
  const _PaymentDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: [
        for (final option in options)
          DropdownMenuItem(value: option, child: Text(option)),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _PaymentListMetaCard extends StatelessWidget {
  const _PaymentListMetaCard({
    required this.visibleCount,
    required this.totalCount,
    required this.statusFilter,
    required this.methodFilter,
    required this.dateFilter,
  });

  final int visibleCount;
  final int totalCount;
  final String statusFilter;
  final String methodFilter;
  final String dateFilter;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: const Icon(
                Icons.payments_outlined,
                color: AppColors.primaryBlue,
              ),
            ),
            Text(
              '$visibleCount visible of $totalCount payments',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            AdminStatusBadge(
              label: statusFilter,
              tone: statusFilter == 'All statuses'
                  ? AdminStatusTone.neutral
                  : AdminStatusBadge.fromStatus(statusFilter).tone,
            ),
            AdminStatusBadge(label: methodFilter, tone: AdminStatusTone.info),
            AdminStatusBadge(label: dateFilter, tone: AdminStatusTone.neutral),
          ],
        ),
      ),
    );
  }
}

class _PaymentIdCell extends StatelessWidget {
  const _PaymentIdCell({required this.payment});

  final AdminPaymentManagementMock payment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(payment.id, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            payment.invoiceNumber,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PaymentActions extends StatelessWidget {
  const _PaymentActions({
    required this.payment,
    required this.onView,
    required this.onAction,
  });

  final AdminPaymentManagementMock payment;
  final VoidCallback onView;
  final VoidCallback onAction;

  String get _actionLabel {
    if (payment.status == 'Failed') {
      return 'Retry';
    }
    if (payment.status == 'Paid') {
      return 'Refund';
    }
    return 'Reconcile';
  }

  IconData get _actionIcon {
    if (payment.status == 'Failed') {
      return Icons.refresh_rounded;
    }
    if (payment.status == 'Paid') {
      return Icons.currency_exchange_outlined;
    }
    return Icons.sync_alt_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          TextButton.icon(
            onPressed: onView,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('View'),
          ),
          TextButton.icon(
            onPressed: onAction,
            icon: Icon(_actionIcon, size: 18),
            label: Text(_actionLabel),
          ),
        ],
      ),
    );
  }
}

class _PaymentDetailsDialog extends StatelessWidget {
  const _PaymentDetailsDialog({required this.payment});

  final AdminPaymentManagementMock payment;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Payment details'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AdminStatusBadge.fromStatus(payment.status),
                  AdminStatusBadge(
                    label: payment.method,
                    tone: AdminStatusTone.info,
                  ),
                  AdminStatusBadge(
                    label: payment.dateFilter,
                    tone: AdminStatusTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _PaymentDetailSection(
                title: 'Payment record',
                children: [
                  _PaymentDetailTile(label: 'Payment ID', value: payment.id),
                  _PaymentDetailTile(
                    label: 'Shipment ID',
                    value: payment.shipmentId,
                  ),
                  _PaymentDetailTile(
                    label: 'Customer',
                    value: payment.customer,
                  ),
                  _PaymentDetailTile(
                    label: 'Payment date',
                    value: _formatDateTime(context, payment.date),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _PaymentDetailSection(
                title: 'Amount and method',
                children: [
                  _PaymentDetailTile(label: 'Amount', value: payment.amount),
                  _PaymentDetailTile(label: 'Fee', value: payment.fee),
                  _PaymentDetailTile(
                    label: 'Net amount',
                    value: payment.netAmount,
                  ),
                  _PaymentDetailTile(label: 'Method', value: payment.method),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _PaymentDetailSection(
                title: 'Reconciliation',
                children: [
                  _PaymentDetailTile(
                    label: 'Transaction reference',
                    value: payment.transactionReference,
                  ),
                  _PaymentDetailTile(
                    label: 'Invoice number',
                    value: payment.invoiceNumber,
                  ),
                  _PaymentDetailTile(label: 'Gateway', value: payment.gateway),
                  _PaymentDetailTile(label: 'Notes', value: payment.notes),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _PaymentDetailSection extends StatelessWidget {
  const _PaymentDetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: children,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentDetailTile extends StatelessWidget {
  const _PaymentDetailTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
