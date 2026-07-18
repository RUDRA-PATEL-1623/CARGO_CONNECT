import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/customer_bottom_navigation.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../notifications/data/customer_notifications_api.dart';
import '../profile/data/customer_profile_api.dart';
import '../shipment/data/customer_shipment_api.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Future<_HomeDashboardData> _dashboardFuture;

  static const _quickActions = [
    _DashboardAction(
      label: 'Book',
      caption: 'New load',
      icon: Icons.add_box_outlined,
      route: AppRoutes.shipment,
    ),
    _DashboardAction(
      label: 'Track',
      caption: 'Latest',
      icon: Icons.route_rounded,
      route: AppRoutes.tracking,
    ),
    _DashboardAction(
      label: 'Pay',
      caption: 'Open due',
      icon: Icons.payments_outlined,
      route: AppRoutes.payment,
    ),
    _DashboardAction(
      label: 'Invoices',
      caption: 'Latest PDF',
      icon: Icons.receipt_long_rounded,
      route: AppRoutes.invoice,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<_HomeDashboardData> _loadDashboard() async {
    final profile = await ref.read(customerProfileApiProvider).getProfile();
    final history = await ref
        .read(customerShipmentApiProvider)
        .listShipmentHistory(limit: 6);

    var unreadCount = 0;
    try {
      final notifications = await ref
          .read(customerNotificationsApiProvider)
          .listNotifications(limit: 1);
      unreadCount = notifications.unreadCount;
    } catch (_) {
      unreadCount = 0;
    }

    return _HomeDashboardData(
      profile: profile,
      shipments: history.shipments,
      unreadCount: unreadCount,
    );
  }

  void _retry() {
    setState(() => _dashboardFuture = _loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth > 520
                ? AppSpacing.xl
                : AppSpacing.screenPadding;

            return RefreshIndicator(
              onRefresh: () async {
                final future = _loadDashboard();
                setState(() => _dashboardFuture = future);
                await future;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.lg,
                  horizontalPadding,
                  AppSpacing.xl,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth,
                    ),
                    child: FutureBuilder<_HomeDashboardData>(
                      future: _dashboardFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LoadingWidget(
                            message: 'Loading customer dashboard',
                          );
                        }

                        if (snapshot.hasError || snapshot.data == null) {
                          return ErrorStateWidget(
                            title: 'Dashboard unavailable',
                            message: _errorMessage(snapshot.error),
                            onRetry: _retry,
                          );
                        }

                        final dashboard = snapshot.data!;
                        final activeShipment = dashboard.activeShipment;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DashboardHeader(data: dashboard),
                            const SizedBox(height: AppSpacing.lg),
                            if (activeShipment == null)
                              const _NoActiveShipmentCard()
                            else
                              _ActiveShipmentSummary(shipment: activeShipment),
                            const SizedBox(height: AppSpacing.xl),
                            _SectionHeader(
                              title: 'Quick actions',
                              actionLabel: 'Support',
                              onAction: () => context.go(AppRoutes.support),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const _QuickActionsGrid(actions: _quickActions),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              'Shipment categories',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _ShipmentCategories(
                              categories: dashboard.statusCategories,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            const _SupportShortcut(),
                            const SizedBox(height: AppSpacing.xl),
                            _SectionHeader(
                              title: 'Recent shipments',
                              actionLabel: 'View all',
                              onAction: () =>
                                  context.go(AppRoutes.shipmentHistory),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (dashboard.shipments.isEmpty)
                              EmptyStateWidget(
                                icon: Icons.inventory_2_outlined,
                                title: 'No shipments yet',
                                message:
                                    'Book your first shipment to see live status, invoices, and proof records here.',
                                action: ElevatedButton.icon(
                                  onPressed: () =>
                                      context.go(AppRoutes.shipment),
                                  icon: const Icon(Icons.add_box_outlined),
                                  label: const Text('Book shipment'),
                                ),
                              )
                            else
                              for (final shipment in dashboard.shipments) ...[
                                _RecentShipmentCard(shipment: shipment),
                                const SizedBox(height: AppSpacing.sm),
                              ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const CustomerBottomNavigation(selectedIndex: 0),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.data});

  final _HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good ${_dayPart()}, ${data.profile.displayName}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                _dashboardSubtitle(data),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _HeaderIconButton(
          tooltip: 'Support',
          icon: Icons.support_agent_rounded,
          onPressed: () => context.go(AppRoutes.support),
        ),
        const SizedBox(width: AppSpacing.xs),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _HeaderIconButton(
              tooltip: 'Notifications',
              icon: Icons.notifications_none_rounded,
              onPressed: () => context.go(AppRoutes.notifications),
            ),
            if (data.unreadCount > 0)
              Positioned(
                right: 7,
                top: 7,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    data.unreadCount > 9 ? '9+' : data.unreadCount.toString(),
                    style: const TextStyle(
                      color: AppColors.textInverse,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      icon: Icon(icon),
    );
  }
}

class _NoActiveShipmentCard extends StatelessWidget {
  const _NoActiveShipmentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.add_road_rounded,
            color: AppColors.roadYellow,
            size: 42,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No active shipment',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppColors.textInverse),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Create a shipment to start tracking pickup, delivery, invoice, and proof updates.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.surfaceMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.shipment),
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Book shipment'),
          ),
        ],
      ),
    );
  }
}

class _ActiveShipmentSummary extends StatelessWidget {
  const _ActiveShipmentSummary({required this.shipment});

  final CustomerShipment shipment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.textInverse.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: const Icon(
                  Icons.fire_truck_rounded,
                  color: AppColors.roadYellow,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active shipment',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.surfaceMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      shipment.shipmentCode,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textInverse,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: _statusFromApi(shipment.shipmentStatus)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _routeLabel(shipment),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppColors.textInverse),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${_weightLabel(shipment)} - ${_vehicleLabel(shipment.vehiclePreference)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.surfaceMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: _statusProgress(shipment.shipmentStatus),
              backgroundColor: AppColors.textInverse.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.roadYellow),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Status',
                  value: _titleCase(shipment.shipmentStatus),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SummaryMetric(
                  label: 'Pickup',
                  value: _formatDateTime(shipment.pickupDateTime),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go(
                    Uri(
                      path: AppRoutes.tracking,
                      queryParameters: {'shipmentId': shipment.id.toString()},
                    ).toString(),
                  ),
                  icon: const Icon(Icons.location_on_rounded),
                  label: const Text('Track live'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                tooltip: 'Shipment details',
                onPressed: () => context.go(
                  Uri(
                    path: AppRoutes.shipmentDetails,
                    queryParameters: {'shipmentId': shipment.id.toString()},
                  ).toString(),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.textInverse.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.surfaceMuted),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.textInverse),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.actions});

  final List<_DashboardAction> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (context, index) {
        return _QuickActionTile(action: actions[index]);
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _DashboardAction action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(action.route),
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Icon(action.icon, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    action.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
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

class _ShipmentCategories extends StatelessWidget {
  const _ShipmentCategories({required this.categories});

  final List<_ShipmentCategorySummary> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = categories[index];
          return InkWell(
            onTap: () => context.go(AppRoutes.shipmentHistory),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            child: Container(
              width: 132,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(category.icon, color: category.color),
                  const Spacer(),
                  Text(
                    category.count.toString(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    category.label,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SupportShortcut extends StatelessWidget {
  const _SupportShortcut();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(AppRoutes.support),
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: AppColors.accentOrange,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need help with a shipment?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Open a support request with shipment ID and lane details.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class _RecentShipmentCard extends StatelessWidget {
  const _RecentShipmentCard({required this.shipment});

  final CustomerShipment shipment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go(
          Uri(
            path: AppRoutes.shipmentDetails,
            queryParameters: {'shipmentId': shipment.id.toString()},
          ).toString(),
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
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
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shipment.shipmentCode,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _vehicleLabel(shipment.vehiclePreference),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: _statusFromApi(shipment.shipmentStatus)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _routeLabel(shipment),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${_weightLabel(shipment)} - ${_titleCase(shipment.shipmentStatus)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: _statusProgress(shipment.shipmentStatus),
                        backgroundColor: AppColors.surfaceMuted,
                        valueColor: AlwaysStoppedAnimation(
                          _statusFromApi(shipment.shipmentStatus) ==
                                  ShipmentStatus.delivered
                              ? AppColors.success
                              : AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _formatDateTime(shipment.pickupDateTime),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeDashboardData {
  const _HomeDashboardData({
    required this.profile,
    required this.shipments,
    required this.unreadCount,
  });

  final CustomerProfile profile;
  final List<CustomerShipment> shipments;
  final int unreadCount;

  CustomerShipment? get activeShipment {
    for (final shipment in shipments) {
      final status = shipment.shipmentStatus;
      if (status != 'completed' &&
          status != 'delivered' &&
          status != 'cancelled' &&
          status != 'rejected') {
        return shipment;
      }
    }
    return shipments.isEmpty ? null : shipments.first;
  }

  List<_ShipmentCategorySummary> get statusCategories {
    int active = 0;
    int booked = 0;
    int delivered = 0;
    int delayed = 0;

    for (final shipment in shipments) {
      switch (shipment.shipmentStatus) {
        case 'pending':
        case 'approved':
        case 'assigned':
        case 'accepted':
          booked++;
        case 'pickup_completed':
        case 'in_transit':
          active++;
        case 'delivered':
        case 'completed':
          delivered++;
        case 'cancelled':
        case 'rejected':
          delayed++;
      }
    }

    return [
      _ShipmentCategorySummary(
        label: 'Active',
        count: active,
        icon: Icons.local_shipping_rounded,
        color: AppColors.primaryBlue,
      ),
      _ShipmentCategorySummary(
        label: 'Booked',
        count: booked,
        icon: Icons.inventory_2_rounded,
        color: AppColors.info,
      ),
      _ShipmentCategorySummary(
        label: 'Delivered',
        count: delivered,
        icon: Icons.done_all_rounded,
        color: AppColors.success,
      ),
      _ShipmentCategorySummary(
        label: 'Closed',
        count: delayed,
        icon: Icons.cancel_outlined,
        color: AppColors.danger,
      ),
    ];
  }
}

class _DashboardAction {
  const _DashboardAction({
    required this.label,
    required this.caption,
    required this.icon,
    required this.route,
  });

  final String label;
  final String caption;
  final IconData icon;
  final String route;
}

class _ShipmentCategorySummary {
  const _ShipmentCategorySummary({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;
}

ShipmentStatus _statusFromApi(String status) {
  return switch (status) {
    'pickup_completed' || 'in_transit' => ShipmentStatus.inTransit,
    'delivered' || 'completed' => ShipmentStatus.delivered,
    'cancelled' || 'rejected' => ShipmentStatus.cancelled,
    _ => ShipmentStatus.booked,
  };
}

double _statusProgress(String status) {
  return switch (status) {
    'pending' => 0.12,
    'approved' => 0.24,
    'assigned' => 0.36,
    'accepted' => 0.46,
    'pickup_completed' => 0.58,
    'in_transit' => 0.74,
    'delivered' => 0.9,
    'completed' => 1,
    'cancelled' || 'rejected' => 1,
    _ => 0.12,
  };
}

String _dashboardSubtitle(_HomeDashboardData data) {
  final count = data.shipments.length;
  if (count == 0) {
    return 'No shipments booked yet. Start with a new load request.';
  }
  final activeCount = data.statusCategories.first.count;
  if (activeCount == 0) {
    return '$count recent shipment${count == 1 ? '' : 's'} in your account.';
  }
  return '$activeCount active shipment${activeCount == 1 ? '' : 's'} moving today.';
}

String _routeLabel(CustomerShipment shipment) {
  return '${_shortAddress(shipment.pickupAddress)} to ${_shortAddress(shipment.deliveryAddress)}';
}

String _shortAddress(String value) {
  final firstPart = value.split(',').first.trim();
  return firstPart.isEmpty ? 'Address pending' : firstPart;
}

String _weightLabel(CustomerShipment shipment) {
  final weight = shipment.packageWeightKg % 1 == 0
      ? shipment.packageWeightKg.toStringAsFixed(0)
      : shipment.packageWeightKg.toStringAsFixed(1);
  return '$weight kg ${shipment.packageType}';
}

String _vehicleLabel(String value) {
  return switch (value) {
    'bike' => 'Bike or mini van',
    'mini_truck' => 'Pickup truck',
    'truck' => '14 ft truck',
    'heavy_truck' => 'Container truck',
    'refrigerated_truck' => 'Reefer vehicle',
    'van' => 'Cushioned van',
    _ => value.replaceAll('_', ' '),
  };
}

String _formatDateTime(String? value) {
  final parsed = DateTime.tryParse(value ?? '');
  if (parsed == null) {
    return 'Schedule pending';
  }

  final hour = parsed.hour > 12 ? parsed.hour - 12 : parsed.hour;
  final displayHour = hour == 0 ? 12 : hour;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final period = parsed.hour >= 12 ? 'PM' : 'AM';
  return '${parsed.day}/${parsed.month}/${parsed.year}, $displayHour:$minute $period';
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _dayPart() {
  final hour = DateTime.now().hour;
  if (hour < 12) {
    return 'morning';
  }
  if (hour < 17) {
    return 'afternoon';
  }
  return 'evening';
}

String _errorMessage(Object? error) {
  if (error is ApiException) {
    return error.message;
  }
  return 'Unable to load customer dashboard data.';
}
