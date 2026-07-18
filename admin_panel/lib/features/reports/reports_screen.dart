import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/mock_admin_data.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/widgets/admin_chart_card.dart';
import '../../core/widgets/admin_state_widgets.dart';
import '../../core/widgets/admin_status_badge.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  static const _dateRangeFilters = [
    'Last 7 days',
    'This month',
    'Last 90 days',
    'Custom range',
  ];
  static const _statusFilters = [
    'All statuses',
    'Pending',
    'Active',
    'Delivered',
    'Cancelled',
    'Paid',
  ];

  String _dateRangeFilter = _dateRangeFilters.first;
  String _statusFilter = _statusFilters.first;
  bool _isLoading = true;
  bool _hasLoadError = false;
  AdminReportsOverviewData? _overview;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });

    try {
      final service = ref.read(adminApiServiceProvider);
      final overview = await service.fetchReportsOverview(
        query: {'limit': 100, ..._reportQuery()},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _overview = overview;
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

  Future<void> _showExportMessage(String format) async {
    try {
      final service = ref.read(adminApiServiceProvider);
      final sizes = await Future.wait([
        service.exportReport('shipments', format, query: _reportQuery()),
        service.exportReport(
          'drivers',
          format,
          query: _dateRangeQuery(_dateRangeFilter),
        ),
        service.exportReport(
          'vehicles',
          format,
          query: _dateRangeQuery(_dateRangeFilter),
        ),
        service.exportReport('payments', format, query: _reportQuery()),
      ]);
      if (!mounted) {
        return;
      }
      final totalBytes = sizes.fold<int>(0, (total, size) => total + size);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$format exports fetched from API ($totalBytes bytes total).',
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
    final overview = _overview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReportsHeader(
          dateRangeFilter: _dateRangeFilter,
          statusFilter: _statusFilter,
          onExportPdf: () => _showExportMessage('PDF'),
          onExportCsv: () => _showExportMessage('CSV'),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReportsFilterBar(
          dateRangeFilters: _dateRangeFilters,
          selectedDateRangeFilter: _dateRangeFilter,
          statusFilters: _statusFilters,
          selectedStatusFilter: _statusFilter,
          onDateRangeChanged: (value) {
            setState(() => _dateRangeFilter = value);
            _loadReports();
          },
          onStatusChanged: (value) {
            setState(() => _statusFilter = value);
            _loadReports();
          },
          onReset: () {
            setState(() {
              _dateRangeFilter = _dateRangeFilters.first;
              _statusFilter = _statusFilters.first;
            });
            _loadReports();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_isLoading)
          const AdminLoadingState(message: 'Loading reports dashboard...')
        else if (_hasLoadError)
          AdminErrorState(
            title: 'Reports unavailable',
            message:
                'Report APIs could not be reached. Retry to restore report cards and charts.',
            onRetry: _loadReports,
          )
        else if (overview == null || overview.reportCards.isEmpty)
          const AdminEmptyState(
            title: 'No report data',
            message:
                'Report cards and charts will appear here when backend report data exists.',
            icon: Icons.insights_outlined,
          )
        else ...[
          _ReportCardGrid(cards: overview.reportCards),
          const SizedBox(height: AppSpacing.lg),
          _ReportCharts(
            overview: overview,
            dateRangeFilter: _dateRangeFilter,
            statusFilter: _statusFilter,
          ),
        ],
      ],
    );
  }

  Map<String, dynamic> _reportQuery() {
    final query = <String, dynamic>{};
    final dateRange = _dateRangeQuery(_dateRangeFilter);
    query.addAll(dateRange);
    final status = _apiStatus(_statusFilter);
    if (status != null) {
      query['status'] = status;
    }
    return query;
  }
}

class _ReportsHeader extends StatelessWidget {
  const _ReportsHeader({
    required this.dateRangeFilter,
    required this.statusFilter,
    required this.onExportPdf,
    required this.onExportCsv,
  });

  final String dateRangeFilter;
  final String statusFilter;
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
                  label: 'API analytics',
                  tone: AdminStatusTone.info,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Reports dashboard',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Shipment, driver, vehicle, and payment reporting with backend exports.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            );

            final actions = _ExportActions(
              dateRangeFilter: dateRangeFilter,
              statusFilter: statusFilter,
              onExportPdf: onExportPdf,
              onExportCsv: onExportCsv,
            );

            if (constraints.maxWidth >= 940) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: AppSpacing.lg),
                  SizedBox(width: 360, child: actions),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.lg),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExportActions extends StatelessWidget {
  const _ExportActions({
    required this.dateRangeFilter,
    required this.statusFilter,
    required this.onExportPdf,
    required this.onExportCsv,
  });

  final String dateRangeFilter;
  final String statusFilter;
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
            '$dateRangeFilter - $statusFilter',
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

class _ReportsFilterBar extends StatelessWidget {
  const _ReportsFilterBar({
    required this.dateRangeFilters,
    required this.selectedDateRangeFilter,
    required this.statusFilters,
    required this.selectedStatusFilter,
    required this.onDateRangeChanged,
    required this.onStatusChanged,
    required this.onReset,
  });

  final List<String> dateRangeFilters;
  final String selectedDateRangeFilter;
  final List<String> statusFilters;
  final String selectedStatusFilter;
  final ValueChanged<String> onDateRangeChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        selectedDateRangeFilter != dateRangeFilters.first ||
        selectedStatusFilter != statusFilters.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dateRange = _ReportDropdown(
              key: ValueKey('report-date-$selectedDateRangeFilter'),
              label: 'Date range',
              icon: Icons.date_range_outlined,
              value: selectedDateRangeFilter,
              options: dateRangeFilters,
              onChanged: onDateRangeChanged,
            );
            final status = _ReportDropdown(
              key: ValueKey('report-status-$selectedStatusFilter'),
              label: 'Status',
              icon: Icons.filter_alt_outlined,
              value: selectedStatusFilter,
              options: statusFilters,
              onChanged: onStatusChanged,
            );
            final reset = OutlinedButton.icon(
              onPressed: hasFilters ? onReset : null,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reset'),
            );

            if (constraints.maxWidth >= 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: dateRange),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: status),
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
                Align(alignment: Alignment.centerLeft, child: reset),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReportDropdown extends StatelessWidget {
  const _ReportDropdown({
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

class _ReportCardGrid extends StatelessWidget {
  const _ReportCardGrid({required this.cards});

  final List<AdminReportCardMock> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 4
            : constraints.maxWidth >= 760
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final report in cards)
              SizedBox(
                width: width,
                child: _ReportCard(report: report),
              ),
          ],
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final AdminReportCardMock report;

  AdminStatusTone get _tone {
    return switch (report.status) {
      'Healthy' || 'Operational' => AdminStatusTone.success,
      'Finance' => AdminStatusTone.info,
      'Watch service' => AdminStatusTone.warning,
      _ => AdminStatusTone.neutral,
    };
  }

  @override
  Widget build(BuildContext context) {
    final deltaColor = report.isPositive
        ? AppColors.success
        : AppColors.warning;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: report.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Icon(report.icon, color: report.accentColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AdminStatusBadge(label: report.status, tone: _tone),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(report.metric, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              report.delta,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: deltaColor),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              report.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCharts extends StatelessWidget {
  const _ReportCharts({
    required this.overview,
    required this.dateRangeFilter,
    required this.statusFilter,
  });

  final AdminReportsOverviewData overview;
  final String dateRangeFilter;
  final String statusFilter;

  @override
  Widget build(BuildContext context) {
    final charts = [
      AdminChartCard(
        title: 'Shipment report',
        subtitle: 'Status distribution for $dateRangeFilter',
        trailing: AdminStatusBadge(
          label: statusFilter,
          tone: statusFilter == 'All statuses'
              ? AdminStatusTone.neutral
              : AdminStatusBadge.fromStatus(statusFilter).tone,
        ),
        entries: _chartEntries(overview.shipmentPoints),
      ),
      AdminChartCard(
        title: 'Driver report',
        subtitle: 'Availability and load distribution',
        trailing: const AdminStatusBadge(
          label: 'Live capacity',
          tone: AdminStatusTone.success,
        ),
        entries: _chartEntries(overview.driverPoints),
      ),
      AdminChartCard(
        title: 'Vehicle report',
        subtitle: 'Fleet utilization by vehicle type',
        trailing: const AdminStatusBadge(
          label: '78%',
          tone: AdminStatusTone.warning,
        ),
        entries: _chartEntries(overview.vehiclePoints),
      ),
      AdminChartCard(
        title: 'Payment report',
        subtitle: 'Collection mix in lakhs',
        trailing: const AdminStatusBadge(
          label: 'Finance',
          tone: AdminStatusTone.info,
        ),
        entries: _chartEntries(overview.paymentPoints),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1180) {
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: charts[2]),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: charts[3]),
                ],
              ),
            ],
          );
        }

        if (constraints.maxWidth >= 820) {
          return Column(
            children: [
              for (var index = 0; index < charts.length; index += 2) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: charts[index]),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: charts[index + 1]),
                  ],
                ),
                if (index + 2 < charts.length)
                  const SizedBox(height: AppSpacing.md),
              ],
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

List<AdminChartEntry> _chartEntries(List<AdminChartPointMock> points) {
  return [
    for (final point in points)
      AdminChartEntry(label: point.label, value: point.value),
  ];
}

Map<String, dynamic> _dateRangeQuery(String filter) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final from = switch (filter) {
    'This month' => DateTime(today.year, today.month),
    'Last 90 days' => today.subtract(const Duration(days: 90)),
    'Custom range' => today.subtract(const Duration(days: 30)),
    _ => today.subtract(const Duration(days: 7)),
  };
  return {
    'dateFrom': _isoDate(from),
    'dateTo': _isoDate(today.add(const Duration(days: 1))),
  };
}

String _isoDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String? _apiStatus(String label) {
  if (label == 'All statuses' || label == 'Active' || label == 'Paid') {
    return null;
  }
  return label.toLowerCase().replaceAll(' ', '_');
}
