import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/mock_admin_data.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/widgets/admin_data_table.dart';
import '../../core/widgets/admin_stat_card.dart';
import '../../core/widgets/admin_state_widgets.dart';
import '../../core/widgets/admin_status_badge.dart';
import 'widgets/driver_form_dialog.dart';

DateTime _today() => DateUtils.dateOnly(DateTime.now());

int _licenseDaysRemaining(DateTime expiry) {
  return DateUtils.dateOnly(expiry).difference(_today()).inDays;
}

bool _isLicenseExpired(DateTime expiry) => _licenseDaysRemaining(expiry) < 0;

bool _isLicenseExpiringSoon(DateTime expiry) {
  final remainingDays = _licenseDaysRemaining(expiry);
  return remainingDays >= 0 && remainingDays <= 30;
}

AdminStatusTone _statusTone(String status) {
  switch (status) {
    case 'Active':
      return AdminStatusTone.success;
    case 'Suspended':
      return AdminStatusTone.danger;
    case 'Inactive':
      return AdminStatusTone.neutral;
    default:
      return AdminStatusTone.neutral;
  }
}

AdminStatusTone _availabilityTone(String availability) {
  switch (availability) {
    case 'Available':
      return AdminStatusTone.success;
    case 'On Trip':
      return AdminStatusTone.primary;
    case 'On Leave':
      return AdminStatusTone.warning;
    case 'Offline':
      return AdminStatusTone.neutral;
    default:
      return AdminStatusTone.neutral;
  }
}

AdminStatusTone _licenseTone(AdminDriverManagementMock driver) {
  if (_isLicenseExpired(driver.licenseExpiry)) {
    return AdminStatusTone.danger;
  }
  if (_isLicenseExpiringSoon(driver.licenseExpiry)) {
    return AdminStatusTone.warning;
  }
  return AdminStatusTone.success;
}

String _licenseStateLabel(AdminDriverManagementMock driver) {
  final remainingDays = _licenseDaysRemaining(driver.licenseExpiry);
  if (remainingDays < 0) {
    return 'Expired ${remainingDays.abs()}d ago';
  }
  if (remainingDays <= 30) {
    return 'Expires in ${remainingDays}d';
  }
  return 'Valid';
}

String _formatDate(BuildContext context, DateTime date) {
  return MaterialLocalizations.of(context).formatMediumDate(date);
}

