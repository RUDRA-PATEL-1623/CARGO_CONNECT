import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/mock_admin_data.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/widgets/admin_data_table.dart';
import '../../core/widgets/admin_search_filter_bar.dart';
import '../../core/widgets/admin_stat_card.dart';
import '../../core/widgets/admin_state_widgets.dart';
import '../../core/widgets/admin_status_badge.dart';
import 'widgets/vehicle_form_dialog.dart';

DateTime _today() => DateUtils.dateOnly(DateTime.now());

int _serviceDaysRemaining(DateTime serviceDue) {
  return DateUtils.dateOnly(serviceDue).difference(_today()).inDays;
}

bool _isServiceOverdue(DateTime serviceDue) =>
    _serviceDaysRemaining(serviceDue) < 0;

bool _isServiceDueSoon(DateTime serviceDue) {
  final daysRemaining = _serviceDaysRemaining(serviceDue);
  return daysRemaining >= 0 && daysRemaining <= 14;
}

AdminStatusTone _serviceTone(AdminVehicleManagementMock vehicle) {
  if (_isServiceOverdue(vehicle.serviceDue)) {
    return AdminStatusTone.danger;
  }
  if (_isServiceDueSoon(vehicle.serviceDue)) {
    return AdminStatusTone.warning;
  }
  return AdminStatusTone.success;
}

String _serviceLabel(AdminVehicleManagementMock vehicle) {
  final daysRemaining = _serviceDaysRemaining(vehicle.serviceDue);
  if (daysRemaining < 0) {
    return 'Overdue ${daysRemaining.abs()}d';
  }
  if (daysRemaining == 0) {
    return 'Due today';
  }
  if (daysRemaining <= 14) {
    return 'Due in ${daysRemaining}d';
  }
  return 'Healthy';
}

String _formatDate(BuildContext context, DateTime date) {
  return MaterialLocalizations.of(context).formatMediumDate(date);
}

