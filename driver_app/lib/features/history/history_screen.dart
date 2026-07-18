import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/mock_driver_data.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../trips/data/driver_trip_api.dart';
import '../trips/data/driver_trip_models.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  var _query = '';
  var _statusFilter = _HistoryStatusFilter.all;
  var _dateFilter = _HistoryDateFilter.all;
  var _records = <_HistoryTripRecord>[];
  var _isLoading = true;
  String? _errorMessage;

  DriverTripApi get _api => ref.read(driverTripApiProvider);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_HistoryTripRecord> get _filteredTrips {
    return _records.where((record) {
      final trip = record.trip;
      final normalizedQuery = _query.trim().toLowerCase();
      final matchesQuery =
          normalizedQuery.isEmpty ||
          trip.id.toLowerCase().contains(normalizedQuery) ||
          trip.pickup.toLowerCase().contains(normalizedQuery) ||
          trip.delivery.toLowerCase().contains(normalizedQuery) ||
          trip.package.toLowerCase().contains(normalizedQuery);
      final matchesStatus = switch (_statusFilter) {
        _HistoryStatusFilter.all => true,
        _HistoryStatusFilter.completed => trip.status == 'Completed',
        _HistoryStatusFilter.delivered => trip.status == 'Delivered',
      };
      final matchesDate = switch (_dateFilter) {
        _HistoryDateFilter.all => true,
        _HistoryDateFilter.last7Days => record.daysAgo <= 7,
        _HistoryDateFilter.last30Days => record.daysAgo <= 30,
      };

      return matchesQuery && matchesStatus && matchesDate;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _query = '';
      _statusFilter = _HistoryStatusFilter.all;
      _dateFilter = _HistoryDateFilter.all;
    });
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _api.listTripHistory(limit: 50);
      if (!mounted) {
        return;
      }
      setState(() {
        _records = result.trips.map(_HistoryTripRecord.fromApi).toList();
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    }
  }

  void _openDetails(DriverTripMock trip) {
    context.go(
      Uri(
        path: AppRoutes.tripDetails,
        queryParameters: {
          if (trip.assignmentId != null)
            'assignmentId': trip.assignmentId.toString(),
          'shipmentId': trip.id,
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTrips = _filteredTrips;

    return CommonAppScaffold(
      title: 'Trip history',
      subtitle: 'Completed and delivered trips from your driver account.',
      bottomNavigationIndex: 2,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const LoadingWidget(message: 'Loading trip history')
          else if (_errorMessage != null)
            ErrorStateWidget(
              title: 'Could not load trip history',
              message: _errorMessage!,
              onRetry: _loadHistory,
            )
          else ...[
            _PerformanceSummaryCard(records: filteredTrips),
            const SizedBox(height: AppSpacing.lg),
            _HistoryFiltersCard(
              searchController: _searchController,
              query: _query,
              statusFilter: _statusFilter,
              dateFilter: _dateFilter,
              onQueryChanged: (value) => setState(() => _query = value),
              onStatusChanged: (value) => setState(() => _statusFilter = value),
              onDateChanged: (value) => setState(() => _dateFilter = value),
              onClearQuery: () {
                setState(() {
                  _searchController.clear();
                  _query = '';
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _HistoryResultsHeader(
              count: filteredTrips.length,
              totalCount: _records.length,
            ),
            const SizedBox(height: AppSpacing.md),
            if (filteredTrips.isEmpty)
              EmptyStateWidget(
                title: 'No trips match these filters',
                message:
                    'Try a shipment ID, route city, package type, or clear filters.',
                icon: Icons.manage_search_rounded,
              )
            else
              for (final record in filteredTrips) ...[
                _HistoryTripCard(
                  record: record,
                  onDetailsPressed: () => _openDetails(record.trip),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            if (filteredTrips.isEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset filters'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PerformanceSummaryCard extends StatelessWidget {
  const _PerformanceSummaryCard({required this.records});

  final List<_HistoryTripRecord> records;

  @override
  Widget build(BuildContext context) {
    final completedCount = records.length;
    final totalDistance = records.fold<int>(
      0,
      (sum, record) => sum + _parseLeadingNumber(record.trip.distance),
    );
    final totalPayout = records.fold<int>(
      0,
      (sum, record) => sum + _parseMoney(record.trip.payout),
    );
    final onTimeCount = records.where((record) => record.wasOnTime).length;
    final onTimeLabel = completedCount == 0
        ? '0%'
        : '${((onTimeCount / completedCount) * 100).round()}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.textInverse.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.roadYellow,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textInverse,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Totals update with search and filters.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.surfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth >= 620
                  ? (constraints.maxWidth - AppSpacing.md * 3) / 4
                  : (constraints.maxWidth - AppSpacing.md) / 2;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  _SummaryMetric(
                    width: itemWidth,
                    label: 'Trips',
                    value: '$completedCount',
                    icon: Icons.done_all_rounded,
                  ),
                  _SummaryMetric(
                    width: itemWidth,
                    label: 'Distance',
                    value: '$totalDistance km',
                    icon: Icons.route_rounded,
                  ),
                  _SummaryMetric(
                    width: itemWidth,
                    label: 'Payout',
                    value: _formatInr(totalPayout),
                    icon: Icons.payments_outlined,
                  ),
                  _SummaryMetric(
                    width: itemWidth,
                    label: 'On time',
                    value: onTimeLabel,
                    icon: Icons.schedule_rounded,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.textInverse.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: AppColors.textInverse.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.roadYellow, size: 22),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.surfaceMuted),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textInverse),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryFiltersCard extends StatelessWidget {
  const _HistoryFiltersCard({
    required this.searchController,
    required this.query,
    required this.statusFilter,
    required this.dateFilter,
    required this.onQueryChanged,
    required this.onStatusChanged,
    required this.onDateChanged,
    required this.onClearQuery,
  });

  final TextEditingController searchController;
  final String query;
  final _HistoryStatusFilter statusFilter;
  final _HistoryDateFilter dateFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<_HistoryStatusFilter> onStatusChanged;
  final ValueChanged<_HistoryDateFilter> onDateChanged;
  final VoidCallback onClearQuery;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onChanged: onQueryChanged,
              decoration: InputDecoration(
                labelText: 'Search completed trips',
                hintText: 'Shipment ID, city, route, or package type',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: onClearQuery,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Status', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final filter in _HistoryStatusFilter.values)
                  ChoiceChip(
                    selected: statusFilter == filter,
                    label: Text(filter.label),
                    avatar: Icon(filter.icon, size: 18),
                    onSelected: (_) => onStatusChanged(filter),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Date range', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final filter in _HistoryDateFilter.values)
                  ChoiceChip(
                    selected: dateFilter == filter,
                    label: Text(filter.label),
                    avatar: Icon(filter.icon, size: 18),
                    onSelected: (_) => onDateChanged(filter),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryResultsHeader extends StatelessWidget {
  const _HistoryResultsHeader({required this.count, required this.totalCount});

  final int count;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Completed trips',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        StatusBadge(
          label: '$count of $totalCount shown',
          tone: count == totalCount
              ? StatusBadgeTone.completed
              : StatusBadgeTone.neutral,
        ),
      ],
    );
  }
}

class _HistoryTripCard extends StatelessWidget {
  const _HistoryTripCard({
    required this.record,
    required this.onDetailsPressed,
  });

  final _HistoryTripRecord record;
  final VoidCallback onDetailsPressed;

  @override
  Widget build(BuildContext context) {
    final trip = record.trip;

    return Card(
      child: InkWell(
        onTap: onDetailsPressed,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.cardRadius,
                      ),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.id,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${trip.package} - ${trip.vehicle}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge.fromTripStatus(trip.status),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 560;
                  final route = _HistoryRouteBlock(trip: trip);
                  final metrics = _HistoryMetricsBlock(record: record);

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: route),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(flex: 2, child: metrics),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      route,
                      const SizedBox(height: AppSpacing.md),
                      metrics,
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  StatusBadge(
                    label: record.proofStatus,
                    tone: record.proofTone,
                  ),
                  StatusBadge(
                    label: record.wasOnTime ? 'On time' : 'Delayed',
                    tone: record.wasOnTime
                        ? StatusBadgeTone.completed
                        : StatusBadgeTone.warning,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onDetailsPressed,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('View details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryRouteBlock extends StatelessWidget {
  const _HistoryRouteBlock({required this.trip});

  final DriverTripMock trip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RouteLine(
          icon: Icons.my_location_rounded,
          label: 'Pickup',
          value: trip.pickup,
        ),
        const SizedBox(height: AppSpacing.sm),
        _RouteLine(
          icon: Icons.location_on_rounded,
          label: 'Delivery',
          value: trip.delivery,
        ),
      ],
    );
  }
}

class _HistoryMetricsBlock extends StatelessWidget {
  const _HistoryMetricsBlock({required this.record});

  final _HistoryTripRecord record;

  @override
  Widget build(BuildContext context) {
    final trip = record.trip;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _MetricRow(
            icon: Icons.calendar_month_outlined,
            label: 'Completed',
            value: record.completedOn,
          ),
          const Divider(height: AppSpacing.lg),
          _MetricRow(
            icon: Icons.social_distance_rounded,
            label: 'Distance',
            value: trip.distance,
          ),
          const Divider(height: AppSpacing.lg),
          _MetricRow(
            icon: Icons.payments_outlined,
            label: 'Payout',
            value: trip.payout,
          ),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryBlue),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}

enum _HistoryStatusFilter {
  all('All', Icons.all_inclusive_rounded),
  completed('Completed', Icons.verified_rounded),
  delivered('Delivered', Icons.local_shipping_outlined);

  const _HistoryStatusFilter(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum _HistoryDateFilter {
  all('All dates', Icons.event_available_outlined),
  last7Days('Last 7 days', Icons.date_range_rounded),
  last30Days('Last 30 days', Icons.calendar_view_month_rounded);

  const _HistoryDateFilter(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _HistoryTripRecord {
  const _HistoryTripRecord({
    required this.trip,
    required this.completedOn,
    required this.daysAgo,
    required this.proofStatus,
    required this.proofTone,
    required this.wasOnTime,
  });

  final DriverTripMock trip;
  final String completedOn;
  final int daysAgo;
  final String proofStatus;
  final StatusBadgeTone proofTone;
  final bool wasOnTime;

  factory _HistoryTripRecord.fromApi(DriverTripSummary trip) {
    final model = trip.toTripCardModel();
    final completedOn = trip.completedAt ?? trip.acceptedAt ?? trip.assignedAt;
    return _HistoryTripRecord(
      trip: model,
      completedOn: _formatHistoryDate(completedOn),
      daysAgo: _daysAgo(completedOn),
      proofStatus: trip.assignmentStatus == 'completed'
          ? 'Proof verified'
          : 'Delivery proof pending',
      proofTone: trip.assignmentStatus == 'completed'
          ? StatusBadgeTone.completed
          : StatusBadgeTone.warning,
      wasOnTime: trip.assignmentStatus == 'completed',
    );
  }
}

int _parseLeadingNumber(String value) {
  final match = RegExp(r'\d+').firstMatch(value.replaceAll(',', ''));
  return int.tryParse(match?.group(0) ?? '') ?? 0;
}

int _parseMoney(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(digits) ?? 0;
}

String _formatInr(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final fromRight = raw.length - i;
    buffer.write(raw[i]);
    if (fromRight > 1 && fromRight % 3 == 1) {
      buffer.write(',');
    }
  }
  return 'INR $buffer';
}

String _formatHistoryDate(String? value) {
  final parsed = DateTime.tryParse(value ?? '');
  if (parsed == null) {
    return 'Completed date pending';
  }
  final local = parsed.toLocal();
  final month = const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][local.month - 1];
  return '$month ${local.day}, ${local.year}';
}

int _daysAgo(String? value) {
  final parsed = DateTime.tryParse(value ?? '');
  if (parsed == null) {
    return 0;
  }
  return DateTime.now().difference(parsed).inDays;
}