String _dateOnly(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _apiDriverStatus(String status) {
  return switch (status) {
    'Active' => 'active',
    'Suspended' => 'suspended',
    _ => 'inactive',
  };
}

String _apiDriverAvailability(String availability) {
  return switch (availability) {
    'Available' => 'available',
    'On Trip' => 'busy',
    'On Leave' => 'on_leave',
    _ => 'offline',
  };
}

Map<String, dynamic> _driverPayload(
  DriverFormResult result, {
  bool includePassword = false,
}) {
  return {
    'name': result.name,
    'username': result.username,
    if (includePassword) 'password': result.generatedPassword,
    'email': result.email,
    'phone': result.phone,
    'licenseNumber': result.licenseNumber,
    'licenseExpiryDate': _dateOnly(result.licenseExpiry),
    'addressLine1': result.address,
    'availabilityStatus': _apiDriverAvailability(result.availabilityStatus),
    'driverStatus': _apiDriverStatus(result.activeStatus),
  };
}

class DriversScreen extends ConsumerStatefulWidget {
  const DriversScreen({super.key});

  @override
  ConsumerState<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends ConsumerState<DriversScreen> {
  static const _statusFilters = [
    'All statuses',
    'Active',
    'Inactive',
    'Suspended',
  ];
  static const _availabilityFilters = [
    'All availability',
    'Available',
    'On Trip',
    'On Leave',
    'Offline',
  ];

  final _searchController = TextEditingController();
  final Set<String> _busyDriverIds = <String>{};

  List<AdminDriverManagementMock> _drivers = <AdminDriverManagementMock>[];
  String _query = '';
  String _statusFilter = _statusFilters.first;
  String _availabilityFilter = _availabilityFilters.first;
  bool _isLoading = true;
  bool _hasLoadError = false;

  List<AdminDriverManagementMock> get _summaryDrivers => _drivers;

  List<AdminDriverManagementMock> get _filteredDrivers {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = _drivers.where((driver) {
      final matchesSearch =
          normalizedQuery.isEmpty ||
          driver.id.toLowerCase().contains(normalizedQuery) ||
          driver.name.toLowerCase().contains(normalizedQuery) ||
          driver.username.toLowerCase().contains(normalizedQuery) ||
          driver.email.toLowerCase().contains(normalizedQuery) ||
          driver.phone.toLowerCase().contains(normalizedQuery) ||
          driver.address.toLowerCase().contains(normalizedQuery) ||
          driver.zone.toLowerCase().contains(normalizedQuery) ||
          driver.assignedVehicle.toLowerCase().contains(normalizedQuery) ||
          driver.licenseNumber.toLowerCase().contains(normalizedQuery) ||
          driver.licenseClass.toLowerCase().contains(normalizedQuery);
      final matchesStatus =
          _statusFilter == _statusFilters.first ||
          driver.status == _statusFilter;
      final matchesAvailability =
          _availabilityFilter == _availabilityFilters.first ||
          driver.availability == _availabilityFilter;
      return matchesSearch && matchesStatus && matchesAvailability;
    }).toList();

    filtered.sort((left, right) {
      final statusPriority = _statusRank(
        left.status,
      ).compareTo(_statusRank(right.status));
      if (statusPriority != 0) {
        return statusPriority;
      }
      return left.name.compareTo(right.name);
    });

    return filtered;
  }

  int get _activeCount =>
      _summaryDrivers.where((driver) => driver.status == 'Active').length;

  int get _availableCount => _summaryDrivers
      .where(
        (driver) =>
            driver.status == 'Active' && driver.availability == 'Available',
      )
      .length;

  int get _onTripCount => _summaryDrivers
      .where(
        (driver) =>
            driver.status == 'Active' && driver.availability == 'On Trip',
      )
      .length;

  int get _expiringLicenseCount => _summaryDrivers
      .where((driver) => _isLicenseExpiringSoon(driver.licenseExpiry))
      .length;

  double get _averageRating {
    final ratedDrivers = _summaryDrivers
        .where((driver) => driver.completedTrips > 0)
        .toList();

    if (ratedDrivers.isEmpty) {
      return 0;
    }

    final total = ratedDrivers.fold<double>(
      0,
      (sum, driver) => sum + driver.rating,
    );
    return total / ratedDrivers.length;
  }

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });

    try {
      final drivers = await ref.read(adminApiServiceProvider).fetchDrivers();
      if (!mounted) {
        return;
      }
      setState(() {
        _drivers = drivers;
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
      _showMessage(error.message, isError: true);
    }
  }

  int _statusRank(String status) {
    switch (status) {
      case 'Active':
        return 0;
      case 'Inactive':
        return 1;
      case 'Suspended':
        return 2;
      default:
        return 3;
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _query = '';
      _statusFilter = _statusFilters.first;
      _availabilityFilter = _availabilityFilters.first;
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.danger : null,
        content: Text(message),
      ),
    );
  }

  Future<void> _showCreateDriverDialog() async {
    final result = await showDriverFormDialog(
      context: context,
      mode: DriverFormMode.create,
    );
    if (!mounted || result == null) {
      return;
    }

    try {
      final newDriver = await ref
          .read(adminApiServiceProvider)
          .createDriver(_driverPayload(result, includePassword: true));

      setState(() {
        _drivers = [newDriver, ..._drivers];
        _searchController.clear();
        _query = '';
        _statusFilter = _statusFilters.first;
        _availabilityFilter = _availabilityFilters.first;
      });

      _showMessage('${newDriver.name} added to the driver roster.');
    } on ApiException catch (error) {
      _showMessage(error.message, isError: true);
    }
  }

  Future<void> _showEditDriverDialog(AdminDriverManagementMock driver) async {
    final result = await showDriverFormDialog(
      context: context,
      mode: DriverFormMode.edit,
      initialDriver: driver,
    );
    if (!mounted || result == null) {
      return;
    }

    try {
      final updatedDriver = await ref
          .read(adminApiServiceProvider)
          .updateDriver(driver, _driverPayload(result));

      setState(() {
        _drivers = _drivers.map((item) {
          if (item.id == driver.id) {
            return updatedDriver;
          }
          return item;
        }).toList();
      });

      _showMessage('${updatedDriver.name} updated successfully.');
    } on ApiException catch (error) {
      _showMessage(error.message, isError: true);
    }
  }

  Future<void> _toggleDriverStatus(AdminDriverManagementMock driver) async {
    final isActive = driver.status == 'Active';

    if (isActive && driver.availability == 'On Trip') {
      _showMessage(
        'Finish or reassign the current trip before deactivating ${driver.name}.',
        isError: true,
      );
      return;
    }

    if (!isActive && _isLicenseExpired(driver.licenseExpiry)) {
      _showMessage(
        'Renew ${driver.name}\'s license before activating the profile.',
        isError: true,
      );
      return;
    }

    setState(() => _busyDriverIds.add(driver.id));
    try {
      final service = ref.read(adminApiServiceProvider);
      final updatedDriver = isActive
          ? await service.deactivateDriver(driver)
          : await service.activateDriver(driver);

      if (!mounted) {
        return;
      }

      setState(() {
        _busyDriverIds.remove(driver.id);
        _drivers = _drivers.map((item) {
          if (item.id == driver.id) {
            return updatedDriver;
          }
          return item;
        }).toList();
      });

      _showMessage(
        '${updatedDriver.name} ${isActive ? 'deactivated' : 'activated'} successfully.',
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyDriverIds.remove(driver.id));
      _showMessage(error.message, isError: true);
    }
  }

  Future<void> _showDriverDetails(AdminDriverManagementMock driver) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _DriverDetailsDialog(driver: driver),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredDrivers = _filteredDrivers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DriversHeader(
          activeCount: _activeCount,
          availableCount: _availableCount,
          onTripCount: _onTripCount,
          expiringLicenseCount: _expiringLicenseCount,
          onCreatePressed: _showCreateDriverDialog,
        ),
        const SizedBox(height: AppSpacing.lg),
        _DriverSummaryGrid(
          totalCount: _summaryDrivers.length,
          availableCount: _availableCount,
          expiringLicenseCount: _expiringLicenseCount,
          averageRating: _averageRating,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_isLoading)
          const AdminLoadingState(message: 'Loading driver roster...')
        else if (_hasLoadError)
          AdminErrorState(
            title: 'Driver roster unavailable',
            message:
                'Driver records could not be loaded from the backend. Retry to restore the list screen.',
            onRetry: _loadDrivers,
          )
        else ...[
          _DriverSearchFilterBar(
            controller: _searchController,
            hintText:
                'Driver ID, name, username, email, phone, address, license',
            statusFilters: _statusFilters,
            selectedStatusFilter: _statusFilter,
            availabilityFilters: _availabilityFilters,
            selectedAvailabilityFilter: _availabilityFilter,
            onSearchChanged: (value) => setState(() => _query = value),
            onStatusFilterChanged: (value) =>
                setState(() => _statusFilter = value),
            onAvailabilityFilterChanged: (value) =>
                setState(() => _availabilityFilter = value),
            onClear: _clearFilters,
          ),
          const SizedBox(height: AppSpacing.md),
          _DriverListMetaCard(
            visibleCount: filteredDrivers.length,
            totalCount: _drivers.length,
            selectedStatusFilter: _statusFilter,
            selectedAvailabilityFilter: _availabilityFilter,
          ),
          const SizedBox(height: AppSpacing.md),
          if (filteredDrivers.isEmpty)
            const AdminEmptyState(
              title: 'No drivers found',
              message:
                  'Try clearing the current search or status filter to view the full roster.',
              icon: Icons.manage_accounts_outlined,
            )
          else
            AdminDataTable(
              dataRowMinHeight: 96,
              dataRowMaxHeight: 128,
              columns: const [
                AdminTableColumn('Driver'),
                AdminTableColumn('Status'),
                AdminTableColumn('Availability'),
                AdminTableColumn('Zone / Vehicle'),
                AdminTableColumn('License'),
                AdminTableColumn('Performance'),
                AdminTableColumn('Last update'),
                AdminTableColumn('Actions'),
              ],
              rows: [
                for (final driver in filteredDrivers)
                  [
                    _DriverIdentityCell(driver: driver),
                    AdminStatusBadge(
                      label: driver.status,
                      tone: _statusTone(driver.status),
                    ),
                    AdminStatusBadge(
                      label: driver.availability,
                      tone: _availabilityTone(driver.availability),
                    ),
                    _DriverFleetCell(driver: driver),
                    _DriverLicenseCell(driver: driver),
                    _DriverPerformanceCell(driver: driver),
                    SizedBox(
                      width: 150,
                      child: Text(
                        driver.lastCheckIn,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    _DriverActions(
                      isBusy: _busyDriverIds.contains(driver.id),
                      isActive: driver.status == 'Active',
                      onView: () => _showDriverDetails(driver),
                      onEdit: () => _showEditDriverDialog(driver),
                      onToggleStatus: () => _toggleDriverStatus(driver),
                    ),
                  ],
              ],
            ),
        ],
      ],
    );
  }
}

