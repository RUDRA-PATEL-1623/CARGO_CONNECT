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

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  AdminDashboardData? _dashboard;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ref.read(adminApiServiceProvider).fetchDashboard();
      if (!mounted) {
        return;
      }
      setState(() {
        _dashboard = data;
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

  @override
  Widget build(BuildContext context) {
    final dashboard = _dashboard;

    if (_isLoading) {
      return const AdminLoadingState(message: 'Loading admin dashboard...');
    }

    if (_errorMessage != null) {
      return AdminErrorState(
        title: 'Dashboard unavailable',
        message: _errorMessage!,
        onRetry: _loadDashboard,
      );
    }

    if (dashboard == null) {
      return AdminErrorState(
        title: 'Dashboard data missing',
        message: 'The backend returned an empty dashboard payload.',
        onRetry: _loadDashboard,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DashboardHeader(dashboard: dashboard),
        const SizedBox(height: AppSpacing.lg),
        _DashboardStatGrid(stats: dashboard.stats),
        const SizedBox(height: AppSpacing.lg),
        _DashboardCharts(dashboard: dashboard),
        const SizedBox(height: AppSpacing.lg),
        _OperationalSnapshot(dashboard: dashboard),
        const SizedBox(height: AppSpacing.lg),
        _RecentActivitySection(activities: dashboard.recentActivity),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.dashboard});

  final AdminDashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: isWide
                ? Row(
                    children: [
                      const Expanded(child: _DashboardHeaderCopy()),
                      const SizedBox(width: AppSpacing.lg),
                      _RevenueCallout(dashboard: dashboard),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DashboardHeaderCopy(),
                      const SizedBox(height: AppSpacing.lg),
                      _RevenueCallout(dashboard: dashboard),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _DashboardHeaderCopy extends StatelessWidget {
  const _DashboardHeaderCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminStatusBadge(
          label: 'Today overview',
          tone: AdminStatusTone.info,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Operations dashboard',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Shipment flow, driver capacity, fleet utilization, and revenue performance from the CargoConnect backend.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _RevenueCallout extends StatelessWidget {
  const _RevenueCallout({required this.dashboard});

  final AdminDashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue summary',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.surfaceMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            dashboard.revenueAmount,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textInverse,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            dashboard.revenueDelta,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.roadYellow),
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: dashboard.utilizationPercent.clamp(0, 1),
            minHeight: 6,
            color: AppColors.roadYellow,
            backgroundColor: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _DashboardStatGrid extends StatelessWidget {
  const _DashboardStatGrid({required this.stats});

  final List<AdminStatMock> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 3
            : constraints.maxWidth >= 760
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final stat in stats)
              SizedBox(
                width: width,
                child: AdminStatCard(
                  label: stat.label,
                  value: stat.value,
                  delta: stat.delta,
                  icon: stat.icon,
                  isPositive: stat.isPositive,
                  accentColor: stat.accentColor,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DashboardCharts extends StatelessWidget {
  const _DashboardCharts({required this.dashboard});

  final AdminDashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    final shipmentTrend = AdminChartCard(
      title: 'Shipment trend',
      subtitle: 'Daily booking volume',
      trailing: const AdminStatusBadge(
        label: '7 days',
        tone: AdminStatusTone.primary,
      ),
      entries: _chartEntries(dashboard.shipmentTrend),
    );
    final revenueByCategory = AdminChartCard(
      title: 'Revenue by category',
      subtitle: 'Service contribution in lakhs',
      trailing: const AdminStatusBadge(
        label: 'MTD',
        tone: AdminStatusTone.success,
      ),
      entries: _chartEntries(
        dashboard.revenueBreakdown,
      ),
    );
    final vehicleUtilization = AdminChartCard(
      title: 'Vehicle utilization',
      subtitle: 'Utilization by fleet type',
      trailing: const AdminStatusBadge(
        label: 'Live',
        tone: AdminStatusTone.warning,
      ),
      entries: _chartEntries(dashboard.vehicleUtilization),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: shipmentTrend),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: revenueByCategory),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: vehicleUtilization),
            ],
          );
        }

        if (constraints.maxWidth >= 820) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: shipmentTrend),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: revenueByCategory),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              vehicleUtilization,
            ],
          );
        }

        return Column(
          children: [
            shipmentTrend,
            const SizedBox(height: AppSpacing.md),
            revenueByCategory,
            const SizedBox(height: AppSpacing.md),
            vehicleUtilization,
          ],
        );
      },
    );
  }
}

class _OperationalSnapshot extends StatelessWidget {
  const _OperationalSnapshot({required this.dashboard});

  final AdminDashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SnapshotCard(
        icon: Icons.groups_2_outlined,
        label: 'Driver capacity',
        value: dashboard.driverCapacity,
        status: 'Healthy',
        tone: AdminStatusTone.success,
      ),
      _SnapshotCard(
        icon: Icons.inventory_outlined,
        label: 'Shipment queue',
        value: dashboard.shipmentQueue,
        status: 'Needs review',
        tone: AdminStatusTone.warning,
      ),
      _SnapshotCard(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Collections',
        value: dashboard.collections,
        status: 'Finance',
        tone: AdminStatusTone.info,
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

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final String status;
  final AdminStatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Icon(icon, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(value, style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AdminStatusBadge(label: status, tone: tone),
          ],
        ),
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.activities});

  final List<AdminRecentActivityMock> activities;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent activity',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            AdminStatusBadge(
              label: '${activities.length} events',
              tone: AdminStatusTone.neutral,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (activities.isEmpty)
          const AdminEmptyState(
            title: 'No recent activity',
            message:
                'Operational events will appear here once the backend has activity records.',
            icon: Icons.history_toggle_off_rounded,
          )
        else
          AdminDataTable(
            columns: const [
              AdminTableColumn('Time'),
              AdminTableColumn('Activity'),
              AdminTableColumn('Reference'),
              AdminTableColumn('Owner'),
              AdminTableColumn('Status'),
              AdminTableColumn('Amount'),
            ],
            rows: [
              for (final activity in activities)
                [
                  Text(activity.time),
                  Text(activity.activity),
                  Text(activity.reference),
                  Text(activity.owner),
                  AdminStatusBadge.fromStatus(activity.status),
                  Text(activity.amount),
                ],
            ],
          ),
      ],
    );
  }
}

List<AdminChartEntry> _chartEntries(List<AdminChartPointMock> points) {
  return [
    for (final point in points)
      AdminChartEntry(label: point.label, value: point.value),
  ];
}
