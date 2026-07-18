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

class DriverReportsScreen extends ConsumerStatefulWidget {
  const DriverReportsScreen({super.key});

  @override
  ConsumerState<DriverReportsScreen> createState() =>
      _DriverReportsScreenState();
}

class _DriverReportsScreenState extends ConsumerState<DriverReportsScreen> {
  static const _dateRangeFilters = [
    'Last 7 days',
    'This month',
    'Last 90 days',
    'Custom range',
  ];
  static const _statusFilters = [
    'All statuses',
    'Available',
    'On Trip',
    'On Leave',
    'Offline',
  ];
  static const _zoneFilters = [
    'All zones',
    'Pune Corridor',
    'Bhiwandi Hub',
    'Navi Mumbai',
    'Delhi North',
    'Mumbai to Bengaluru',
    'Chennai South',
    'Ahmedabad Ring Road',
    'Jaipur Retail Belt',
  ];

  String _dateRangeFilter = _dateRangeFilters.first;
  String _statusFilter = _statusFilters.first;
  String _zoneFilter = _zoneFilters.first;
  bool _isLoading = true;
  bool _hasLoadError = false;
  AdminDriverReportUiData? _report;

  List<AdminDriverReportMock> get _filteredRows {
    final rows = _report?.rows ?? const <AdminDriverReportMock>[];
    return rows.where((driver) {
      final matchesStatus =
          _statusFilter == _statusFilters.first ||
          driver.status == _statusFilter;
      final matchesZone =
          _zoneFilter == _zoneFilters.first || driver.zone == _zoneFilter;
      return matchesStatus && matchesZone;
    }).toList();
  }

  int get _completedTrips => _filteredRows.fold<int>(
    0,
    (total, driver) => total + driver.completedTrips,
  );

  int get _delays =>
      _filteredRows.fold<int>(0, (total, driver) => total + driver.delays);

  int get _emergencyCount => _filteredRows.fold<int>(
    0,
    (total, driver) => total + driver.emergencyCount,
  );

  double get _acceptanceRate {
    if (_filteredRows.isEmpty) {
      return 0;
    }
    final total = _filteredRows.fold<double>(
      0,
      (sum, driver) => sum + driver.acceptanceRate,
    );
    return total / _filteredRows.length;
  }

  double get _performanceScore {
    if (_filteredRows.isEmpty) {
      return 0;
    }
    final total = _filteredRows.fold<int>(
      0,
      (sum, driver) => sum + driver.performanceScore,
    );
    return total / _filteredRows.length;
  }

  @override
  void initState() {
    super.initState();
    _loadDriverReports();
  }