class _DriversHeader extends StatelessWidget {
  const _DriversHeader({
    required this.activeCount,
    required this.availableCount,
    required this.onTripCount,
    required this.expiringLicenseCount,
    required this.onCreatePressed,
  });

  final int activeCount;
  final int availableCount;
  final int onTripCount;
  final int expiringLicenseCount;
  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final summaryBadges = Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AdminStatusBadge(
                  label: '$activeCount active',
                  tone: AdminStatusTone.success,
                ),
                AdminStatusBadge(
                  label: '$availableCount available',
                  tone: AdminStatusTone.primary,
                ),
                AdminStatusBadge(
                  label: '$onTripCount on trip',
                  tone: AdminStatusTone.warning,
                ),
                AdminStatusBadge(
                  label: '$expiringLicenseCount licenses due',
                  tone: expiringLicenseCount > 0
                      ? AdminStatusTone.warning
                      : AdminStatusTone.success,
                ),
              ],
            );

            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driver management',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Monitor roster status, license compliance, availability, and operational performance from backend data.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            );

            final actionButton = ElevatedButton.icon(
              onPressed: onCreatePressed,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Create driver'),
            );

            if (constraints.maxWidth >= 980) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: AppSpacing.lg),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        actionButton,
                        const SizedBox(height: AppSpacing.md),
                        summaryBadges,
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.md),
                actionButton,
                const SizedBox(height: AppSpacing.md),
                summaryBadges,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DriverSummaryGrid extends StatelessWidget {
  const _DriverSummaryGrid({
    required this.totalCount,
    required this.availableCount,
    required this.expiringLicenseCount,
    required this.averageRating,
  });

  final int totalCount;
  final int availableCount;
  final int expiringLicenseCount;
  final double averageRating;

  @override
  Widget build(BuildContext context) {
    final cards = [
      AdminStatCard(
        label: 'Total drivers',
        value: '$totalCount',
        delta: 'Rostered for current operations',
        icon: Icons.badge_outlined,
        isPositive: true,
        accentColor: AppColors.primaryBlue,
      ),
      AdminStatCard(
        label: 'Available now',
        value: '$availableCount',
        delta: 'Ready for assignment',
        icon: Icons.wifi_tethering_outlined,
        isPositive: true,
        accentColor: AppColors.success,
      ),
      AdminStatCard(
        label: 'Licenses due soon',
        value: '$expiringLicenseCount',
        delta: expiringLicenseCount == 0
            ? 'No expiries inside 30 days'
            : 'Renew before dispatch impact',
        icon: Icons.fact_check_outlined,
        isPositive: expiringLicenseCount == 0,
        accentColor: AppColors.warning,
      ),
      AdminStatCard(
        label: 'Average rating',
        value: averageRating == 0 ? '--' : averageRating.toStringAsFixed(1),
        delta: 'Customer delivery feedback',
        icon: Icons.star_outline_rounded,
        isPositive: averageRating >= 4.5 || averageRating == 0,
        accentColor: AppColors.accentOrange,
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

class _DriverListMetaCard extends StatelessWidget {
  const _DriverListMetaCard({
    required this.visibleCount,
    required this.totalCount,
    required this.selectedStatusFilter,
    required this.selectedAvailabilityFilter,
  });

  final int visibleCount;
  final int totalCount;
  final String selectedStatusFilter;
  final String selectedAvailabilityFilter;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final summary = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: const Icon(
                    Icons.groups_2_outlined,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Flexible(
                  child: Text(
                    '$visibleCount visible of $totalCount drivers',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            );

            final filterBadges = Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AdminStatusBadge(
                  label: selectedStatusFilter,
                  tone: selectedStatusFilter == 'All statuses'
                      ? AdminStatusTone.neutral
                      : _statusTone(selectedStatusFilter),
                ),
                AdminStatusBadge(
                  label: selectedAvailabilityFilter,
                  tone: selectedAvailabilityFilter == 'All availability'
                      ? AdminStatusTone.neutral
                      : _availabilityTone(selectedAvailabilityFilter),
                ),
              ],
            );

            if (constraints.maxWidth >= 760) {
              return Row(
                children: [
                  Expanded(child: summary),
                  const SizedBox(width: AppSpacing.md),
                  filterBadges,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                summary,
                const SizedBox(height: AppSpacing.md),
                filterBadges,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DriverSearchFilterBar extends StatelessWidget {
  const _DriverSearchFilterBar({
    required this.controller,
    required this.hintText,
    required this.statusFilters,
    required this.selectedStatusFilter,
    required this.availabilityFilters,
    required this.selectedAvailabilityFilter,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.onAvailabilityFilterChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final List<String> statusFilters;
  final String selectedStatusFilter;
  final List<String> availabilityFilters;
  final String selectedAvailabilityFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusFilterChanged;
  final ValueChanged<String> onAvailabilityFilterChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasSearch = controller.text.trim().isNotEmpty;
    final hasFilters =
        selectedStatusFilter != 'All statuses' ||
        selectedAvailabilityFilter != 'All availability';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final search = TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: hintText,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: hasSearch
                    ? IconButton(
                        tooltip: 'Clear search',
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
            );

            final statusFilter = DropdownButtonFormField<String>(
              key: ValueKey('driver-status-$selectedStatusFilter'),
              initialValue: selectedStatusFilter,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Status filter',
                prefixIcon: Icon(Icons.verified_user_outlined),
              ),
              items: [
                for (final option in statusFilters)
                  DropdownMenuItem(value: option, child: Text(option)),
              ],
              onChanged: (value) {
                if (value != null) {
                  onStatusFilterChanged(value);
                }
              },
            );

            final availabilityFilter = DropdownButtonFormField<String>(
              key: ValueKey('driver-availability-$selectedAvailabilityFilter'),
              initialValue: selectedAvailabilityFilter,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Availability',
                prefixIcon: Icon(Icons.wifi_tethering_outlined),
              ),
              items: [
                for (final option in availabilityFilters)
                  DropdownMenuItem(value: option, child: Text(option)),
              ],
              onChanged: (value) {
                if (value != null) {
                  onAvailabilityFilterChanged(value);
                }
              },
            );

            final resetButton = OutlinedButton.icon(
              onPressed: hasSearch || hasFilters ? onClear : null,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reset'),
            );

            if (constraints.maxWidth >= 980) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: search),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: statusFilter),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: availabilityFilter),
                  const SizedBox(width: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: resetButton,
                  ),
                ],
              );
            }

            return Column(
              children: [
                search,
                const SizedBox(height: AppSpacing.md),
                statusFilter,
                const SizedBox(height: AppSpacing.md),
                availabilityFilter,
                const SizedBox(height: AppSpacing.md),
                Align(alignment: Alignment.centerLeft, child: resetButton),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DriverIdentityCell extends StatelessWidget {
  const _DriverIdentityCell({required this.driver});

  final AdminDriverManagementMock driver;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            driver.name,
            style: Theme.of(context).textTheme.labelLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${driver.id} | @${driver.username}',
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            driver.email,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(driver.phone, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _DriverFleetCell extends StatelessWidget {
  const _DriverFleetCell({required this.driver});

  final AdminDriverManagementMock driver;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            driver.zone,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            driver.assignedVehicle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DriverLicenseCell extends StatelessWidget {
  const _DriverLicenseCell({required this.driver});

  final AdminDriverManagementMock driver;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${driver.licenseClass} | ${driver.licenseNumber}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Expiry ${_formatDate(context, driver.licenseExpiry)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          AdminStatusBadge(
            label: _licenseStateLabel(driver),
            tone: _licenseTone(driver),
          ),
        ],
      ),
    );
  }
}

class _DriverPerformanceCell extends StatelessWidget {
  const _DriverPerformanceCell({required this.driver});

  final AdminDriverManagementMock driver;

  @override
  Widget build(BuildContext context) {
    final ratingLabel = driver.completedTrips == 0
        ? 'New'
        : driver.rating.toStringAsFixed(1);

    return SizedBox(
      width: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rating $ratingLabel | ${driver.completedTrips} trips',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'On-time ${driver.onTimePercentage}% | Safety ${driver.safetyScore}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: driver.completedTrips == 0
                ? 0.4
                : driver.onTimePercentage / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: AppColors.surfaceMuted,
            color: driver.onTimePercentage >= 95
                ? AppColors.success
                : driver.onTimePercentage >= 90
                ? AppColors.primaryBlue
                : AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _DriverActions extends StatelessWidget {
  const _DriverActions({
    required this.isBusy,
    required this.isActive,
    required this.onView,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final bool isBusy;
  final bool isActive;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          TextButton.icon(
            onPressed: isBusy ? null : onView,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('View'),
          ),
          TextButton.icon(
            onPressed: isBusy ? null : onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
          ),
          TextButton.icon(
            onPressed: isBusy ? null : onToggleStatus,
            icon: isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isActive
                        ? Icons.person_off_outlined
                        : Icons.verified_user_outlined,
                    size: 18,
                  ),
            label: Text(isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }
}

class _DriverDetailsDialog extends StatelessWidget {
  const _DriverDetailsDialog({required this.driver});

  final AdminDriverManagementMock driver;

  @override
  Widget build(BuildContext context) {
    final ratingLabel = driver.completedTrips == 0
        ? 'New driver'
        : driver.rating.toStringAsFixed(1);

    return AlertDialog(
      title: Text('${driver.name} details'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AdminStatusBadge(
                    label: driver.status,
                    tone: _statusTone(driver.status),
                  ),
                  AdminStatusBadge(
                    label: driver.availability,
                    tone: _availabilityTone(driver.availability),
                  ),
                  AdminStatusBadge(
                    label: _licenseStateLabel(driver),
                    tone: _licenseTone(driver),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _DriverDetailSection(
                title: 'Account and contact',
                children: [
                  _DriverDetailTile(label: 'Driver ID', value: driver.id),
                  _DriverDetailTile(label: 'Username', value: driver.username),
                  _DriverDetailTile(label: 'Email', value: driver.email),
                  _DriverDetailTile(label: 'Phone', value: driver.phone),
                  _DriverDetailTile(label: 'Address', value: driver.address),
                  _DriverDetailTile(
                    label: 'Generated password',
                    value: driver.temporaryPassword,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DriverDetailSection(
                title: 'Fleet assignment',
                children: [
                  _DriverDetailTile(label: 'Zone', value: driver.zone),
                  _DriverDetailTile(
                    label: 'Assigned vehicle',
                    value: driver.assignedVehicle,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DriverDetailSection(
                title: 'License and compliance',
                children: [
                  _DriverDetailTile(
                    label: 'License number',
                    value: driver.licenseNumber,
                  ),
                  _DriverDetailTile(
                    label: 'License class',
                    value: driver.licenseClass,
                  ),
                  _DriverDetailTile(
                    label: 'License expiry',
                    value: _formatDate(context, driver.licenseExpiry),
                  ),
                  _DriverDetailTile(
                    label: 'Compliance state',
                    value: _licenseStateLabel(driver),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DriverDetailSection(
                title: 'Performance summary',
                children: [
                  _DriverDetailTile(label: 'Rating', value: ratingLabel),
                  _DriverDetailTile(
                    label: 'Completed trips',
                    value: '${driver.completedTrips}',
                  ),
                  _DriverDetailTile(
                    label: 'On-time delivery',
                    value: '${driver.onTimePercentage}%',
                  ),
                  _DriverDetailTile(
                    label: 'Safety score',
                    value: '${driver.safetyScore}/100',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DriverDetailSection(
                title: 'Latest roster update',
                children: [
                  _DriverDetailTile(
                    label: 'Last update',
                    value: driver.lastCheckIn,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _DriverDetailSection extends StatelessWidget {
  const _DriverDetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: children,
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverDetailTile extends StatelessWidget {
  const _DriverDetailTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
