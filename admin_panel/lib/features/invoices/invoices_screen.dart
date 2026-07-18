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

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  static const _paymentStatusFilters = [
    'All payment statuses',
    'Paid',
    'Pending',
    'Processing',
    'Failed',
    'Refunded',
  ];
  static const _dateFilters = ['All dates', 'Today', 'This Week', 'This Month'];

  final _searchController = TextEditingController();
  List<AdminInvoiceManagementMock> _invoices = <AdminInvoiceManagementMock>[];
  String _query = '';
  String _paymentStatusFilter = _paymentStatusFilters.first;
  String _dateFilter = _dateFilters.first;
  bool _isLoading = true;
  bool _hasLoadError = false;

  List<AdminInvoiceManagementMock> get _summaryInvoices => _invoices;

  List<AdminInvoiceManagementMock> get _filteredInvoices {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = _invoices.where((invoice) {
      final matchesSearch =
          normalizedQuery.isEmpty ||
          invoice.invoiceNumber.toLowerCase().contains(normalizedQuery) ||
          invoice.shipmentId.toLowerCase().contains(normalizedQuery) ||
          invoice.customer.toLowerCase().contains(normalizedQuery) ||
          invoice.total.toLowerCase().contains(normalizedQuery) ||
          invoice.paymentStatus.toLowerCase().contains(normalizedQuery) ||
          invoice.paymentMethod.toLowerCase().contains(normalizedQuery);
      final matchesStatus =
          _paymentStatusFilter == _paymentStatusFilters.first ||
          invoice.paymentStatus == _paymentStatusFilter;
      final matchesDate =
          _dateFilter == _dateFilters.first ||
          invoice.dateFilter == _dateFilter;
      return matchesSearch && matchesStatus && matchesDate;
    }).toList();

    filtered.sort(
      (left, right) => right.generatedDate.compareTo(left.generatedDate),
    );
    return filtered;
  }

  int get _issuedCount => _summaryInvoices
      .where((invoice) => invoice.invoiceStatus == 'Issued')
      .length;

  int get _paidCount => _summaryInvoices
      .where((invoice) => invoice.paymentStatus == 'Paid')
      .length;

  int get _pendingCount => _summaryInvoices
      .where(
        (invoice) =>
            invoice.paymentStatus == 'Pending' ||
            invoice.paymentStatus == 'Processing',
      )
      .length;

  int get _exceptionCount => _summaryInvoices
      .where(
        (invoice) =>
            invoice.paymentStatus == 'Failed' ||
            invoice.paymentStatus == 'Refunded' ||
            invoice.invoiceStatus == 'Voided',
      )
      .length;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });

    try {
      final invoices = await ref.read(adminApiServiceProvider).fetchInvoices();
      if (!mounted) {
        return;
      }
      setState(() {
        _invoices = invoices;
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
      _paymentStatusFilter = _paymentStatusFilters.first;
      _dateFilter = _dateFilters.first;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showInvoicePreview(AdminInvoiceManagementMock invoice) async {
    AdminInvoiceManagementMock detail = invoice;
    try {
      detail = await ref
          .read(adminApiServiceProvider)
          .fetchInvoiceDetails(invoice);
    } on ApiException catch (error) {
      _showMessage(error.message);
    }

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => _InvoicePreviewDialog(
        invoice: detail,
        onDownload: () => _showDownloadMessage(detail),
      ),
    );
  }

  Future<void> _showDownloadMessage(AdminInvoiceManagementMock invoice) async {
    try {
      final bytes = await ref
          .read(adminApiServiceProvider)
          .downloadInvoicePdf(invoice);
      _showMessage(
        'Invoice PDF downloaded from API ($bytes bytes) for ${invoice.invoiceNumber}.',
      );
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredInvoices = _filteredInvoices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InvoicesHeader(
          totalCount: _summaryInvoices.length,
          issuedCount: _issuedCount,
          paidCount: _paidCount,
          exceptionCount: _exceptionCount,
        ),
        const SizedBox(height: AppSpacing.lg),
        _InvoiceSummaryGrid(
          totalCount: _summaryInvoices.length,
          issuedCount: _issuedCount,
          paidCount: _paidCount,
          pendingCount: _pendingCount,
          exceptionCount: _exceptionCount,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_isLoading)
          const AdminLoadingState(message: 'Loading invoice register...')
        else if (_hasLoadError)
          AdminErrorState(
            title: 'Invoice register unavailable',
            message:
                'Invoice records could not be loaded from the backend API. Retry to restore the invoice register.',
            onRetry: _loadInvoices,
          )
        else ...[
          _InvoiceFilterBar(
            controller: _searchController,
            paymentStatusFilters: _paymentStatusFilters,
            selectedPaymentStatusFilter: _paymentStatusFilter,
            dateFilters: _dateFilters,
            selectedDateFilter: _dateFilter,
            onSearchChanged: (value) => setState(() => _query = value),
            onPaymentStatusFilterChanged: (value) =>
                setState(() => _paymentStatusFilter = value),
            onDateFilterChanged: (value) => setState(() => _dateFilter = value),
            onClear: _clearFilters,
          ),
          const SizedBox(height: AppSpacing.md),
          _InvoiceListMetaCard(
            visibleCount: filteredInvoices.length,
            totalCount: _invoices.length,
            paymentStatusFilter: _paymentStatusFilter,
            dateFilter: _dateFilter,
          ),
          const SizedBox(height: AppSpacing.md),
          if (filteredInvoices.isEmpty)
            const AdminEmptyState(
              title: 'No invoices found',
              message:
                  'Try clearing search, payment status, or generated date filters to view invoices.',
              icon: Icons.receipt_long_outlined,
            )
          else
            AdminDataTable(
              dataRowMinHeight: 88,
              dataRowMaxHeight: 116,
              columns: const [
                AdminTableColumn('Invoice number'),
                AdminTableColumn('Shipment ID'),
                AdminTableColumn('Customer'),
                AdminTableColumn('Total'),
                AdminTableColumn('Payment status'),
                AdminTableColumn('Generated date'),
                AdminTableColumn('Actions'),
              ],
              rows: [
                for (final invoice in filteredInvoices)
                  [
                    _InvoiceNumberCell(invoice: invoice),
                    SizedBox(
                      width: 130,
                      child: Text(
                        invoice.shipmentId,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: Text(
                        invoice.customer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(
                        invoice.total,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    AdminStatusBadge.fromStatus(invoice.paymentStatus),
                    SizedBox(
                      width: 180,
                      child: Text(
                        _formatDateTime(context, invoice.generatedDate),
                      ),
                    ),
                    _InvoiceActions(
                      onView: () => _showInvoicePreview(invoice),
                      onDownload: () => _showDownloadMessage(invoice),
                    ),
                  ],
              ],
            ),
        ],
      ],
    );
  }
}

class _InvoicesHeader extends StatelessWidget {
  const _InvoicesHeader({
    required this.totalCount,
    required this.issuedCount,
    required this.paidCount,
    required this.exceptionCount,
  });

  final int totalCount;
  final int issuedCount;
  final int paidCount;
  final int exceptionCount;

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
                  'Invoice management',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Review generated logistics invoices, payment status, and PDF download exports from backend report data.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            );

            final badges = Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AdminStatusBadge(
                  label: '$totalCount invoices',
                  tone: AdminStatusTone.primary,
                ),
                AdminStatusBadge(
                  label: '$issuedCount issued',
                  tone: AdminStatusTone.success,
                ),
                AdminStatusBadge(
                  label: '$paidCount paid',
                  tone: AdminStatusTone.success,
                ),
                AdminStatusBadge(
                  label: '$exceptionCount exceptions',
                  tone: exceptionCount == 0
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

class _InvoiceSummaryGrid extends StatelessWidget {
  const _InvoiceSummaryGrid({
    required this.totalCount,
    required this.issuedCount,
    required this.paidCount,
    required this.pendingCount,
    required this.exceptionCount,
  });

  final int totalCount;
  final int issuedCount;
  final int paidCount;
  final int pendingCount;
  final int exceptionCount;

  @override
  Widget build(BuildContext context) {
    final cards = [
      AdminStatCard(
        label: 'Total invoices',
        value: '$totalCount',
        delta: 'Generated records',
        icon: Icons.receipt_long_outlined,
        isPositive: true,
        accentColor: AppColors.primaryBlue,
      ),
      AdminStatCard(
        label: 'Issued',
        value: '$issuedCount',
        delta: 'Ready for customer copy',
        icon: Icons.task_alt_rounded,
        isPositive: true,
        accentColor: AppColors.success,
      ),
      AdminStatCard(
        label: 'Paid invoices',
        value: '$paidCount',
        delta: 'Matched to payment',
        icon: Icons.payments_outlined,
        isPositive: true,
        accentColor: AppColors.info,
      ),
      AdminStatCard(
        label: 'Pending or exceptions',
        value: '${pendingCount + exceptionCount}',
        delta: 'Draft, failed, or voided',
        icon: Icons.report_gmailerrorred_outlined,
        isPositive: pendingCount + exceptionCount == 0,
        accentColor: AppColors.warning,
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

class _InvoiceFilterBar extends StatelessWidget {
  const _InvoiceFilterBar({
    required this.controller,
    required this.paymentStatusFilters,
    required this.selectedPaymentStatusFilter,
    required this.dateFilters,
    required this.selectedDateFilter,
    required this.onSearchChanged,
    required this.onPaymentStatusFilterChanged,
    required this.onDateFilterChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final List<String> paymentStatusFilters;
  final String selectedPaymentStatusFilter;
  final List<String> dateFilters;
  final String selectedDateFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onPaymentStatusFilterChanged;
  final ValueChanged<String> onDateFilterChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasSearch = controller.text.trim().isNotEmpty;
    final hasFilters =
        selectedPaymentStatusFilter != 'All payment statuses' ||
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
                hintText: 'Invoice, shipment, customer, total, method',
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

            final statusFilter = _InvoiceDropdown(
              key: ValueKey('invoice-payment-$selectedPaymentStatusFilter'),
              label: 'Payment status',
              icon: Icons.verified_outlined,
              value: selectedPaymentStatusFilter,
              options: paymentStatusFilters,
              onChanged: onPaymentStatusFilterChanged,
            );

            final dateFilter = _InvoiceDropdown(
              key: ValueKey('invoice-date-$selectedDateFilter'),
              label: 'Generated date',
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

            if (constraints.maxWidth >= 980) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: search),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: statusFilter),
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

class _InvoiceDropdown extends StatelessWidget {
  const _InvoiceDropdown({
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

class _InvoiceListMetaCard extends StatelessWidget {
  const _InvoiceListMetaCard({
    required this.visibleCount,
    required this.totalCount,
    required this.paymentStatusFilter,
    required this.dateFilter,
  });

  final int visibleCount;
  final int totalCount;
  final String paymentStatusFilter;
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
                Icons.receipt_long_outlined,
                color: AppColors.primaryBlue,
              ),
            ),
            Text(
              '$visibleCount visible of $totalCount invoices',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            AdminStatusBadge(
              label: paymentStatusFilter,
              tone: paymentStatusFilter == 'All payment statuses'
                  ? AdminStatusTone.neutral
                  : AdminStatusBadge.fromStatus(paymentStatusFilter).tone,
            ),
            AdminStatusBadge(label: dateFilter, tone: AdminStatusTone.neutral),
          ],
        ),
      ),
    );
  }
}

class _InvoiceNumberCell extends StatelessWidget {
  const _InvoiceNumberCell({required this.invoice});

  final AdminInvoiceManagementMock invoice;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            invoice.invoiceNumber,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xxs),
          AdminStatusBadge.fromStatus(invoice.invoiceStatus),
        ],
      ),
    );
  }
}

class _InvoiceActions extends StatelessWidget {
  const _InvoiceActions({required this.onView, required this.onDownload});

  final VoidCallback onView;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
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
            onPressed: onDownload,
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Download'),
          ),
        ],
      ),
    );
  }
}

