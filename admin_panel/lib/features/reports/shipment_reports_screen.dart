import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/mock_admin_data.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/widgets/admin_chart_card.dart';
import '../../core/widgets/admin_data_table.dart';
import '../../core/widgets/admin_state_widgets.dart';
import '../../core/widgets/admin_status_badge.dart';

class ShipmentReportsScreen extends ConsumerStatefulWidget {
  const ShipmentReportsScreen({super.key});

  @override
  ConsumerState<ShipmentReportsScreen> createState() =>
      _ShipmentReportsScreenState();
}

class _ShipmentReportsScreenState extends ConsumerState<ShipmentReportsScreen> {
  static const _dateRangeFilters = [
    'Last 7 days',
    'This month',
    'Last 90 days',
    'Custom range',
  ];
  static const _statusFilters = [
    'All statuses',
    'Pending',
    'Approved',
    'Assigned',
    'In Transit',
    'Delivered',
    'Cancelled',
  ];
  static const _categoryFilters = [
    'All categories',
    'Small Parcel',
    'Medium Goods',
    'Heavy Cargo',
    'Refrigerated',
    'Fragile',
    'Urgent',
  ];

  String _dateRangeFilter = _dateRangeFilters.first;
  String _statusFilter = _statusFilters.first;
  String _categoryFilter = _categoryFilters.first;
  bool _isLoading = true;
  bool _hasLoadError = false;
  AdminShipmentReportUiData? _report;

  List<AdminShipmentStatusReportMock> get _filteredStatusRows {
    final rows = _report?.statusRows ?? const <AdminShipmentStatusReportMock>[];
    if (_statusFilter == _statusFilters.first) {
      return rows;
    }
    return rows.where((row) => row.status == _statusFilter).toList();
  }

  List<AdminShipmentCategoryReportMock> get _filteredCategoryRows {
    final rows =
        _report?.categoryRows ?? const <AdminShipmentCategoryReportMock>[];
    if (_categoryFilter == _categoryFilters.first) {
      return rows;
    }
    return rows.where((row) => row.category == _categoryFilter).toList();
  }

  int get _totalBookings => _report?.totalBookings ?? 0;

  int get _totalDelivered => _report?.totalDelivered ?? 0;

  int get _totalCancelled => _report?.totalCancelled ?? 0;

  @override
  void initState() {
    super.initState();
    _loadShipmentReports();
  }

