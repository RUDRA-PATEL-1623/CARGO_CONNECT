import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/trip_card.dart';
import '../../core/widgets/trip_timeline_widget.dart';
import '../profile/data/driver_profile_api.dart';
import '../trips/data/driver_trip_api.dart';
import '../trips/data/driver_trip_models.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  _DriverDashboardData? _dashboard;
  var _isLoading = true;
  var _isUpdatingAvailability = false;
  String? _errorMessage;

  DriverTripApi get _tripApi => ref.read(driverTripApiProvider);
  DriverProfileApi get _profileApi => ref.read(driverProfileApiProvider);

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
      final profile = await _profileApi.getProfile();
      final trips = await _tripApi.listTrips(limit: 50);
      final history = await _tripApi.listTripHistory(limit: 50);
      DriverTripTimeline? timeline;
      final activeTrip = _selectActiveTrip(trips.trips);
      if (activeTrip != null) {
        final details = await _tripApi.getTripDetails(activeTrip.id);
        timeline = details.timeline;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _dashboard = _DriverDashboardData(
          profile: profile,
          trips: trips.trips,
          history: history.trips,
          activeTrip: activeTrip,
          activeTimeline: timeline,
        );
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

  Future<void> _toggleAvailability(bool value) async {
    if (_isUpdatingAvailability) {
      return;
    }
    setState(() => _isUpdatingAvailability = true);
    try {
      final updatedProfile = await _profileApi.updateAvailability(
        value ? 'available' : 'offline',
      );
      if (!mounted) {
        return;
      }
      final current = _dashboard;
      setState(() {
        _isUpdatingAvailability = false;
        if (current != null) {
          _dashboard = current.copyWith(profile: updatedProfile);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Availability updated to available.'
                : 'Availability updated to offline.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isUpdatingAvailability = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      await _loadDashboard();
    }
  }

  void _openTrip(DriverTripSummary trip) {
    context.go(_tripWorkflowRoute(trip));
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = _dashboard;

    return CommonAppScaffold(
      title: 'Driver dashboard',
      subtitle: 'CargoConnect Driver',
      bottomNavigationIndex: 0,
      actions: [
        IconButton(
          tooltip: 'Emergency support',
          onPressed: () => context.go(AppRoutes.emergency),
          icon: const Icon(Icons.sos_rounded),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const LoadingWidget(message: 'Loading driver dashboard')
          else if (_errorMessage != null)
            ErrorStateWidget(
              title: 'Could not load dashboard',
              message: _errorMessage!,
              onRetry: _loadDashboard,
            )
          else if (dashboard != null) ...[
            _DutyHeader(
              driverName: dashboard.profile.user.name,
              vehicleLabel: dashboard.activeTrip?.vehicleLabel,
              availabilityLabel: dashboard.profile.profile.availabilityLabel,
              isAvailable: dashboard.profile.profile.isAvailable,
              isUpdating: _isUpdatingAvailability,
              onAvailabilityChanged: _toggleAvailability,
            ),
            const SizedBox(height: AppSpacing.lg),
            _DashboardStatsGrid(
              stats: [
                _DashboardStat(
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'Assigned trips',
                  value: '${dashboard.trips.length}',
                  note: '${dashboard.profile.profile.activeAssignments} active',
                ),
                _DashboardStat(
                  icon: Icons.done_all_rounded,
                  label: 'Completed trips',
                  value: '${dashboard.completedCount}',
                  note: 'From trip history',
                ),
                _DashboardStat(
                  icon: Icons.payments_outlined,
                  label: 'Earnings',
                  value: dashboard.earningsLabel,
                  note: 'From completed trips',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _EmergencyButton(onPressed: () => context.go(AppRoutes.emergency)),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Active trip',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.go(AppRoutes.trips),
                  icon: const Icon(Icons.route_rounded),
                  label: const Text('View trips'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (dashboard.activeTrip == null)
              EmptyStateWidget(
                title: 'No active trip',
                message:
                    'Assigned trips from dispatch will appear here after login.',
                icon: Icons.route_outlined,
              )
            else ...[
              TripCard(
                trip: dashboard.activeTrip!.toTripCardModel(),
                primaryActionLabel: 'Open active trip',
                onTap: () => _openTrip(dashboard.activeTrip!),
                onPrimaryAction: () => _openTrip(dashboard.activeTrip!),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Today\'s route',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              _TodayRouteSummary(trip: dashboard.activeTrip!),
              const SizedBox(height: AppSpacing.md),
              TripTimelineWidget(
                items: dashboard.activeTimeline?.toTimelineMocks() ?? const [],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _DutyHeader extends StatelessWidget {
  const _DutyHeader({
    required this.driverName,
    required this.vehicleLabel,
    required this.availabilityLabel,
    required this.isAvailable,
    required this.isUpdating,
    required this.onAvailabilityChanged,
  });

  final String driverName;
  final String? vehicleLabel;
  final String availabilityLabel;
  final bool isAvailable;
  final bool isUpdating;
  final ValueChanged<bool> onAvailabilityChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availabilityControl = _AvailabilityControl(
            isAvailable: isAvailable,
            availabilityLabel: availabilityLabel,
            isUpdating: isUpdating,
            onChanged: onAvailabilityChanged,
          );

          final driverInfo = Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.textInverse.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: const Icon(
                  Icons.badge_rounded,
                  color: AppColors.roadYellow,
                  size: 34,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textInverse,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      vehicleLabel ?? 'No active vehicle assignment',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.surfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (constraints.maxWidth >= 620) {
            return Row(
              children: [
                Expanded(child: driverInfo),
                const SizedBox(width: AppSpacing.lg),
                availabilityControl,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              driverInfo,
              const SizedBox(height: AppSpacing.lg),
              availabilityControl,
            ],
          );
        },
      ),
    );
  }
}

class _AvailabilityControl extends StatelessWidget {
  const _AvailabilityControl({
    required this.isAvailable,
    required this.availabilityLabel,
    required this.isUpdating,
    required this.onChanged,
  });

  final bool isAvailable;
  final String availabilityLabel;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.textInverse.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: AppColors.textInverse.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusBadge(
            label: availabilityLabel,
            tone: isAvailable
                ? StatusBadgeTone.available
                : StatusBadgeTone.neutral,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Duty status',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.textInverse),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch.adaptive(
            value: isAvailable,
            onChanged: isUpdating ? null : onChanged,
          ),
        ],
      ),
    );
  }
}

class _DashboardStatsGrid extends StatelessWidget {
  const _DashboardStatsGrid({required this.stats});

  final List<_DashboardStat> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720
            ? 3
            : constraints.maxWidth >= 480
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - (AppSpacing.md * (columns - 1))) / columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final stat in stats)
              SizedBox(
                width: width,
                child: _DashboardStatCard(stat: stat),
              ),
          ],
        );
      },
    );
  }
}

class _DashboardStat {
  const _DashboardStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
  });

  final IconData icon;
  final String label;
  final String value;
  final String note;
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({required this.stat});

  final _DashboardStat stat;

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
              child: Icon(stat.icon, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.label,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    stat.value,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    stat.note,
                    style: Theme.of(context).textTheme.bodyMedium,
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

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger,
          foregroundColor: AppColors.textInverse,
        ),
        icon: const Icon(Icons.sos_rounded),
        label: const Text('Emergency support'),
      ),
    );
  }
}

