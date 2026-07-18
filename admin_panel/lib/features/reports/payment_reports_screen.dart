import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/mock_admin_data.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/widgets/admin_chart_card.dart';
import '../../core/widgets/admin_data_table.dart';
import '../../core/widgets/admin_stat_card.dart';
import '../../core/widgets/admin_state_widgets.dart';
import '../../core/widgets/admin_status_badge.dart';

class PaymentReportsScreen extends ConsumerStatefulWidget {
  const PaymentReportsScreen({super.key});

  @override
  ConsumerState<PaymentReportsScreen> createState() =>
      _PaymentReportsScreenState();
}

class _PaymentReportsScreenState extends ConsumerState<PaymentReportsScreen> {
  static const _dateRangeFilters = [
    'Last 7 days',
    'This month',
    'Last 90 days',
    'Custom range',
  ];
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
  ];

  String _dateRangeFilter = _dateRangeFilters.first;
  String _statusFilter = _statusFilters.first;
  String _methodFilter = _methodFilters.first;
  bool _isLoading = true;
  bool _hasLoadError = false;
  AdminPaymentReportUiData? _report;

  List<AdminPaymentStatusReportMock> get _filteredStatusRows {
    final rows = _report?.statusRows ?? const <AdminPaymentStatusReportMock>[];
    if (_statusFilter == _statusFilters.first) {
      return rows;
    }
    return rows.where((row) => row.status == _statusFilter).toList();
  }

  List<AdminPaymentMethodReportMock> get _filteredMethodRows {
    final rows = _report?.methodRows ?? const <AdminPaymentMethodReportMock>[];
    if (_methodFilter == _methodFilters.first) {
      return rows;
    }
    return rows.where((row) => row.method == _methodFilter).toList();
  }

  List<AdminPaymentRevenueReportMock> get _revenueRows =>
      _report?.revenueRows ?? const <AdminPaymentRevenueReportMock>[];

  int get _totalTransactions => _report?.totalTransactions ?? 0;

  AdminPaymentStatusReportMock _statusRow(String status) {
    return _report?.statusRow(status) ??
        AdminPaymentStatusReportMock(
          status: status,
          count: 0,
          amount: 'INR 0',
          share: '0%',
          action: 'No records',
        );
  }

  @override
  void initState() {
    super.initState();
    _loadPaymentReports();
  }

  Future<void> _loadPaymentReports() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });

    try {
      final report = await ref
          .read(adminApiServiceProvider)
          .fetchPaymentReportUi(query: {'limit': 100, ..._dateRangeQuery()});
      if (!mounted) {
        return;
      }
      setState(() {
        _report = report;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(error.message),
        ),
      );
    }
  }

  void _resetFilters() {
    setState(() {
      _dateRangeFilter = _dateRangeFilters.first;
      _statusFilter = _statusFilters.first;
      _methodFilter = _methodFilters.first;
    });
    _loadPaymentReports();
  }

  Future<void> _showExportMessage(String format) async {
    try {
      final bytes = await ref
          .read(adminApiServiceProvider)
          .exportReport('payments', format, query: _exportQuery());
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$format payment report fetched from API ($bytes bytes).',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(error.message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final filteredStatusRows = _filteredStatusRows;
    final filteredMethodRows = _filteredMethodRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PaymentReportHeader(
          dateRangeFilter: _dateRangeFilter,
          statusFilter: _statusFilter,
          methodFilter: _methodFilter,
          onExportPdf: () => _showExportMessage('PDF'),
          onExportCsv: () => _showExportMessage('CSV'),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PaymentReportFilters(
          dateRangeFilters: _dateRangeFilters,
          selectedDateRangeFilter: _dateRangeFilter,
          statusFilters: _statusFilters,
          selectedStatusFilter: _statusFilter,
          methodFilters: _methodFilters,
          selectedMethodFilter: _methodFilter,
          onDateRangeChanged: (value) {
            setState(() => _dateRangeFilter = value);
            _loadPaymentReports();
          },
          onStatusChanged: (value) => setState(() => _statusFilter = value),
          onMethodChanged: (value) => setState(() => _methodFilter = value),
          onReset: _resetFilters,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_isLoading)
          const AdminLoadingState(message: 'Loading payment reports...')
        else if (_hasLoadError)
          AdminErrorState(
            title: 'Payment reports unavailable',
            message:
                'Payment report API could not be loaded. Retry to restore revenue, method, and status summaries.',
            onRetry: _loadPaymentReports,
          )
        else if (report == null || report.isEmpty)
          const AdminEmptyState(
            title: 'No payment report data',
            message:
                'Payment report charts and tables will appear here when backend data exists.',
            icon: Icons.payments_outlined,
          )
        else ...[
          _PaymentReportSummary(
            totalTransactions: _totalTransactions,
            revenueSummary: report.totalRevenue,
            paid: _statusRow('Paid'),
            pending: _statusRow('Pending'),
            refunded: _statusRow('Refunded'),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PaymentReportCharts(
            dateRangeFilter: _dateRangeFilter,
            revenueRows: _revenueRows,
            statusRows: filteredStatusRows,
            methodRows: filteredMethodRows,
          ),
          const SizedBox(height: AppSpacing.lg),
          _RevenueSummarySection(
            dateRangeFilter: _dateRangeFilter,
            rows: _revenueRows,
          ),
          const SizedBox(height: AppSpacing.lg),
          _PaymentStatusSection(rows: filteredStatusRows),
          const SizedBox(height: AppSpacing.lg),
          _PaymentMethodSection(rows: filteredMethodRows),
        ],
      ],
    );
  }

  Map<String, dynamic> _dateRangeQuery() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = switch (_dateRangeFilter) {
      'This month' => DateTime(today.year, today.month),
      'Last 90 days' => today.subtract(const Duration(days: 90)),
      'Custom range' => today.subtract(const Duration(days: 30)),
      _ => today.subtract(const Duration(days: 7)),
    };
    return {'dateFrom': _isoDate(from), 'dateTo': _isoDate(today)};
  }

  Map<String, dynamic> _exportQuery() {
    final query = <String, dynamic>{..._dateRangeQuery()};
    if (_statusFilter != _statusFilters.first) {
      query['status'] = _apiValue(_statusFilter);
    }
    if (_methodFilter != _methodFilters.first) {
      query['paymentMethod'] = _apiValue(_methodFilter);
    }
    return query;
  }
}