class _InvoicePreviewDialog extends StatelessWidget {
  const _InvoicePreviewDialog({
    required this.invoice,
    required this.onDownload,
  });

  final AdminInvoiceManagementMock invoice;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invoice preview'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: SingleChildScrollView(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InvoicePreviewHeader(invoice: invoice),
                  const Divider(height: AppSpacing.xl),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      const SizedBox(
                        width: 360,
                        child: _InvoiceSection(
                          title: 'Company',
                          children: [
                            _InvoiceDetailRow(
                              label: 'Name',
                              value: 'CargoConnect Logistics Pvt Ltd',
                            ),
                            _InvoiceDetailRow(
                              label: 'GSTIN',
                              value: '27AABCC2406C1Z5',
                            ),
                            _InvoiceDetailRow(
                              label: 'Address',
                              value:
                                  'Operations Tower, Bhiwandi Logistics Park, Maharashtra',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 360,
                        child: _InvoiceSection(
                          title: 'Bill to',
                          children: [
                            _InvoiceDetailRow(
                              label: 'Customer',
                              value: invoice.customer,
                            ),
                            _InvoiceDetailRow(
                              label: 'Billing address',
                              value: invoice.billingAddress,
                            ),
                            _InvoiceDetailRow(
                              label: 'Payment method',
                              value: invoice.paymentMethod,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InvoiceSection(
                    title: 'Shipment',
                    children: [
                      _InvoiceDetailRow(
                        label: 'Shipment ID',
                        value: invoice.shipmentId,
                      ),
                      _InvoiceDetailRow(label: 'Route', value: invoice.route),
                      _InvoiceDetailRow(
                        label: 'Package',
                        value: invoice.packageSummary,
                      ),
                      _InvoiceDetailRow(
                        label: 'Generated',
                        value: _formatDateTime(context, invoice.generatedDate),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ChargeBreakdown(invoice: invoice),
                  const SizedBox(height: AppSpacing.md),
                  _InvoiceSection(
                    title: 'Notes',
                    children: [
                      _InvoiceDetailRow(
                        label: 'Admin note',
                        value: invoice.notes,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onDownload();
          },
          icon: const Icon(Icons.download_outlined),
          label: const Text('Download PDF'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _InvoicePreviewHeader extends StatelessWidget {
  const _InvoicePreviewHeader({required this.invoice});

  final AdminInvoiceManagementMock invoice;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.roadYellow,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: const Icon(
            Icons.local_shipping_rounded,
            color: AppColors.primaryNavy,
          ),
        ),
        SizedBox(
          width: 330,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CargoConnect',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Logistics tax invoice',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invoice.invoiceNumber,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  AdminStatusBadge.fromStatus(invoice.invoiceStatus),
                  AdminStatusBadge.fromStatus(invoice.paymentStatus),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InvoiceSection extends StatelessWidget {
  const _InvoiceSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _InvoiceDetailRow extends StatelessWidget {
  const _InvoiceDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ChargeBreakdown extends StatelessWidget {
  const _ChargeBreakdown({required this.invoice});

  final AdminInvoiceManagementMock invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Charge breakdown',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          _InvoiceAmountRow(label: 'Base freight', value: invoice.baseCharge),
          _InvoiceAmountRow(label: 'Handling fee', value: invoice.handlingFee),
          _InvoiceAmountRow(label: 'Tax', value: invoice.tax),
          _InvoiceAmountRow(label: 'Discount', value: invoice.discount),
          const Divider(height: AppSpacing.lg),
          _InvoiceAmountRow(
            label: 'Total',
            value: invoice.total,
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _InvoiceAmountRow extends StatelessWidget {
  const _InvoiceAmountRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