String _dateOnly(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _apiVehicleType(String type) {
  return switch (type) {
    'Pickup Van' => 'van',
    'Mini Truck' => 'mini_truck',
    '14 ft Truck' => 'truck',
    'Open Truck' => 'truck',
    'Container Truck' => 'heavy_truck',
    'Reefer Van' => 'refrigerated_truck',
    'Trailer' => 'heavy_truck',
    _ => 'van',
  };
}

String _apiFuelType(String fuelType) => fuelType.toLowerCase();

String _apiVehicleAvailability(String availability) {
  return switch (availability) {
    'Available' => 'available',
    'Busy' => 'assigned',
    'Maintenance' => 'maintenance',
    _ => 'inactive',
  };
}

num _capacityKg(String capacity) {
  final numeric = RegExp(r'\d+(\.\d+)?').firstMatch(capacity)?.group(0);
  final value = num.tryParse(numeric ?? '') ?? 0;
  if (capacity.toLowerCase().contains('ton')) {
    return value * 1000;
  }
  return value;
}

Map<String, dynamic> _vehiclePayload(VehicleFormResult result) {
  return {
    'registrationNumber': result.registration,
    'vehicleType': _apiVehicleType(result.type),
    'capacityKg': _capacityKg(result.capacity),
    'model': result.model,
    'fuelType': _apiFuelType(result.fuelType),
    'insuranceExpiryDate': _dateOnly(result.insuranceExpiry),
    'serviceDueDate': _dateOnly(result.serviceDue),
    'availabilityStatus': _apiVehicleAvailability(result.availability),
    'notes': result.notes,
  };
}

class VehiclesScreen extends ConsumerStatefulWidget {
  const VehiclesScreen({super.key});

  @override
  ConsumerState<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends ConsumerState<VehiclesScreen> {
  static const _availabilityFilters = [
    'All',
    'Available',
    'Busy',
    'Maintenance',
    'On Leave',
    'Out of Service',
  ];

  final _searchController = TextEditingController();
  final Set<String> _busyVehicleIds = <String>{};

  List<AdminVehicleManagementMock> _vehicles = <AdminVehicleManagementMock>[];
  String _query = '';
  String _availabilityFilter = _availabilityFilters.first;
  bool _isLoading = true;
  bool _hasLoadError = false;

  List<AdminVehicleManagementMock> get _summaryVehicles => _vehicles;

  List<AdminVehicleManagementMock> get _filteredVehicles {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = _vehicles.where((vehicle) {
      final matchesSearch =
          normalizedQuery.isEmpty ||
          vehicle.id.toLowerCase().contains(normalizedQuery) ||
          vehicle.vehicleNumber.toLowerCase().contains(normalizedQuery) ||
          vehicle.type.toLowerCase().contains(normalizedQuery) ||
          vehicle.capacity.toLowerCase().contains(normalizedQuery) ||
          vehicle.model.toLowerCase().contains(normalizedQuery) ||
          vehicle.fuelType.toLowerCase().contains(normalizedQuery) ||
          vehicle.registration.toLowerCase().contains(normalizedQuery) ||
          vehicle.notes.toLowerCase().contains(normalizedQuery) ||
          vehicle.assignedDriver.toLowerCase().contains(normalizedQuery) ||
          (vehicle.assignedTrip ?? '').toLowerCase().contains(normalizedQuery);
      final matchesAvailability =
          _availabilityFilter == _availabilityFilters.first ||
          vehicle.availability == _availabilityFilter;
      return matchesSearch && matchesAvailability;
    }).toList();

    filtered.sort((left, right) {
      final servicePriority = _serviceDaysRemaining(
        left.serviceDue,
      ).compareTo(_serviceDaysRemaining(right.serviceDue));
      if (servicePriority != 0) {
        return servicePriority;
      }
      return left.vehicleNumber.compareTo(right.vehicleNumber);
    });

    return filtered;
  }

  int get _availableCount => _summaryVehicles
      .where((vehicle) => vehicle.availability == 'Available')
      .length;

  int get _busyCount => _summaryVehicles
      .where((vehicle) => vehicle.availability == 'Busy')
      .length;

  int get _maintenanceCount => _summaryVehicles
      .where((vehicle) => vehicle.availability == 'Maintenance')
      .length;

  int get _serviceAttentionCount => _summaryVehicles
      .where(
        (vehicle) =>
            _isServiceOverdue(vehicle.serviceDue) ||
            _isServiceDueSoon(vehicle.serviceDue),
      )
      .length;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });

    try {
      final vehicles = await ref.read(adminApiServiceProvider).fetchVehicles();
      if (!mounted) {
        return;
      }
      setState(() {
        _vehicles = vehicles;
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

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _query = '';
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

  Future<void> _showVehicleDetails(AdminVehicleManagementMock vehicle) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _VehicleDetailsDialog(vehicle: vehicle),
    );
  }

  Future<void> _showCreateVehicleDialog() async {
    final result = await showVehicleFormDialog(
      context: context,
      mode: VehicleFormMode.create,
    );
    if (!mounted || result == null) {
      return;
    }

    try {
      final newVehicle = await ref
          .read(adminApiServiceProvider)
          .createVehicle(_vehiclePayload(result));

      setState(() {
        _vehicles = [newVehicle, ..._vehicles];
        _searchController.clear();
        _query = '';
        _availabilityFilter = _availabilityFilters.first;
      });

      _showMessage('${newVehicle.vehicleNumber} added to the fleet.');
    } on ApiException catch (error) {
      _showMessage(error.message, isError: true);
    }
  }

  Future<void> _showEditVehicleDialog(
    AdminVehicleManagementMock vehicle,
  ) async {
    final result = await showVehicleFormDialog(
      context: context,
      mode: VehicleFormMode.edit,
      initialVehicle: vehicle,
    );
    if (!mounted || result == null) {
      return;
    }

    try {
      final updatedVehicle = await ref
          .read(adminApiServiceProvider)
          .updateVehicle(vehicle, _vehiclePayload(result));

      setState(() {
        _vehicles = _vehicles.map((item) {
          if (item.id == vehicle.id) {
            return updatedVehicle;
          }
          return item;
        }).toList();
      });

      _showMessage('${updatedVehicle.vehicleNumber} updated successfully.');
    } on ApiException catch (error) {
      _showMessage(error.message, isError: true);
    }
  }

  Future<void> _toggleMaintenance(AdminVehicleManagementMock vehicle) async {
    final isInMaintenance = vehicle.availability == 'Maintenance';

    if (!isInMaintenance && vehicle.assignedTrip != null) {
      _showMessage(
        'Clear ${vehicle.assignedTrip} before sending ${vehicle.vehicleNumber} to service.',
        isError: true,
      );
      return;
    }

    setState(() => _busyVehicleIds.add(vehicle.id));
    try {
      final updatedVehicle = await ref
          .read(adminApiServiceProvider)
          .updateVehicle(vehicle, {
            'availabilityStatus': isInMaintenance ? 'available' : 'maintenance',
          });

      if (!mounted) {
        return;
      }

      setState(() {
        _busyVehicleIds.remove(vehicle.id);
        _vehicles = _vehicles.map((item) {
          if (item.id == vehicle.id) {
            return updatedVehicle;
          }
          return item;
        }).toList();
      });

      _showMessage(
        '${vehicle.vehicleNumber} ${isInMaintenance ? 'marked available' : 'queued for service'}.',
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyVehicleIds.remove(vehicle.id));
      _showMessage(error.message, isError: true);
    }
  }

  void _showAssignmentPlaceholder(AdminVehicleManagementMock vehicle) {
    _showMessage(
      'Select a shipment from Driver Assignment to assign ${vehicle.vehicleNumber}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredVehicles = _filteredVehicles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VehiclesHeader(
          totalCount: _summaryVehicles.length,
          availableCount: _availableCount,
          busyCount: _busyCount,
          maintenanceCount: _maintenanceCount,
          onAddPressed: _showCreateVehicleDialog,
        ),
        const SizedBox(height: AppSpacing.lg),
        _VehicleSummaryGrid(
          totalCount: _summaryVehicles.length,
          availableCount: _availableCount,
          busyCount: _busyCount,
          serviceAttentionCount: _serviceAttentionCount,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_isLoading)
          const AdminLoadingState(message: 'Loading fleet inventory...')
        else if (_hasLoadError)
          AdminErrorState(
            title: 'Vehicle inventory unavailable',
            message:
                'Vehicle records could not be loaded from the backend. Retry to restore the fleet list.',
            onRetry: _loadVehicles,
          )
        else ...[
          AdminSearchFilterBar(
            controller: _searchController,
            hintText:
                'Vehicle number, registration, type, model, fuel, driver, trip',
            filters: _availabilityFilters,
            selectedFilter: _availabilityFilter,
            onSearchChanged: (value) => setState(() => _query = value),
            onFilterChanged: (value) =>
                setState(() => _availabilityFilter = value),
            onClear: _clearFilters,
          ),
          const SizedBox(height: AppSpacing.md),
          _VehicleListMetaCard(
            visibleCount: filteredVehicles.length,
            totalCount: _vehicles.length,
            selectedFilter: _availabilityFilter,
          ),
          const SizedBox(height: AppSpacing.md),
          if (filteredVehicles.isEmpty)
            const AdminEmptyState(
              title: 'No vehicles found',
              message:
                  'Try clearing the current search or availability filter to view the fleet.',
              icon: Icons.local_shipping_outlined,
            )
          else
            AdminDataTable(
              dataRowMinHeight: 124,
              dataRowMaxHeight: 156,
              columns: const [
                AdminTableColumn('Vehicle number'),
                AdminTableColumn('Type / capacity'),
                AdminTableColumn('Registration'),
                AdminTableColumn('Service due'),
                AdminTableColumn('Availability'),
                AdminTableColumn('Assigned driver / trip'),
                AdminTableColumn('Actions'),
              ],
              rows: [
                for (final vehicle in filteredVehicles)
                  [
                    _VehicleIdentityCell(vehicle: vehicle),
                    _VehicleTypeCell(vehicle: vehicle),
                    SizedBox(
                      width: 150,
                      child: Text(
                        vehicle.registration,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    _ServiceDueCell(vehicle: vehicle),
                    AdminStatusBadge.fromStatus(vehicle.availability),
                    _AssignmentCell(vehicle: vehicle),
                    _VehicleActions(
                      isBusy: _busyVehicleIds.contains(vehicle.id),
                      isInMaintenance: vehicle.availability == 'Maintenance',
                      onView: () => _showVehicleDetails(vehicle),
                      onEdit: () => _showEditVehicleDialog(vehicle),
                      onAssign: () => _showAssignmentPlaceholder(vehicle),
                      onToggleMaintenance: () => _toggleMaintenance(vehicle),
                    ),
                  ],
              ],
            ),
        ],
      ],
    );
  }
}

class _VehiclesHeader extends StatelessWidget {
  const _VehiclesHeader({
    required this.totalCount,
    required this.availableCount,
    required this.busyCount,
    required this.maintenanceCount,
    required this.onAddPressed,
  });

  final int totalCount;
  final int availableCount;
  final int busyCount;
  final int maintenanceCount;
  final VoidCallback onAddPressed;

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
                Text(
                  'Vehicle management',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Track fleet capacity, registration, service readiness, and live assignment status from backend data.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            );

            final badges = Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AdminStatusBadge(
                  label: '$totalCount vehicles',
                  tone: AdminStatusTone.primary,
                ),
                AdminStatusBadge(
                  label: '$availableCount available',
                  tone: AdminStatusTone.success,
                ),
                AdminStatusBadge(
                  label: '$busyCount busy',
                  tone: AdminStatusTone.info,
                ),
                AdminStatusBadge(
                  label: '$maintenanceCount in service',
                  tone: maintenanceCount > 0
                      ? AdminStatusTone.warning
                      : AdminStatusTone.success,
                ),
              ],
            );

            final actionButton = ElevatedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add vehicle'),
            );

            if (constraints.maxWidth >= 920) {
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
                        badges,
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
                badges,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VehicleSummaryGrid extends StatelessWidget {
  const _VehicleSummaryGrid({
    required this.totalCount,
    required this.availableCount,
    required this.busyCount,
    required this.serviceAttentionCount,
  });

  final int totalCount;
  final int availableCount;
  final int busyCount;
  final int serviceAttentionCount;

  @override
  Widget build(BuildContext context) {
    final cards = [
      AdminStatCard(
        label: 'Fleet size',
        value: '$totalCount',
        delta: 'Registered vehicles',
        icon: Icons.fire_truck_outlined,
        isPositive: true,
        accentColor: AppColors.primaryBlue,
      ),
      AdminStatCard(
        label: 'Available',
        value: '$availableCount',
        delta: 'Ready for assignment',
        icon: Icons.task_alt_rounded,
        isPositive: true,
        accentColor: AppColors.success,
      ),
      AdminStatCard(
        label: 'Assigned',
        value: '$busyCount',
        delta: 'Active trip coverage',
        icon: Icons.route_outlined,
        isPositive: true,
        accentColor: AppColors.info,
      ),
      AdminStatCard(
        label: 'Service attention',
        value: '$serviceAttentionCount',
        delta: serviceAttentionCount == 0
            ? 'No immediate due dates'
            : 'Due or overdue within 14 days',
        icon: Icons.build_circle_outlined,
        isPositive: serviceAttentionCount == 0,
        accentColor: AppColors.warning,
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

class _VehicleListMetaCard extends StatelessWidget {
  const _VehicleListMetaCard({
    required this.visibleCount,
    required this.totalCount,
    required this.selectedFilter,
  });

  final int visibleCount;
  final int totalCount;
  final String selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                color: AppColors.primaryBlue,
              ),
            ),
            Text(
              '$visibleCount visible of $totalCount vehicles',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            AdminStatusBadge(
              label: selectedFilter == 'All'
                  ? 'All availability'
                  : '$selectedFilter only',
              tone: selectedFilter == 'All'
                  ? AdminStatusTone.neutral
                  : AdminStatusBadge.fromStatus(selectedFilter).tone,
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleIdentityCell extends StatelessWidget {
  const _VehicleIdentityCell({required this.vehicle});

  final AdminVehicleManagementMock vehicle;

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
          Text(
            vehicle.hub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _VehicleTypeCell extends StatelessWidget {
  const _VehicleTypeCell({required this.vehicle});

  final AdminVehicleManagementMock vehicle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(vehicle.type, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            vehicle.model,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(vehicle.capacity, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(vehicle.fuelType, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ServiceDueCell extends StatelessWidget {
  const _ServiceDueCell({required this.vehicle});

  final AdminVehicleManagementMock vehicle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDate(context, vehicle.serviceDue),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          AdminStatusBadge(
            label: _serviceLabel(vehicle),
            tone: _serviceTone(vehicle),
          ),
        ],
      ),
    );
  }
}

class _AssignmentCell extends StatelessWidget {
  const _AssignmentCell({required this.vehicle});

  final AdminVehicleManagementMock vehicle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            vehicle.assignedDriver,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
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

class _VehicleActions extends StatelessWidget {
  const _VehicleActions({
    required this.isBusy,
    required this.isInMaintenance,
    required this.onView,
    required this.onEdit,
    required this.onAssign,
    required this.onToggleMaintenance,
  });

  final bool isBusy;
  final bool isInMaintenance;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onAssign;
  final VoidCallback onToggleMaintenance;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 380,
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
            onPressed: isBusy ? null : onAssign,
            icon: const Icon(Icons.assignment_ind_outlined, size: 18),
            label: const Text('Assign'),
          ),
          TextButton.icon(
            onPressed: isBusy ? null : onToggleMaintenance,
            icon: isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isInMaintenance
                        ? Icons.task_alt_outlined
                        : Icons.build_outlined,
                    size: 18,
                  ),
            label: Text(isInMaintenance ? 'Mark available' : 'Service'),
          ),
        ],
      ),
    );
  }
}

class _VehicleDetailsDialog extends StatelessWidget {
  const _VehicleDetailsDialog({required this.vehicle});

  final AdminVehicleManagementMock vehicle;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${vehicle.vehicleNumber} details'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AdminStatusBadge.fromStatus(vehicle.availability),
                  AdminStatusBadge(
                    label: _serviceLabel(vehicle),
                    tone: _serviceTone(vehicle),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _VehicleDetailSection(
                title: 'Vehicle profile',
                children: [
                  _VehicleDetailTile(
                    label: 'Vehicle number',
                    value: vehicle.vehicleNumber,
                  ),
                  _VehicleDetailTile(label: 'Type', value: vehicle.type),
                  _VehicleDetailTile(
                    label: 'Capacity',
                    value: vehicle.capacity,
                  ),
                  _VehicleDetailTile(label: 'Model', value: vehicle.model),
                  _VehicleDetailTile(
                    label: 'Fuel type',
                    value: vehicle.fuelType,
                  ),
                  _VehicleDetailTile(
                    label: 'Registration',
                    value: vehicle.registration,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _VehicleDetailSection(
                title: 'Service and location',
                children: [
                  _VehicleDetailTile(
                    label: 'Insurance expiry',
                    value: _formatDate(context, vehicle.insuranceExpiry),
                  ),
                  _VehicleDetailTile(
                    label: 'Service due',
                    value: _formatDate(context, vehicle.serviceDue),
                  ),
                  _VehicleDetailTile(
                    label: 'Last inspection',
                    value: vehicle.lastInspection,
                  ),
                  _VehicleDetailTile(label: 'Hub', value: vehicle.hub),
                  _VehicleDetailTile(
                    label: 'Odometer',
                    value: vehicle.odometer,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _VehicleDetailSection(
                title: 'Assignment',
                children: [
                  _VehicleDetailTile(
                    label: 'Assigned driver',
                    value: vehicle.assignedDriver,
                  ),
                  _VehicleDetailTile(
                    label: 'Assigned trip',
                    value: vehicle.assignedTrip ?? 'No active trip',
                  ),
                  _VehicleDetailTile(label: 'Notes', value: vehicle.notes),
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

class _VehicleDetailSection extends StatelessWidget {
  const _VehicleDetailSection({required this.title, required this.children});

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

class _VehicleDetailTile extends StatelessWidget {
  const _VehicleDetailTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
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
