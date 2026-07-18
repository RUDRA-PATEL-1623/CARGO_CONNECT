import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/driver_auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../auth/data/driver_auth_api.dart';
import '../trips/data/driver_trip_api.dart';
import '../trips/data/driver_trip_models.dart';
import 'data/driver_profile_api.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  _DriverProfileMock? _driver;
  var _isLoading = true;
  var _isUpdatingAvailability = false;
  String? _errorMessage;

  DriverProfileApi get _profileApi => ref.read(driverProfileApiProvider);
  DriverTripApi get _tripApi => ref.read(driverTripApiProvider);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileApi.getProfile();
      final trips = await _tripApi.listTrips(limit: 50);
      if (!mounted) {
        return;
      }
      setState(() {
        _driver = _profileFromApi(profile, _selectActiveTrip(trips.trips));
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
      final profile = await _profileApi.updateAvailability(
        value ? 'available' : 'offline',
      );
      final trips = await _tripApi.listTrips(limit: 50);
      if (!mounted) {
        return;
      }
      setState(() {
        _driver = _profileFromApi(profile, _selectActiveTrip(trips.trips));
        _isUpdatingAvailability = false;
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
      await _loadProfile();
    }
  }

  Future<void> _openChangePassword() async {
    await context.push(AppRoutes.changePassword);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text(
            'This will clear the saved driver session on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await ref.read(driverAuthApiProvider).logout();
    await ref.read(driverAuthControllerProvider).handleUnauthorized();

    if (!mounted) {
      return;
    }

    context.go(AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    final driver = _driver;

    return CommonAppScaffold(
      title: 'Driver profile',
      subtitle: 'Driver, vehicle, availability, and compliance summary.',
      bottomNavigationIndex: 3,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const LoadingWidget(message: 'Loading driver profile')
          else if (_errorMessage != null)
            ErrorStateWidget(
              title: 'Could not load profile',
              message: _errorMessage!,
              onRetry: _loadProfile,
            )
          else if (driver != null) ...[
            _ProfileHero(isAvailable: driver.isAvailable, driver: driver),
            const SizedBox(height: AppSpacing.lg),
            _AvailabilityCard(
              isAvailable: driver.isAvailable,
              availabilityLabel: driver.availabilityLabel,
              isUpdating: _isUpdatingAvailability,
              onChanged: _toggleAvailability,
            ),
            const SizedBox(height: AppSpacing.lg),
            _ProfileDetailsGrid(driver: driver),
            const SizedBox(height: AppSpacing.lg),
            _VehicleAssignmentCard(driver: driver),
            const SizedBox(height: AppSpacing.lg),
            _PerformanceSummaryCard(driver: driver),
            const SizedBox(height: AppSpacing.lg),
            _ProfileActionsCard(
              onChangePassword: _openChangePassword,
              onLogout: _logout,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.isAvailable, required this.driver});

  final bool isAvailable;
  final _DriverProfileMock driver;

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
          final avatar = _DriverAvatar(initials: driver.initials);
          final details = _DriverHeroDetails(
            isAvailable: isAvailable,
            driver: driver,
          );

          if (constraints.maxWidth >= 560) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                avatar,
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: details),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(height: AppSpacing.md),
              details,
            ],
          );
        },
      ),
    );
  }
}

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 42,
          backgroundColor: AppColors.textInverse.withValues(alpha: 0.12),
          child: Text(
            initials,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textInverse,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryNavy, width: 3),
            ),
          ),
        ),
      ],
    );
  }
}

class _DriverHeroDetails extends StatelessWidget {
  const _DriverHeroDetails({required this.isAvailable, required this.driver});

  final bool isAvailable;
  final _DriverProfileMock driver;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          driver.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textInverse,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '@${driver.username}',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.surfaceMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          driver.phone,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.surfaceMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            StatusBadge(
              label: driver.availabilityLabel,
              tone: isAvailable
                  ? StatusBadgeTone.available
                  : StatusBadgeTone.neutral,
            ),
            const StatusBadge(
              label: 'Verified driver',
              tone: StatusBadgeTone.completed,
            ),
          ],
        ),
      ],
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({
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
    return Card(
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        value: isAvailable,
        onChanged: isUpdating ? null : onChanged,
        title: Text(
          'Availability: $availabilityLabel',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          isAvailable
              ? 'Online for dispatch and active-trip updates.'
              : 'Offline from new trip assignments.',
        ),
        secondary: Icon(
          isAvailable ? Icons.check_circle_rounded : Icons.do_not_disturb_on,
          color: isAvailable ? AppColors.success : AppColors.neutral,
        ),
      ),
    );
  }
}

class _ProfileDetailsGrid extends StatelessWidget {
  const _ProfileDetailsGrid({required this.driver});

