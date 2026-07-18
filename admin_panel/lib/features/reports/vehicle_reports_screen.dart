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

String _formatDate(BuildContext context, DateTime date) {
  return MaterialLocalizations.of(context).formatMediumDate(date);
}

int _daysUntilService(DateTime serviceDue) {
  return serviceDue.difference(DateTime.now()).inDays;
}

class VehicleReportsScreen extends ConsumerStatefulWidget {
  const VehicleReportsScreen({super.key});

  @override
  ConsumerState<VehicleReportsScreen> createState() =>
      _VehicleReportsScreenState();
}

class _VehicleReportsScreenState extends ConsumerState<VehicleReportsScreen> {
  static const _dateRangeFilters = [
    'Last 7 days',
    'This month',
    'Last 90 days',
    'Custom range',
  ];
  static const _availabilityFilters = [
    'All availability',
    'Available',
    'Busy',
    'Maintenance',
    'On Leave',
  ];
  static const _typeFilters = [
    'All vehicle types',
    'Pickup Van',
    '14 ft Truck',
    'Mini Truck',
    'Reefer Van',
    'Open Truck',
    'Container Truck',
  ];

  String _dateRangeFilter = _dateRangeFilters.first;
  String _availabilityFilter = _availabilityFilters.first;
  String _typeFilter = _typeFilters.first;
  bool _isLoading = true;
  bool _hasLoadError = false;
  AdminVehicleReportUiData? _report;

  List<AdminVehicleReportMock> get _filteredRows {
    final rows = _report?.rows ?? const <AdminVehicleReportMock>[];
    return rows.where((vehicle) {
      final matchesAvailability =
          _availabilityFilter == _availabilityFilters.first ||
          vehicle.availability == _availabilityFilter;
      final matchesType =
          _typeFilter == _typeFilters.first || vehicle.type == _typeFilter;
      return matchesAvailability && matchesType;
    }).toList();
  }

  List<AdminVehicleAssignmentHistoryReportMock> get _filteredAssignments {
    final vehicleNumbers = _filteredRows
        .map((vehicle) => vehicle.vehicleNumber)
        .toSet();
    return (_report?.assignments ??
            const <AdminVehicleAssignmentHistoryReportMock>[])
        .where((row) => vehicleNumbers.contains(row.vehicleNumber))
        .toList();
  }

  List<AdminVehicleBreakdownReportMock> get _filteredBreakdowns {
    final vehicleNumbers = _filteredRows
        .map((vehicle) => vehicle.vehicleNumber)
        .toSet();
    return (_report?.breakdowns ?? const <AdminVehicleBreakdownReportMock>[])
        .where((row) => vehicleNumbers.contains(row.vehicleNumber))
        .toList();
  }

  int get _averageUtilization {
    final rows = _filteredRows;
    if (rows.isEmpty) {
      return 0;
    }
    final total = rows.fold<int>(
      0,
      (sum, vehicle) => sum + vehicle.utilization,
    );
    return (total / rows.length).round();
  }

  int get _serviceDueSoon => _filteredRows
      .where((vehicle) => _daysUntilService(vehicle.serviceDue) <= 14)
      .length;

  int get _busyVehicles =>
      _filteredRows.where((vehicle) => vehicle.availability == 'Busy').length;

  int get _breakdownCount => _filteredRows.fold<int>(
    0,
    (sum, vehicle) => sum + vehicle.breakdownCount,
  );

  @override
  void initState() {
    super.initState();
    _loadVehicleReports();
  }