class _PaymentReportHeader extends StatelessWidget {
  const _PaymentReportHeader({
    required this.dateRangeFilter,
    required this.statusFilter,
    required this.methodFilter,
    required this.onExportPdf,
    required this.onExportCsv,
  });

  final String dateRangeFilter;
  final String statusFilter;
  final String methodFilter;
  final VoidCallback onExportPdf;
  final VoidCallback onExportCsv;

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
                const AdminStatusBadge(
                  label: 'Payment analytics',
                  tone: AdminStatusTone.info,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Payment reports',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Revenue, payment methods, paid, pending, and refunded payment status reporting with backend exports.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            );

            final exportPanel = _PaymentExportPanel(
              dateRangeFilter: dateRangeFilter,
              statusFilter: statusFilter,
              methodFilter: methodFilter,
              onExportPdf: onExportPdf,
              onExportCsv: onExportCsv,
            );

            if (constraints.maxWidth >= 940) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: AppSpacing.lg),
                  SizedBox(width: 390, child: exportPanel),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.lg),
                exportPanel,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PaymentExportPanel extends StatelessWidget {
  const _PaymentExportPanel({
    required this.dateRangeFilter,
    required this.statusFilter,
    required this.methodFilter,
    required this.onExportPdf,
    required this.onExportCsv,
  });

  final String dateRangeFilter;
  final String statusFilter;
  final String methodFilter;
  final VoidCallback onExportPdf;
  final VoidCallback onExportCsv;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export scope',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.surfaceMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$dateRangeFilter - $statusFilter - $methodFilter',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textInverse,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.icon(
                onPressed: onExportPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Export PDF'),
              ),
              OutlinedButton.icon(
                onPressed: onExportCsv,
                icon: const Icon(Icons.table_view_outlined),
                label: const Text('Export CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textInverse,
                  side: const BorderSide(color: AppColors.surfaceMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentReportFilters extends StatelessWidget {
  const _PaymentReportFilters({
    required this.dateRangeFilters,
    required this.selectedDateRangeFilter,
    required this.statusFilters,
    required this.selectedStatusFilter,
    required this.methodFilters,
    required this.selectedMethodFilter,
    required this.onDateRangeChanged,
    required this.onStatusChanged,
    required this.onMethodChanged,
    required this.onReset,
  });

  final List<String> dateRangeFilters;
  final String selectedDateRangeFilter;
  final List<String> statusFilters;
  final String selectedStatusFilter;
  final List<String> methodFilters;
  final String selectedMethodFilter;
  final ValueChanged<String> onDateRangeChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onMethodChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        selectedDateRangeFilter != dateRangeFilters.first ||
        selectedStatusFilter != statusFilters.first ||
        selectedMethodFilter != methodFilters.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dateRange = _PaymentReportDropdown(
              key: ValueKey('payment-report-date-$selectedDateRangeFilter'),
              label: 'Date range',
              icon: Icons.date_range_outlined,
              value: selectedDateRangeFilter,
              options: dateRangeFilters,
              onChanged: onDateRangeChanged,
            );
            final status = _PaymentReportDropdown(
              key: ValueKey('payment-report-status-$selectedStatusFilter'),
              label: 'Status',
              icon: Icons.verified_outlined,
              value: selectedStatusFilter,
              options: statusFilters,
              onChanged: onStatusChanged,
            );
            final method = _PaymentReportDropdown(
              key: ValueKey('payment-report-method-$selectedMethodFilter'),
              label: 'Payment method',
              icon: Icons.account_balance_wallet_outlined,
              value: selectedMethodFilter,
              options: methodFilters,
              onChanged: onMethodChanged,
            );
            final reset = OutlinedButton.icon(
              onPressed: hasFilters ? onReset : null,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reset'),
            );

            if (constraints.maxWidth >= 1120) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: dateRange),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: status),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: method),
                  const SizedBox(width: AppSpacing.md),
                  Padding(padding: const EdgeInsets.only(top: 6), child: reset),
                ],
              );
            }

            return Column(
              children: [
                dateRange,
                const SizedBox(height: AppSpacing.md),
                status,
                const SizedBox(height: AppSpacing.md),
                method,
                const SizedBox(height: AppSpacing.md),
                Align(alignment: Alignment.centerLeft, child: reset),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PaymentReportDropdown extends StatelessWidget {
  const _PaymentReportDropdown({
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

class _PaymentReportSummary extends StatelessWidget {
  const _PaymentReportSummary({
    required this.totalTransactions,
    required this.revenueSummary,
    required this.paid,
    required this.pending,
    required this.refunded,
  });

  final int totalTransactions;
  final String revenueSummary;
  final AdminPaymentStatusReportMock paid;
  final AdminPaymentStatusReportMock pending;
  final AdminPaymentStatusReportMock refunded;

  @override
  Widget build(BuildContext context) {
    final cards = [
      AdminStatCard(
        label: 'Revenue summary',
        value: revenueSummary,
        delta: 'Backend collections',
        icon: Icons.trending_up_rounded,
        isPositive: true,
        accentColor: AppColors.primaryBlue,
      ),
      AdminStatCard(
        label: 'Paid',
        value: paid.amount,
        delta: '${paid.count} paid transactions',
        icon: Icons.task_alt_rounded,
        isPositive: true,
        accentColor: AppColors.success,
      ),
      AdminStatCard(
        label: 'Pending',
        value: pending.amount,
        delta: '${pending.count} awaiting capture',
        icon: Icons.pending_actions_outlined,
        isPositive: false,
        accentColor: AppColors.warning,
      ),
      AdminStatCard(
        label: 'Refunded',
        value: refunded.amount,
        delta: '$totalTransactions total transactions',
        icon: Icons.currency_exchange_outlined,
        isPositive: true,
        accentColor: AppColors.info,
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

class _PaymentReportCharts extends StatelessWidget {
  const _PaymentReportCharts({
    required this.dateRangeFilter,
    required this.revenueRows,
    required this.statusRows,
    required this.methodRows,
  });

  final String dateRangeFilter;
  final List<AdminPaymentRevenueReportMock> revenueRows;
  final List<AdminPaymentStatusReportMock> statusRows;
  final List<AdminPaymentMethodReportMock> methodRows;

  @override
  Widget build(BuildContext context) {
    final charts = [
      AdminChartCard(
        title: 'Revenue trend',
        subtitle: 'Paid amount by day for $dateRangeFilter',
        trailing: AdminStatusBadge(
          label: dateRangeFilter,
          tone: AdminStatusTone.primary,
        ),
        entries: [
          for (final row in revenueRows)
            AdminChartEntry(
              label: row.date,
              value: _amountLakhs(row.paidRevenue),
            ),
        ],
      ),
      AdminChartCard(
        title: 'Payment methods',
        subtitle: 'Revenue mix by method',
        trailing: AdminStatusBadge(
          label: '${methodRows.length} methods',
          tone: AdminStatusTone.info,
        ),
        entries: [
          for (final row in methodRows)
            AdminChartEntry(
              label: _shortMethodLabel(row.method),
              value: _amountLakhs(row.revenue),
            ),
        ],
      ),
      AdminChartCard(
        title: 'Payment statuses',
        subtitle: 'Paid, pending, refunded, and exception exposure',
        trailing: AdminStatusBadge(
          label: '${statusRows.length} statuses',
          tone: AdminStatusTone.warning,
        ),
        entries: [
          for (final row in statusRows)
            AdminChartEntry(label: row.status, value: _amountLakhs(row.amount)),
        ],
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1180) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: charts[0]),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: charts[1]),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: charts[2]),
            ],
          );
        }

        if (constraints.maxWidth >= 820) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: charts[0]),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: charts[1]),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              charts[2],
            ],
          );
        }

        return Column(
          children: [
            for (final chart in charts) ...[
              chart,
              if (chart != charts.last) const SizedBox(height: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class _RevenueSummarySection extends StatelessWidget {
  const _RevenueSummarySection({
    required this.dateRangeFilter,
    required this.rows,
  });

  final String dateRangeFilter;
  final List<AdminPaymentRevenueReportMock> rows;

  @override
  Widget build(BuildContext context) {
    return _PaymentReportSection(
      title: 'Revenue summary',
      subtitle:
          'Daily paid revenue, pending capture, refunds, and transaction volume.',
      trailing: AdminStatusBadge(
        label: dateRangeFilter,
        tone: AdminStatusTone.primary,
      ),
      child: AdminDataTable(
        columns: const [
          AdminTableColumn('Date'),
          AdminTableColumn('Paid revenue'),
          AdminTableColumn('Pending'),
          AdminTableColumn('Refunded'),
          AdminTableColumn('Transactions'),
        ],
        rows: [
          for (final row in rows)
            [
              Text(row.date),
              Text(row.paidRevenue),
              Text(row.pendingAmount),
              Text(row.refundedAmount),
              Text('${row.transactions}'),
            ],
        ],
      ),
    );
  }
}

class _PaymentStatusSection extends StatelessWidget {
  const _PaymentStatusSection({required this.rows});

  final List<AdminPaymentStatusReportMock> rows;

  @override
  Widget build(BuildContext context) {
    return _PaymentReportSection(
      title: 'Payment statuses',
      subtitle:
          'Paid, pending, processing, failed, and refunded payment exposure.',
      trailing: AdminStatusBadge(
        label: '${rows.length} rows',
        tone: AdminStatusTone.info,
      ),
      child: rows.isEmpty
          ? const AdminEmptyState(
              title: 'No payment statuses',
              message: 'Select another status filter to restore status data.',
              icon: Icons.filter_alt_off_outlined,
            )
          : AdminDataTable(
              columns: const [
                AdminTableColumn('Status'),
                AdminTableColumn('Count'),
                AdminTableColumn('Amount'),
                AdminTableColumn('Share'),
                AdminTableColumn('Admin action'),
              ],
              rows: [
                for (final row in rows)
                  [
                    AdminStatusBadge.fromStatus(row.status),
                    Text('${row.count}'),
                    Text(row.amount),
                    Text(row.share),
                    Text(row.action),
                  ],
              ],
            ),
    );
  }
}

class _PaymentMethodSection extends StatelessWidget {
  const _PaymentMethodSection({required this.rows});

  final List<AdminPaymentMethodReportMock> rows;

  @override
  Widget build(BuildContext context) {
    return _PaymentReportSection(
      title: 'Payment methods',
      subtitle:
          'Method-level transaction volume, revenue, pending amount, and settlement notes.',
      trailing: AdminStatusBadge(
        label: '${rows.length} methods',
        tone: AdminStatusTone.info,
      ),
      child: rows.isEmpty
          ? const AdminEmptyState(
              title: 'No payment methods',
              message: 'Select another method filter to restore method data.',
              icon: Icons.account_balance_wallet_outlined,
            )
          : AdminDataTable(
              columns: const [
                AdminTableColumn('Method'),
                AdminTableColumn('Transactions'),
                AdminTableColumn('Revenue'),
                AdminTableColumn('Pending amount'),
                AdminTableColumn('Success rate'),
                AdminTableColumn('Settlement note'),
              ],
              rows: [
                for (final row in rows)
                  [
                    Text(row.method),
                    Text('${row.transactions}'),
                    Text(row.revenue),
                    Text(row.pendingAmount),
                    Text(row.successRate),
                    Text(row.settlementNote),
                  ],
              ],
            ),
    );
  }
}

class _PaymentReportSection extends StatelessWidget {
  const _PaymentReportSection({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.md),
              trailing!,
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

double _amountLakhs(String amount) {
  final normalized = amount.replaceAll('INR', '').replaceAll('L', '').trim();
  return double.tryParse(normalized) ?? 0;
}

String _shortMethodLabel(String method) {
  return switch (method) {
    'Corporate Wallet' => 'Corp',
    'Cash on Delivery' => 'COD',
    'Bank Transfer' => 'Bank',
    _ => method,
  };
}

String _isoDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _apiValue(String value) => value.toLowerCase().replaceAll(' ', '_');