  final _DriverProfileMock driver;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _ProfileInfoTile(
        icon: Icons.person_outline_rounded,
        label: 'Name',
        value: driver.name,
      ),
      _ProfileInfoTile(
        icon: Icons.alternate_email_rounded,
        label: 'Username',
        value: driver.username,
      ),
      _ProfileInfoTile(
        icon: Icons.phone_outlined,
        label: 'Phone',
        value: driver.phone,
      ),
      _ProfileInfoTile(
        icon: Icons.badge_outlined,
        label: 'License number',
        value: driver.licenseNumber,
        trailing: StatusBadge(
          label: driver.licenseExpiryDate.isEmpty
              ? 'Expiry pending'
              : 'Expires ${driver.licenseExpiryDate}',
          tone: StatusBadgeTone.neutral,
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 2 : 1;
        final width =
            (constraints.maxWidth - (AppSpacing.md * (columns - 1))) / columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryBlue),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(value, style: Theme.of(context).textTheme.bodyLarge),
                  if (trailing != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    trailing!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleAssignmentCard extends StatelessWidget {
  const _VehicleAssignmentCard({required this.driver});

  final _DriverProfileMock driver;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle assignment',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        driver.hasActiveTrip
                            ? 'Current backend assignment.'
                            : 'No active backend assignment.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const StatusBadge(
                  label: 'Assigned',
                  tone: StatusBadgeTone.accepted,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoLine(
              icon: Icons.confirmation_number_outlined,
              label: 'Vehicle',
              value: driver.vehicleAssignment,
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoLine(
              icon: Icons.route_outlined,
              label: 'Active trip',
              value: driver.activeTripLabel,
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoLine(
              icon: Icons.inventory_2_outlined,
              label: 'Cargo',
              value: driver.activeCargo,
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceSummaryCard extends StatelessWidget {
  const _PerformanceSummaryCard({required this.driver});

  final _DriverProfileMock driver;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.insights_rounded,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Performance summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusBadge(
                  label: '${driver.activeAssignments} active',
                  tone: driver.activeAssignments > 0
                      ? StatusBadgeTone.accepted
                      : StatusBadgeTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth >= 640
                    ? (constraints.maxWidth - AppSpacing.md * 3) / 4
                    : (constraints.maxWidth - AppSpacing.md) / 2;

                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    _PerformanceMetric(
                      width: itemWidth,
                      icon: Icons.done_all_rounded,
                      label: 'Completed',
                      value: driver.completedTrips,
                    ),
                    _PerformanceMetric(
                      width: itemWidth,
                      icon: Icons.route_rounded,
                      label: 'Distance',
                      value: driver.monthlyDistance,
                    ),
                    _PerformanceMetric(
                      width: itemWidth,
                      icon: Icons.schedule_rounded,
                      label: 'On time',
                      value: driver.onTimeRate,
                    ),
                    _PerformanceMetric(
                      width: itemWidth,
                      icon: Icons.star_border_rounded,
                      label: 'Rating',
                      value: driver.rating,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  const _PerformanceMetric({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryBlue),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _ProfileActionsCard extends StatelessWidget {
  const _ProfileActionsCard({
    required this.onChangePassword,
    required this.onLogout,
  });

  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onChangePassword,
                    icon: const Icon(Icons.lock_reset_rounded),
                    label: const Text('Change password'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: AppColors.textInverse,
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
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

class _DriverProfileMock {
  const _DriverProfileMock({
    required this.initials,
    required this.name,
    required this.username,
    required this.phone,
    required this.licenseNumber,
    required this.vehicleAssignment,
    required this.completedTrips,
    required this.monthlyDistance,
    required this.onTimeRate,
    required this.rating,
    required this.isAvailable,
    required this.availabilityLabel,
    required this.licenseExpiryDate,
    required this.activeTripLabel,
    required this.activeCargo,
    required this.activeAssignments,
  });

  final String initials;
  final String name;
  final String username;
  final String phone;
  final String licenseNumber;
  final String vehicleAssignment;
  final String completedTrips;
  final String monthlyDistance;
  final String onTimeRate;
  final String rating;
  final bool isAvailable;
  final String availabilityLabel;
  final String licenseExpiryDate;
  final String activeTripLabel;
  final String activeCargo;
  final int activeAssignments;

  bool get hasActiveTrip => activeTripLabel != 'No active trip';
}

_DriverProfileMock _profileFromApi(
  DriverProfileData data,
  DriverTripSummary? activeTrip,
) {
  final profile = data.profile;
  final activeTripModel = activeTrip?.toTripCardModel();
  return _DriverProfileMock(
    initials: data.user.initials,
    name: data.user.name,
    username: data.user.username,
    phone: data.user.phone.isEmpty ? 'Phone not added' : data.user.phone,
    licenseNumber: profile.licenseNumber,
    licenseExpiryDate: profile.licenseExpiryDate,
    vehicleAssignment: activeTrip?.vehicleLabel ?? 'No vehicle assigned',
    completedTrips: '${profile.completedTrips}',
    monthlyDistance: activeTripModel?.distance ?? 'Distance pending',
    onTimeRate: profile.activeAssignments > 0 ? 'Active' : 'Ready',
    rating: profile.rating == 0 ? 'New' : profile.rating.toStringAsFixed(1),
    isAvailable: profile.isAvailable,
    availabilityLabel: profile.availabilityLabel,
    activeTripLabel: activeTripModel == null
        ? 'No active trip'
        : '${activeTripModel.id} - ${activeTripModel.distance}',
    activeCargo: activeTripModel?.package ?? 'No active cargo',
    activeAssignments: profile.activeAssignments,
  );
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