class _TodayRouteSummary extends StatelessWidget {
  const _TodayRouteSummary({required this.trip});

  final DriverTripSummary trip;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 560;
            final routeDetails = Column(
              children: [
                _RouteStop(
                  icon: Icons.my_location_rounded,
                  label: 'Start',
                  value: trip.pickupAddress,
                ),
                const SizedBox(height: AppSpacing.sm),
                _RouteStop(
                  icon: Icons.flag_rounded,
                  label: 'Finish',
                  value: trip.deliveryAddress,
                ),
              ],
            );

            final metrics = Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _RouteMetric(label: 'Distance', value: trip.distanceLabel),
                _RouteMetric(label: 'ETA', value: trip.durationLabel),
                const _RouteMetric(label: 'Stops', value: '2'),
              ],
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: routeDetails),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(flex: 2, child: metrics),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                routeDetails,
                const SizedBox(height: AppSpacing.md),
                metrics,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DriverDashboardData {
  const _DriverDashboardData({
    required this.profile,
    required this.trips,
    required this.history,
    required this.activeTrip,
    required this.activeTimeline,
  });

  final DriverProfileData profile;
  final List<DriverTripSummary> trips;
  final List<DriverTripSummary> history;
  final DriverTripSummary? activeTrip;
  final DriverTripTimeline? activeTimeline;

  int get completedCount {
    final profileCount = profile.profile.completedTrips;
    return profileCount > 0 ? profileCount : history.length;
  }

  String get earningsLabel {
    final total = history.fold<double>(
      0,
      (sum, trip) => sum + (trip.routeSummary.estimatedPrice ?? 0),
    );
    return _formatInr(total);
  }

  _DriverDashboardData copyWith({DriverProfileData? profile}) {
    return _DriverDashboardData(
      profile: profile ?? this.profile,
      trips: trips,
      history: history,
      activeTrip: activeTrip,
      activeTimeline: activeTimeline,
    );
  }
}

DriverTripSummary? _selectActiveTrip(List<DriverTripSummary> trips) {
  final priority = [
    'in_transit',
    'pickup_completed',
    'started',
    'accepted',
    'assigned',
  ];
  for (final status in priority) {
    for (final trip in trips) {
      if (trip.assignmentStatus == status) {
        return trip;
      }
    }
  }
  return trips.isEmpty ? null : trips.first;
}

String _tripWorkflowRoute(DriverTripSummary trip) {
  final query = {
    'assignmentId': trip.id.toString(),
    'shipmentId': trip.displayId,
  };
  final path = switch (trip.assignmentStatus) {
    'accepted' => AppRoutes.startTrip,
    'started' => AppRoutes.proofUpload,
    'pickup_completed' || 'in_transit' => AppRoutes.inTransitUpdate,
    'delivered' => AppRoutes.completeTrip,
    _ => AppRoutes.tripDetails,
  };
  return Uri(path: path, queryParameters: query).toString();
}

String _formatInr(num value) {
  final raw = value.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < raw.length; index++) {
    final fromRight = raw.length - index;
    buffer.write(raw[index]);
    if (fromRight > 1 && fromRight % 3 == 1) {
      buffer.write(',');
    }
  }
  return 'INR $buffer';
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
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
        Icon(icon, color: AppColors.primaryBlue),
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

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
