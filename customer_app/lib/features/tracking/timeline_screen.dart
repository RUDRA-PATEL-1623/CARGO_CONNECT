import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../shipment/data/customer_shipment_api.dart';

class ShipmentTimelineScreen extends ConsumerWidget {
  const ShipmentTimelineScreen({super.key, required this.shipmentId});

  final String shipmentId;

  Future<_TimelineViewData> _loadTimeline(WidgetRef ref) async {
    final api = ref.read(customerShipmentApiProvider);
    final resolvedId = await api.resolveShipmentId(shipmentId);
    final timeline = await api.getShipmentTimeline(resolvedId);

    return _TimelineViewData(shipmentId: resolvedId, timeline: timeline);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<_TimelineViewData>(
      future: _loadTimeline(ref),
      builder: (context, snapshot) {
        final data = snapshot.data;

        return CommonAppScaffold(
          title: 'Shipment timeline',
          subtitle: data == null
              ? 'Loading shipment status flow.'
              : 'Current status: ${_titleCase(data.timeline.currentStatus)}',
          bottomNavigationIndex: 2,
          actions: [
            IconButton(
              tooltip: 'Open tracking',
              onPressed: () => context.go(
                Uri(
                  path: AppRoutes.tracking,
                  queryParameters: {'shipmentId': shipmentId},
                ).toString(),
              ),
              icon: const Icon(Icons.map_outlined),
            ),
          ],
          body: Builder(
            builder: (context) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget(message: 'Loading timeline');
              }

              if (snapshot.hasError || data == null) {
                return ErrorStateWidget(
                  title: 'Timeline unavailable',
                  message: _errorMessage(snapshot.error),
                  onRetry: () => context.go(
                    Uri(
                      path: AppRoutes.tracking,
                      queryParameters: {'shipmentId': shipmentId},
                    ).toString(),
                  ),
                );
              }

              if (data.timeline.steps.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.timeline_outlined,
                  title: 'No timeline updates yet',
                  message:
                      'Status updates will appear here as the shipment progresses.',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TimelineHero(data: data),
                  const SizedBox(height: AppSpacing.lg),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          for (var index = 0;
                              index < data.timeline.steps.length;
                              index++)
                            _TimelineStepTile(
                              step: data.timeline.steps[index],
                              isLast:
                                  index == data.timeline.steps.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (data.timeline.events.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _EventLogCard(events: data.timeline.events),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _TimelineHero extends StatelessWidget {
  const _TimelineHero({required this.data});

  final _TimelineViewData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.textInverse.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: const Icon(
              Icons.timeline_rounded,
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
                  'Shipment #${data.shipmentId}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Complete status flow from pending approval to completion.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.surfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStepTile extends StatelessWidget {
  const _TimelineStepTile({required this.step, required this.isLast});

  final ShipmentTimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final state = _stepState(step.state);
    final color = _stateColor(state);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_stateIcon(state), size: 16, color: Colors.white),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: color.withValues(alpha: 0.28),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          step.label.isEmpty
                              ? _titleCase(step.status)
                              : step.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      _StateChip(label: _titleCase(state), color: color),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    _formatDateTime(step.timestamp),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  if (step.description?.isNotEmpty ?? false) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      step.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _EventLogCard extends StatelessWidget {
  const _EventLogCard({required this.events});

  final List<TripLogRecord> events;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Driver updates', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            for (final event in events) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.route_rounded,
                  color: AppColors.primaryBlue,
                ),
                title: Text(event.title.isEmpty ? _titleCase(event.status) : event.title),
                subtitle: Text(
                  [
                    if (event.description?.isNotEmpty ?? false)
                      event.description!,
                    if (event.locationText?.isNotEmpty ?? false)
                      event.locationText!,
                    _formatDateTime(event.eventTime),
                  ].join('\n'),
                ),
              ),
              if (event != events.last) const Divider(height: AppSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineViewData {
  const _TimelineViewData({required this.shipmentId, required this.timeline});

  final int shipmentId;
  final ShipmentTimelineData timeline;
}

String _stepState(String value) {
  final normalized = value.toLowerCase().trim();
  if (normalized == 'completed' ||
      normalized == 'current' ||
      normalized == 'pending') {
    return normalized;
  }
  return 'pending';
}

Color _stateColor(String state) {
  return switch (state) {
    'completed' => AppColors.success,
    'current' => AppColors.accentOrange,
    _ => AppColors.textSecondary,
  };
}

IconData _stateIcon(String state) {
  return switch (state) {
    'completed' => Icons.check_rounded,
    'current' => Icons.local_shipping_rounded,
    _ => Icons.more_horiz_rounded,
  };
}

String _formatDateTime(String? value) {
  final date = DateTime.tryParse(value ?? '');
  if (date == null) {
    return 'Timestamp pending';
  }

  final hour = date.hour > 12 ? date.hour - 12 : date.hour;
  final displayHour = hour == 0 ? 12 : hour;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${date.day}/${date.month}/${date.year}, $displayHour:$minute $period';
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _errorMessage(Object? error) {
  if (error is ApiException) {
    return error.message;
  }
  return 'Unable to load shipment timeline.';
}