  Future<void> _loadShipmentReports() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });

    try {
      final report = await ref
          .read(adminApiServiceProvider)
          .fetchShipmentReportUi(query: {'limit': 100, ..._dateRangeQuery()});
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
      _categoryFilter = _categoryFilters.first;
    });
    _loadShipmentReports();
  }

  Future<void> _showExportMessage(String format) async {
    try {
      final bytes = await ref
          .read(adminApiServiceProvider)
          .exportReport('shipments', format, query: _exportQuery());
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$format shipment report fetched from API ($bytes bytes).',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShipmentReportHeader(
          dateRangeFilter: _dateRangeFilter,
          statusFilter: _statusFilter,
          categoryFilter: _categoryFilter,
          onExportPdf: () => _showExportMessage('PDF'),
          onExportCsv: () => _showExportMessage('CSV'),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ShipmentReportFilters(
          dateRangeFilters: _dateRangeFilters,
          selectedDateRangeFilter: _dateRangeFilter,
          statusFilters: _statusFilters,
          selectedStatusFilter: _statusFilter,
          categoryFilters: _categoryFilters,
          selectedCategoryFilter: _categoryFilter,
          onDateRangeChanged: (value) {
            setState(() => _dateRangeFilter = value);
            _loadShipmentReports();
          },
          onStatusChanged: (value) => setState(() => _statusFilter = value),
          onCategoryChanged: (value) => setState(() => _categoryFilter = value),
          onReset: _resetFilters,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_isLoading)
          const AdminLoadingState(message: 'Loading shipment reports...')
        else if (_hasLoadError)
          AdminErrorState(
            title: 'Shipment reports unavailable',
            message:
                'Shipment report API could not be loaded. Retry to restore date, status, and category breakdowns.',
            onRetry: _loadShipmentReports,
          )
        else if (report == null || report.isEmpty)
          const AdminEmptyState(
            title: 'No shipment report data',
            message:
                'Shipment report charts and tables will appear here when backend data exists.',
            icon: Icons.inventory_2_outlined,
          )
        else ...[
          _ShipmentReportSummary(
            bookings: _totalBookings,
            delivered: _totalDelivered,
            cancelled: _totalCancelled,
          ),
          const SizedBox(height: AppSpacing.lg),
          _DateWiseReportSection(
            dateRangeFilter: _dateRangeFilter,
            rows: report.dateRows,
          ),
          const SizedBox(height: AppSpacing.lg),
          _StatusWiseReportSection(rows: _filteredStatusRows),
          const SizedBox(height: AppSpacing.lg),
          _CategoryWiseReportSection(rows: _filteredCategoryRows),
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
    if (_categoryFilter != _categoryFilters.first) {
      query['categoryCode'] = _apiValue(_categoryFilter);
    }
    return query;
  }
}

class _ShipmentReportHeader extends StatelessWidget {
  const _ShipmentReportHeader({
    required this.dateRangeFilter,
    required this.statusFilter,
    required this.categoryFilter,
    required this.onExportPdf,
    required this.onExportCsv,
  });

  final String dateRangeFilter;
  final String statusFilter;
  final String categoryFilter;
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
                  label: 'Shipment analytics',
                  tone: AdminStatusTone.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Shipment reports',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Date-wise, status-wise, and category-wise shipment performance with backend exports.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            );

            final exportPanel = _ShipmentExportPanel(
              dateRangeFilter: dateRangeFilter,
              statusFilter: statusFilter,
              categoryFilter: categoryFilter,
              onExportPdf: onExportPdf,
              onExportCsv: onExportCsv,
            );

            if (constraints.maxWidth >= 940) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: AppSpacing.lg),
                  SizedBox(width: 380, child: exportPanel),
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

class _ShipmentExportPanel extends StatelessWidget {
  const _ShipmentExportPanel({
    required this.dateRangeFilter,
    required this.statusFilter,
    required this.categoryFilter,
    required this.onExportPdf,
    required this.onExportCsv,
  });

  final String dateRangeFilter;
  final String statusFilter;
  final String categoryFilter;
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
            '$dateRangeFilter - $statusFilter - $categoryFilter',
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

class _ShipmentReportFilters extends StatelessWidget {
  const _ShipmentReportFilters({
    required this.dateRangeFilters,
    required this.selectedDateRangeFilter,
    required this.statusFilters,
    required this.selectedStatusFilter,
    required this.categoryFilters,
    required this.selectedCategoryFilter,
    required this.onDateRangeChanged,
    required this.onStatusChanged,
    required this.onCategoryChanged,
    required this.onReset,
  });

  final List<String> dateRangeFilters;
  final String selectedDateRangeFilter;
  final List<String> statusFilters;
  final String selectedStatusFilter;
  final List<String> categoryFilters;
  final String selectedCategoryFilter;
  final ValueChanged<String> onDateRangeChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        selectedDateRangeFilter != dateRangeFilters.first ||
        selectedStatusFilter != statusFilters.first ||
        selectedCategoryFilter != categoryFilters.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dateRange = _ShipmentReportDropdown(
              key: ValueKey('shipment-report-date-$selectedDateRangeFilter'),
              label: 'Date range',
              icon: Icons.date_range_outlined,
              value: selectedDateRangeFilter,
              options: dateRangeFilters,
              onChanged: onDateRangeChanged,
            );
            final status = _ShipmentReportDropdown(
              key: ValueKey('shipment-report-status-$selectedStatusFilter'),
              label: 'Status',
              icon: Icons.filter_alt_outlined,
              value: selectedStatusFilter,
              options: statusFilters,
              onChanged: onStatusChanged,
            );
            final category = _ShipmentReportDropdown(
              key: ValueKey('shipment-report-category-$selectedCategoryFilter'),
              label: 'Category',
              icon: Icons.category_outlined,
              value: selectedCategoryFilter,
              options: categoryFilters,
              onChanged: onCategoryChanged,
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
                  Expanded(child: category),
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
                category,
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

class _ShipmentReportDropdown extends StatelessWidget {
  const _ShipmentReportDropdown({
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

class _ShipmentReportSummary extends StatelessWidget {
  const _ShipmentReportSummary({
    required this.bookings,
    required this.delivered,
    required this.cancelled,
  });

  final int bookings;
  final int delivered;
  final int cancelled;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryTile(
        label: 'Total bookings',
        value: '$bookings',
        icon: Icons.inventory_2_outlined,
        tone: AdminStatusTone.primary,
      ),
      _SummaryTile(
        label: 'Delivered',
        value: '$delivered',
        icon: Icons.task_alt_rounded,
        tone: AdminStatusTone.success,
      ),
      _SummaryTile(
        label: 'Cancelled',
        value: '$cancelled',
        icon: Icons.cancel_outlined,
        tone: AdminStatusTone.danger,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            children: [
              for (final card in cards) ...[
                Expanded(child: card),
                if (card != cards.last) const SizedBox(width: AppSpacing.md),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (final card in cards) ...[
              card,
              if (card != cards.last) const SizedBox(height: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final AdminStatusTone tone;

  Color get _color {
    return switch (tone) {
      AdminStatusTone.primary => AppColors.primaryBlue,
      AdminStatusTone.success => AppColors.success,
      AdminStatusTone.warning => AppColors.warning,
      AdminStatusTone.danger => AppColors.danger,
      AdminStatusTone.info => AppColors.info,
      AdminStatusTone.neutral => AppColors.neutral,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Icon(icon, color: _color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateWiseReportSection extends StatelessWidget {
  const _DateWiseReportSection({
    required this.dateRangeFilter,
    required this.rows,
  });

  final String dateRangeFilter;
  final List<AdminShipmentDateReportMock> rows;

  @override
  Widget build(BuildContext context) {
    return _ReportSectionLayout(
      title: 'Date-wise shipment report',
      subtitle:
          'Daily bookings, delivery movement, cancellations, and revenue.',
      chart: AdminChartCard(
        title: 'Date-wise chart',
        subtitle: 'Booking trend for $dateRangeFilter',
        trailing: AdminStatusBadge(
          label: dateRangeFilter,
          tone: AdminStatusTone.primary,
        ),
        entries: [
          for (final row in rows)
            AdminChartEntry(label: row.date, value: row.bookings.toDouble()),
        ],
      ),
      table: AdminDataTable(
        columns: const [
          AdminTableColumn('Date'),
          AdminTableColumn('Bookings'),
          AdminTableColumn('Approved'),
          AdminTableColumn('In transit'),
          AdminTableColumn('Delivered'),
          AdminTableColumn('Cancelled'),
          AdminTableColumn('Revenue'),
        ],
        rows: [
          for (final row in rows)
            [
              Text(row.date),
              Text('${row.bookings}'),
              Text('${row.approved}'),
              Text('${row.inTransit}'),
              Text('${row.delivered}'),
              Text('${row.cancelled}'),
              Text(row.revenue),
            ],
        ],
      ),
    );
  }
}

String _isoDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _apiValue(String value) => value.toLowerCase().replaceAll(' ', '_');

class _StatusWiseReportSection extends StatelessWidget {
  const _StatusWiseReportSection({required this.rows});

  final List<AdminShipmentStatusReportMock> rows;

  @override
  Widget build(BuildContext context) {
    return _ReportSectionLayout(
      title: 'Status-wise shipment report',
      subtitle:
          'Shipment count, share, revenue exposure, and SLA note by status.',
      chart: AdminChartCard(
        title: 'Status-wise chart',
        subtitle: 'Current shipment status distribution',
        trailing: AdminStatusBadge(
          label: '${rows.length} status rows',
          tone: AdminStatusTone.info,
        ),
        entries: [
          for (final row in rows)
            AdminChartEntry(label: row.status, value: row.count.toDouble()),
        ],
      ),
      table: rows.isEmpty
          ? const AdminEmptyState(
              title: 'No status rows',
              message: 'Select another status filter to restore status data.',
              icon: Icons.filter_alt_off_outlined,
            )
          : AdminDataTable(
              columns: const [
                AdminTableColumn('Status'),
                AdminTableColumn('Count'),
                AdminTableColumn('Share'),
                AdminTableColumn('Revenue'),
                AdminTableColumn('SLA note'),
              ],
              rows: [
                for (final row in rows)
                  [
                    AdminStatusBadge.fromStatus(row.status),
                    Text('${row.count}'),
                    Text(row.share),
                    Text(row.revenue),
                    Text(row.sla),
                  ],
              ],
            ),
    );
  }
}

class _CategoryWiseReportSection extends StatelessWidget {
  const _CategoryWiseReportSection({required this.rows});

  final List<AdminShipmentCategoryReportMock> rows;

  @override
  Widget build(BuildContext context) {
    return _ReportSectionLayout(
      title: 'Category-wise shipment report',
      subtitle: 'Shipment volume, average weight, revenue, and vehicle mix.',
      chart: AdminChartCard(
        title: 'Category-wise chart',
        subtitle: 'Shipment volume by category',
        trailing: AdminStatusBadge(
          label: '${rows.length} categories',
          tone: AdminStatusTone.success,
        ),
        entries: [
          for (final row in rows)
            AdminChartEntry(
              label: row.category,
              value: row.shipments.toDouble(),
            ),
        ],
      ),
      table: rows.isEmpty
          ? const AdminEmptyState(
              title: 'No category rows',
              message:
                  'Select another category filter to restore category data.',
              icon: Icons.category_outlined,
            )
          : AdminDataTable(
              columns: const [
                AdminTableColumn('Category'),
                AdminTableColumn('Shipments'),
                AdminTableColumn('Average weight'),
                AdminTableColumn('Revenue'),
                AdminTableColumn('Top vehicle'),
              ],
              rows: [
                for (final row in rows)
                  [
                    Text(row.category),
                    Text('${row.shipments}'),
                    Text(row.averageWeight),
                    Text(row.revenue),
                    Text(row.topVehicle),
                  ],
              ],
            ),
    );
  }
}

class _ReportSectionLayout extends StatelessWidget {
  const _ReportSectionLayout({
    required this.title,
    required this.subtitle,
    required this.chart,
    required this.table,
  });

  final String title;
  final String subtitle;
  final Widget chart;
  final Widget table;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 1180) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: chart),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: table),
                ],
              );
            }

            return Column(
              children: [
                chart,
                const SizedBox(height: AppSpacing.md),
                table,
              ],
            );
          },
        ),
      ],
    );
  }
}