  Future<void> _loadDriverReports() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });

    try {
      final report = await ref
          .read(adminApiServiceProvider)
          .fetchDriverReportUi(query: {'limit': 100, ..._dateRangeQuery()});
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
      _zoneFilter = _zoneFilters.first;
    });
    _loadDriverReports();
  }

  Future<void> _showExportMessage(String format) async {
    try {
      final bytes = await ref
          .read(adminApiServiceProvider)
          .exportReport('drivers', format, query: _dateRangeQuery());
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$format driver report fetched from API ($bytes bytes).',
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
    final rows = _filteredRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DriverReportHeader(
          dateRangeFilter: _dateRangeFilter,
          statusFilter: _statusFilter,
          zoneFilter: _zoneFilter,
          onExportPdf: () => _showExportMessage('PDF'),
          onExportCsv: () => _showExportMessage('CSV'),
        ),
        const SizedBox(height: AppSpacing.lg),
        _DriverReportFilters(
          dateRangeFilters: _dateRangeFilters,
          selectedDateRangeFilter: _dateRangeFilter,
          statusFilters: _statusFilters,
          selectedStatusFilter: _statusFilter,
          zoneFilters: _zoneFilters,
          selectedZoneFilter: _zoneFilter,
          onDateRangeChanged: (value) {
            setState(() => _dateRangeFilter = value);
            _loadDriverReports();
          },
          onStatusChanged: (value) => setState(() => _statusFilter = value),
          onZoneChanged: (value) => setState(() => _zoneFilter = value),
          onReset: _resetFilters,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_isLoading)
          const AdminLoadingState(message: 'Loading driver reports...')
        else if (_hasLoadError)
          AdminErrorState(
            title: 'Driver reports unavailable',
            message:
                'Driver report API could not be loaded. Retry to restore performance metrics.',
            onRetry: _loadDriverReports,
          )
        else if (report == null || report.isEmpty)
          const AdminEmptyState(
            title: 'No driver report data',
            message:
                'Driver performance reports will appear here when backend data exists.',
            icon: Icons.badge_outlined,
          )
        else ...[
          _DriverReportSummary(
            completedTrips: _completedTrips,
            acceptanceRate: _acceptanceRate,
            delays: _delays,
            performanceScore: _performanceScore,
            emergencyCount: _emergencyCount,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (rows.isEmpty)
            const AdminEmptyState(
              title: 'No drivers match filters',
              message:
                  'Adjust status or zone filters to restore driver report rows.',
              icon: Icons.filter_alt_off_outlined,
            )
          else ...[
            _DriverReportCharts(rows: rows),
            const SizedBox(height: AppSpacing.lg),
            _DriverReportTable(rows: rows),
          ],
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
}

String _isoDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class _DriverReportHeader extends StatelessWidget {
  const _DriverReportHeader({
    required this.dateRangeFilter,
    required this.statusFilter,
    required this.zoneFilter,
    required this.onExportPdf,
    required this.onExportCsv,
  });

  final String dateRangeFilter;
  final String statusFilter;
  final String zoneFilter;
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
                  label: 'Driver analytics',
                  tone: AdminStatusTone.info,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Driver reports',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Completed trips, acceptance rate, delays, performance score, and emergency counts with backend exports.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            );

            final exportPanel = _DriverExportPanel(
              dateRangeFilter: dateRangeFilter,
              statusFilter: statusFilter,
              zoneFilter: zoneFilter,
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

class _DriverExportPanel extends StatelessWidget {
  const _DriverExportPanel({
    required this.dateRangeFilter,
    required this.statusFilter,
    required this.zoneFilter,
    required this.onExportPdf,
    required this.onExportCsv,
  });

  final String dateRangeFilter;
  final String statusFilter;
  final String zoneFilter;
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
            '$dateRangeFilter - $statusFilter - $zoneFilter',
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

class _DriverReportFilters extends StatelessWidget {
  const _DriverReportFilters({
    required this.dateRangeFilters,
    required this.selectedDateRangeFilter,
    required this.statusFilters,
    required this.selectedStatusFilter,
    required this.zoneFilters,
    required this.selectedZoneFilter,
    required this.onDateRangeChanged,
    required this.onStatusChanged,
    required this.onZoneChanged,
    required this.onReset,
  });

  final List<String> dateRangeFilters;
  final String selectedDateRangeFilter;
  final List<String> statusFilters;
  final String selectedStatusFilter;
  final List<String> zoneFilters;
  final String selectedZoneFilter;
  final ValueChanged<String> onDateRangeChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onZoneChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        selectedDateRangeFilter != dateRangeFilters.first ||
        selectedStatusFilter != statusFilters.first ||
        selectedZoneFilter != zoneFilters.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dateRange = _DriverReportDropdown(
              key: ValueKey('driver-report-date-$selectedDateRangeFilter'),
              label: 'Date range',
              icon: Icons.date_range_outlined,
              value: selectedDateRangeFilter,
              options: dateRangeFilters,
              onChanged: onDateRangeChanged,
            );
            final status = _DriverReportDropdown(
              key: ValueKey('driver-report-status-$selectedStatusFilter'),
              label: 'Status',
              icon: Icons.filter_alt_outlined,
              value: selectedStatusFilter,
              options: statusFilters,
              onChanged: onStatusChanged,
            );
            final zone = _DriverReportDropdown(
              key: ValueKey('driver-report-zone-$selectedZoneFilter'),
              label: 'Zone',
              icon: Icons.route_outlined,
              value: selectedZoneFilter,
              options: zoneFilters,
              onChanged: onZoneChanged,
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
                  Expanded(child: zone),
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
                zone,
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

class _DriverReportDropdown extends StatelessWidget {
  const _DriverReportDropdown({
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

class _DriverReportSummary extends StatelessWidget {
  const _DriverReportSummary({
    required this.completedTrips,
    required this.acceptanceRate,
    required this.delays,
    required this.performanceScore,
    required this.emergencyCount,
  });

  final int completedTrips;
  final double acceptanceRate;
  final int delays;
  final double performanceScore;
  final int emergencyCount;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricTile(
        label: 'Completed trips',
        value: '$completedTrips',
        icon: Icons.task_alt_rounded,
        tone: AdminStatusTone.success,
      ),
      _MetricTile(
        label: 'Acceptance rate',
        value: '${acceptanceRate.toStringAsFixed(1)}%',
        icon: Icons.how_to_reg_outlined,
        tone: AdminStatusTone.primary,
      ),
      _MetricTile(
        label: 'Delays',
        value: '$delays',
        icon: Icons.schedule_outlined,
        tone: delays > 10 ? AdminStatusTone.warning : AdminStatusTone.info,
      ),
      _MetricTile(
        label: 'Performance score',
        value: performanceScore.toStringAsFixed(1),
        icon: Icons.speed_outlined,
        tone: performanceScore >= 90
            ? AdminStatusTone.success
            : AdminStatusTone.warning,
      ),
      _MetricTile(
        label: 'Emergency count',
        value: '$emergencyCount',
        icon: Icons.emergency_outlined,
        tone: emergencyCount == 0
            ? AdminStatusTone.success
            : AdminStatusTone.danger,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 5
            : constraints.maxWidth >= 760
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
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
              width: 46,
              height: 46,
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

class _DriverReportCharts extends StatelessWidget {
  const _DriverReportCharts({required this.rows});

  final List<AdminDriverReportMock> rows;

  @override
  Widget build(BuildContext context) {
    final charts = [
      AdminChartCard(
        title: 'Completed trips',
        subtitle: 'Trips completed by driver',
        trailing: AdminStatusBadge(
          label: '${rows.length} drivers',
          tone: AdminStatusTone.success,
        ),
        entries: [
          for (final row in rows)
            AdminChartEntry(
              label: row.name.split(' ').first,
              value: row.completedTrips.toDouble(),
            ),
        ],
      ),
      AdminChartCard(
        title: 'Performance score',
        subtitle: 'Composite score by driver',
        trailing: const AdminStatusBadge(
          label: 'Score',
          tone: AdminStatusTone.primary,
        ),
        entries: [
          for (final row in rows)
            AdminChartEntry(
              label: row.name.split(' ').first,
              value: row.performanceScore.toDouble(),
            ),
        ],
      ),
      AdminChartCard(
        title: 'Delays and emergencies',
        subtitle: 'Operational incidents by driver',
        trailing: const AdminStatusBadge(
          label: 'Risk',
          tone: AdminStatusTone.warning,
        ),
        entries: [
          for (final row in rows)
            AdminChartEntry(
              label: row.name.split(' ').first,
              value: (row.delays + row.emergencyCount).toDouble(),
            ),
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

class _DriverReportTable extends StatelessWidget {
  const _DriverReportTable({required this.rows});

  final List<AdminDriverReportMock> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Driver performance table',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Completed trips, acceptance, delays, score, and emergency events by driver.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        AdminDataTable(
          dataRowMinHeight: 82,
          dataRowMaxHeight: 104,
          columns: const [
            AdminTableColumn('Driver'),
            AdminTableColumn('Status'),
            AdminTableColumn('Zone'),
            AdminTableColumn('Completed trips'),
            AdminTableColumn('Acceptance rate'),
            AdminTableColumn('Delays'),
            AdminTableColumn('Performance score'),
            AdminTableColumn('Emergency count'),
            AdminTableColumn('On-time rate'),
            AdminTableColumn('Rating'),
          ],
          rows: [
            for (final row in rows)
              [
                _DriverCell(driver: row),
                AdminStatusBadge.fromStatus(row.status),
                SizedBox(width: 170, child: Text(row.zone)),
                Text('${row.completedTrips}'),
                Text('${row.acceptanceRate.toStringAsFixed(0)}%'),
                Text('${row.delays}'),
                AdminStatusBadge(
                  label: '${row.performanceScore}',
                  tone: row.performanceScore >= 90
                      ? AdminStatusTone.success
                      : AdminStatusTone.warning,
                ),
                Text('${row.emergencyCount}'),
                Text('${row.onTimeRate.toStringAsFixed(0)}%'),
                Text(row.rating.toStringAsFixed(1)),
              ],
          ],
        ),
      ],
    );
  }
}

class _DriverCell extends StatelessWidget {
  const _DriverCell({required this.driver});

  final AdminDriverReportMock driver;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(driver.name, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(driver.id, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