  Future<void> _loadVehicleReports() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });

    try {
      final report = await ref
          .read(adminApiServiceProvider)
          .fetchVehicleReportUi(query: {'limit': 100, ..._dateRangeQuery()});
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
      _availabilityFilter = _availabilityFilters.first;
      _typeFilter = _typeFilters.first;
    });
    _loadVehicleReports();
  }

  Future<void> _showExportMessage(String format) async {
    try {
      final bytes = await ref
          .read(adminApiServiceProvider)
          .exportReport('vehicles', format, query: _dateRangeQuery());
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$format vehicle report fetched from API ($bytes bytes).',
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
    final rows = _filteredRows;
    final report = _report;
    final assignments = _filteredAssignments;
    final breakdowns = _filteredBreakdowns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VehicleReportHeader(
          dateRangeFilter: _dateRangeFilter,
          availabilityFilter: _availabilityFilter,
          typeFilter: _typeFilter,
          onExportPdf: () => _showExportMessage('PDF'),
          onExportCsv: () => _showExportMessage('CSV'),
        ),
        const SizedBox(height: AppSpacing.lg),
        _VehicleReportFilters(
          dateRangeFilters: _dateRangeFilters,
          selectedDateRangeFilter: _dateRangeFilter,
          availabilityFilters: _availabilityFilters,
          selectedAvailabilityFilter: _availabilityFilter,
          typeFilters: _typeFilters,
          selectedTypeFilter: _typeFilter,
          onDateRangeChanged: (value) {
            setState(() => _dateRangeFilter = value);
            _loadVehicleReports();
          },
          onAvailabilityChanged: (value) =>
              setState(() => _availabilityFilter = value),
          onTypeChanged: (value) => setState(() => _typeFilter = value),
          onReset: _resetFilters,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_isLoading)
          const AdminLoadingState(message: 'Loading vehicle reports...')
        else if (_hasLoadError)
          AdminErrorState(
            title: 'Vehicle reports unavailable',
            message:
                'Vehicle report API could not be loaded. Retry to restore utilization, service, assignment, and breakdown data.',
            onRetry: _loadVehicleReports,
          )
        else if (report == null || report.isEmpty)
          const AdminEmptyState(
            title: 'No vehicle report data',
            message:
                'Fleet utilization reports will appear here when backend data exists.',
            icon: Icons.local_shipping_outlined,
          )
        else ...[
          _VehicleReportSummary(
            totalVehicles: rows.length,
            averageUtilization: _averageUtilization,
            serviceDueSoon: _serviceDueSoon,
            busyVehicles: _busyVehicles,
            breakdownCount: _breakdownCount,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (rows.isEmpty)
            const AdminEmptyState(
              title: 'No vehicles match filters',
              message:
                  'Adjust availability or vehicle type filters to restore fleet report rows.',
              icon: Icons.filter_alt_off_outlined,
            )
          else ...[
            _VehicleReportCharts(
              rows: rows,
              assignments: assignments,
              breakdowns: breakdowns,
            ),
            const SizedBox(height: AppSpacing.lg),
            _FleetUtilizationSection(rows: rows),
            const SizedBox(height: AppSpacing.lg),
            _AssignmentHistorySection(rows: assignments),
            const SizedBox(height: AppSpacing.lg),
            _BreakdownSection(rows: breakdowns),
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

class _VehicleReportHeader extends StatelessWidget {
  const _VehicleReportHeader({
    required this.dateRangeFilter,
    required this.availabilityFilter,
    required this.typeFilter,
    required this.onExportPdf,
    required this.onExportCsv,
  });

  final String dateRangeFilter;
  final String availabilityFilter;
  final String typeFilter;
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
                  label: 'Fleet analytics',
                  tone: AdminStatusTone.warning,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Vehicle reports',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Utilization, service due exposure, assignment history, and breakdown reporting with backend exports.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            );

            final exportPanel = _VehicleExportPanel(
              dateRangeFilter: dateRangeFilter,
              availabilityFilter: availabilityFilter,
              typeFilter: typeFilter,
              onExportPdf: onExportPdf,
              onExportCsv: onExportCsv,
            );

            if (constraints.maxWidth >= 940) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: AppSpacing.lg),
                  SizedBox(width: 400, child: exportPanel),
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

class _VehicleExportPanel extends StatelessWidget {
  const _VehicleExportPanel({
    required this.dateRangeFilter,
    required this.availabilityFilter,
    required this.typeFilter,
    required this.onExportPdf,
    required this.onExportCsv,
  });

  final String dateRangeFilter;
  final String availabilityFilter;
  final String typeFilter;
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
            '$dateRangeFilter - $availabilityFilter - $typeFilter',
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

class _VehicleReportFilters extends StatelessWidget {
  const _VehicleReportFilters({
    required this.dateRangeFilters,
    required this.selectedDateRangeFilter,
    required this.availabilityFilters,
    required this.selectedAvailabilityFilter,
    required this.typeFilters,
    required this.selectedTypeFilter,
    required this.onDateRangeChanged,
    required this.onAvailabilityChanged,
    required this.onTypeChanged,
    required this.onReset,
  });

  final List<String> dateRangeFilters;
  final String selectedDateRangeFilter;
  final List<String> availabilityFilters;
  final String selectedAvailabilityFilter;
  final List<String> typeFilters;
  final String selectedTypeFilter;
  final ValueChanged<String> onDateRangeChanged;
  final ValueChanged<String> onAvailabilityChanged;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        selectedDateRangeFilter != dateRangeFilters.first ||
        selectedAvailabilityFilter != availabilityFilters.first ||
        selectedTypeFilter != typeFilters.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dateRange = _VehicleReportDropdown(
              key: ValueKey('vehicle-report-date-$selectedDateRangeFilter'),
              label: 'Date range',
              icon: Icons.date_range_outlined,
              value: selectedDateRangeFilter,
              options: dateRangeFilters,
              onChanged: onDateRangeChanged,
            );
            final availability = _VehicleReportDropdown(
              key: ValueKey(
                'vehicle-report-availability-$selectedAvailabilityFilter',
              ),
              label: 'Availability',
              icon: Icons.local_shipping_outlined,
              value: selectedAvailabilityFilter,
              options: availabilityFilters,
              onChanged: onAvailabilityChanged,
            );
            final vehicleType = _VehicleReportDropdown(
              key: ValueKey('vehicle-report-type-$selectedTypeFilter'),
              label: 'Vehicle type',
              icon: Icons.category_outlined,
              value: selectedTypeFilter,
              options: typeFilters,
              onChanged: onTypeChanged,
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
                  Expanded(child: availability),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: vehicleType),
                  const SizedBox(width: AppSpacing.md),
                  Padding(padding: const EdgeInsets.only(top: 6), child: reset),
                ],
              );
            }

            return Column(
              children: [
                dateRange,
                const SizedBox(height: AppSpacing.md),
                availability,
                const SizedBox(height: AppSpacing.md),
                vehicleType,
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

class _VehicleReportDropdown extends StatelessWidget {
  const _VehicleReportDropdown({
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

class _VehicleReportSummary extends StatelessWidget {
  const _VehicleReportSummary({
    required this.totalVehicles,
    required this.averageUtilization,
    required this.serviceDueSoon,
    required this.busyVehicles,
    required this.breakdownCount,
  });

  final int totalVehicles;
  final int averageUtilization;
  final int serviceDueSoon;
  final int busyVehicles;
  final int breakdownCount;

  @override
  Widget build(BuildContext context) {
    final cards = [
      AdminStatCard(
        label: 'Utilization',
        value: '$averageUtilization%',
        delta: '$totalVehicles vehicles in scope',
        icon: Icons.speed_outlined,
        isPositive: averageUtilization >= 70,
        accentColor: AppColors.primaryBlue,
      ),
      AdminStatCard(
        label: 'Service due',
        value: '$serviceDueSoon',
        delta: 'Due within 14 days',
        icon: Icons.build_outlined,
        isPositive: serviceDueSoon == 0,
        accentColor: AppColors.warning,
      ),
      AdminStatCard(
        label: 'Busy vehicles',
        value: '$busyVehicles',
        delta: 'Currently assigned',
        icon: Icons.route_outlined,
        isPositive: true,
        accentColor: AppColors.success,
      ),
      AdminStatCard(
        label: 'Breakdowns',
        value: '$breakdownCount',
        delta: 'Incidents in selected period',
        icon: Icons.report_gmailerrorred_outlined,
        isPositive: breakdownCount == 0,
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

class _VehicleReportCharts extends StatelessWidget {
  const _VehicleReportCharts({
    required this.rows,
    required this.assignments,
    required this.breakdowns,
  });

  final List<AdminVehicleReportMock> rows;
  final List<AdminVehicleAssignmentHistoryReportMock> assignments;
  final List<AdminVehicleBreakdownReportMock> breakdowns;

  @override
  Widget build(BuildContext context) {
    final charts = [
      AdminChartCard(
        title: 'Vehicle utilization',
        subtitle: 'Utilization percentage by vehicle',
        trailing: AdminStatusBadge(
          label: '${rows.length} vehicles',
          tone: AdminStatusTone.primary,
        ),
        entries: [
          for (final row in rows)
            AdminChartEntry(
              label: _shortVehicleLabel(row.vehicleNumber),
              value: row.utilization.toDouble(),
            ),
        ],
      ),
      AdminChartCard(
        title: 'Service due',
        subtitle: 'Days until next scheduled service',
        trailing: const AdminStatusBadge(
          label: 'Calendar',
          tone: AdminStatusTone.warning,
        ),
        entries: [
          for (final row in rows)
            AdminChartEntry(
              label: _shortVehicleLabel(row.vehicleNumber),
              value: _daysUntilService(row.serviceDue).clamp(0, 120).toDouble(),
            ),
        ],
      ),
      AdminChartCard(
        title: 'Assignment history',
        subtitle: 'Assignment count by vehicle in scope',
        trailing: AdminStatusBadge(
          label: '${assignments.length} trips',
          tone: AdminStatusTone.success,
        ),
        entries: [
          for (final row in rows)
            AdminChartEntry(
              label: _shortVehicleLabel(row.vehicleNumber),
              value: row.assignmentCount.toDouble(),
            ),
        ],
      ),
      AdminChartCard(
        title: 'Breakdowns',
        subtitle: 'Reported issues by vehicle',
        trailing: AdminStatusBadge(
          label: '${breakdowns.length} reports',
          tone: breakdowns.isEmpty
              ? AdminStatusTone.success
              : AdminStatusTone.danger,
        ),
        entries: [
          for (final row in rows)
            AdminChartEntry(
              label: _shortVehicleLabel(row.vehicleNumber),
              value: row.breakdownCount.toDouble(),
            ),
        ],
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

class _FleetUtilizationSection extends StatelessWidget {
  const _FleetUtilizationSection({required this.rows});

  final List<AdminVehicleReportMock> rows;

  @override
  Widget build(BuildContext context) {
    return _VehicleSection(
      title: 'Utilization and service due',
      subtitle:
          'Fleet utilization, service calendar, active assignments, and hub ownership.',
      trailing: AdminStatusBadge(
        label: '${rows.length} vehicles',
        tone: AdminStatusTone.primary,
      ),
      child: AdminDataTable(
        dataRowMinHeight: 92,
        dataRowMaxHeight: 116,
        columns: const [
          AdminTableColumn('Vehicle'),
          AdminTableColumn('Availability'),
          AdminTableColumn('Utilization'),
          AdminTableColumn('Service due'),
          AdminTableColumn('Assignments'),
          AdminTableColumn('Breakdowns'),
          AdminTableColumn('Assigned driver / trip'),
          AdminTableColumn('Hub'),
        ],
        rows: [
          for (final row in rows)
            [
              _VehicleCell(vehicle: row),
              AdminStatusBadge.fromStatus(row.availability),
              _UtilizationCell(value: row.utilization),
              _ServiceDueCell(date: row.serviceDue),
              Text('${row.assignmentCount}'),
              AdminStatusBadge(
                label: '${row.breakdownCount}',
                tone: row.breakdownCount == 0
                    ? AdminStatusTone.success
                    : AdminStatusTone.warning,
              ),
              _AssignmentCell(vehicle: row),
              SizedBox(width: 170, child: Text(row.hub)),
            ],
        ],
      ),
    );
  }
}

class _AssignmentHistorySection extends StatelessWidget {
  const _AssignmentHistorySection({required this.rows});

  final List<AdminVehicleAssignmentHistoryReportMock> rows;

  @override
  Widget build(BuildContext context) {
    return _VehicleSection(
      title: 'Assignment history',
      subtitle:
          'Recent vehicle-to-driver assignments and route activity for the selected fleet scope.',
      trailing: AdminStatusBadge(
        label: '${rows.length} assignments',
        tone: AdminStatusTone.success,
      ),
      child: rows.isEmpty
          ? const AdminEmptyState(
              title: 'No assignment history',
              message:
                  'Select another availability or vehicle type filter to restore assignment rows.',
              icon: Icons.route_outlined,
            )
          : AdminDataTable(
              columns: const [
                AdminTableColumn('Date'),
                AdminTableColumn('Vehicle'),
                AdminTableColumn('Trip ID'),
                AdminTableColumn('Driver'),
                AdminTableColumn('Route'),
                AdminTableColumn('Status'),
                AdminTableColumn('Duration'),
              ],
              rows: [
                for (final row in rows)
                  [
                    Text(row.date),
                    Text(row.vehicleNumber),
                    Text(row.tripId),
                    Text(row.driver),
                    SizedBox(width: 220, child: Text(row.route)),
                    AdminStatusBadge.fromStatus(row.status),
                    Text(row.duration),
                  ],
              ],
            ),
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({required this.rows});

  final List<AdminVehicleBreakdownReportMock> rows;

  @override
  Widget build(BuildContext context) {
    return _VehicleSection(
      title: 'Breakdowns',
      subtitle:
          'Vehicle breakdowns, severity, downtime, and current resolution status.',
      trailing: AdminStatusBadge(
        label: '${rows.length} reports',
        tone: rows.isEmpty ? AdminStatusTone.success : AdminStatusTone.warning,
      ),
      child: rows.isEmpty
          ? const AdminEmptyState(
              title: 'No breakdown reports',
              message:
                  'No breakdowns match the current fleet filters in backend data.',
              icon: Icons.build_circle_outlined,
            )
          : AdminDataTable(
              columns: const [
                AdminTableColumn('Date'),
                AdminTableColumn('Vehicle'),
                AdminTableColumn('Issue'),
                AdminTableColumn('Severity'),
                AdminTableColumn('Downtime'),
                AdminTableColumn('Status'),
              ],
              rows: [
                for (final row in rows)
                  [
                    Text(row.date),
                    Text(row.vehicleNumber),
                    SizedBox(width: 240, child: Text(row.issue)),
                    AdminStatusBadge.fromStatus(row.severity),
                    Text(row.downtime),
                    AdminStatusBadge.fromStatus(row.status),
                  ],
              ],
            ),
    );
  }
}

class _VehicleSection extends StatelessWidget {
  const _VehicleSection({
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

class _VehicleCell extends StatelessWidget {
  const _VehicleCell({required this.vehicle});

  final AdminVehicleReportMock vehicle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            vehicle.vehicleNumber,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(vehicle.id, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(vehicle.type, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _UtilizationCell extends StatelessWidget {
  const _UtilizationCell({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final tone = value >= 80
        ? AdminStatusTone.success
        : value >= 65
        ? AdminStatusTone.primary
        : AdminStatusTone.warning;

    return AdminStatusBadge(label: '$value%', tone: tone);
  }
}

class _ServiceDueCell extends StatelessWidget {
  const _ServiceDueCell({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final days = _daysUntilService(date);
    final tone = days <= 7
        ? AdminStatusTone.danger
        : days <= 14
        ? AdminStatusTone.warning
        : AdminStatusTone.success;

    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_formatDate(context, date)),
          const SizedBox(height: AppSpacing.xxs),
          AdminStatusBadge(label: '$days days', tone: tone),
        ],
      ),
    );
  }
}

class _AssignmentCell extends StatelessWidget {
  const _AssignmentCell({required this.vehicle});

  final AdminVehicleReportMock vehicle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(vehicle.assignedDriver),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            vehicle.assignedTrip ?? 'No active trip',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

String _shortVehicleLabel(String vehicleNumber) {
  final parts = vehicleNumber.split('-');
  if (parts.length >= 3) {
    return parts.last;
  }
  return vehicleNumber;
}
