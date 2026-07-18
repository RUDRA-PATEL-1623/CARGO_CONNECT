import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/mock_admin_data.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/admin_state_widgets.dart';
import '../../core/widgets/admin_status_badge.dart';

class ShipmentAssignmentScreen extends ConsumerStatefulWidget {
  const ShipmentAssignmentScreen({super.key, this.initialShipmentId});

  final String? initialShipmentId;

  @override
  ConsumerState<ShipmentAssignmentScreen> createState() =>
      _ShipmentAssignmentScreenState();
}

class _ShipmentAssignmentScreenState
    extends ConsumerState<ShipmentAssignmentScreen> {
  final Map<String, _AssignmentRecord> _assignments = {};
  List<AdminShipmentManagementMock> _shipments = [];
  List<AdminDriverAssignmentMock> _drivers = [];
  List<AdminVehicleAssignmentMock> _vehicles = [];
  List<String> _serverValidationMessages = [];
  String? _selectedShipmentId;
  String? _selectedDriverId;
  String? _selectedVehicleId;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAssignmentData();
  }

  Future<void> _loadAssignmentData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ref
          .read(adminApiServiceProvider)
          .fetchAssignmentData(initialShipmentId: widget.initialShipmentId);
      if (!mounted) {
        return;
      }
      setState(() {
        _shipments = data.shipments;
        _drivers = data.drivers;
        _vehicles = data.vehicles;
        _selectedShipmentId = _initialShipmentId();
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

  AdminShipmentManagementMock? get _selectedShipment {
    final id = _selectedShipmentId;
    if (id == null) {
      return null;
    }

    for (final shipment in _shipments) {
      if (shipment.id == id) {
        return shipment;
      }
    }
    return null;
  }

  AdminDriverAssignmentMock? get _selectedDriver {
    final id = _selectedDriverId;
    if (id == null) {
      return null;
    }

    for (final driver in _drivers) {
      if (driver.id == id) {
        return driver;
      }
    }
    return null;
  }

  AdminVehicleAssignmentMock? get _selectedVehicle {
    final id = _selectedVehicleId;
    if (id == null) {
      return null;
    }

    for (final vehicle in _vehicles) {
      if (vehicle.id == id) {
        return vehicle;
      }
    }
    return null;
  }

  List<String> get _validationMessages {
    final shipment = _selectedShipment;
    final driver = _selectedDriver;
    final vehicle = _selectedVehicle;
    final messages = <String>[];

    if (shipment == null) {
      messages.add('Select a shipment to assign.');
      return messages;
    }

    if (driver == null) {
      messages.add('Select an available driver.');
    } else if (_isDriverAlreadyAssigned(driver)) {
      messages.add(
        '${driver.name} is already assigned to ${driver.currentShipmentId ?? _assignedShipmentForDriver(driver.id)}.',
      );
    }

    if (vehicle == null) {
      messages.add('Select an available vehicle.');
    } else if (_isVehicleAlreadyAssigned(vehicle)) {
      messages.add(
        '${vehicle.label} is already assigned to ${vehicle.currentShipmentId ?? _assignedShipmentForVehicle(vehicle.id)}.',
      );
    }

    if (shipment.category == 'Refrigerated' &&
        vehicle != null &&
        vehicle.type != 'Reefer Van') {
      messages.add('Refrigerated shipments require a reefer vehicle.');
    }

    messages.addAll(_serverValidationMessages);
    return messages;
  }

  bool get _canConfirm => _validationMessages.isEmpty && !_isSubmitting;

  String? _initialShipmentId() {
    final provided = widget.initialShipmentId;
    if (provided != null &&
        _shipments.any((shipment) => shipment.id == provided)) {
      return provided;
    }

    if (_shipments.isEmpty) {
      return null;
    }

    return _shipments
        .firstWhere(
          (shipment) =>
              shipment.driver == 'Unassigned' &&
              shipment.status != 'Cancelled' &&
              shipment.status != 'Delivered',
          orElse: () => _shipments.first,
        )
        .id;
  }

  bool _isDriverAlreadyAssigned(AdminDriverAssignmentMock driver) {
    return driver.currentShipmentId != null ||
        _assignments.values.any(
          (assignment) => assignment.driverId == driver.id,
        );
  }

  bool _isVehicleAlreadyAssigned(AdminVehicleAssignmentMock vehicle) {
    return vehicle.currentShipmentId != null ||
        _assignments.values.any(
          (assignment) => assignment.vehicleId == vehicle.id,
        );
  }

  String? _assignedShipmentForDriver(String driverId) {
    for (final entry in _assignments.entries) {
      if (entry.value.driverId == driverId) {
        return entry.key;
      }
    }
    return null;
  }

  String? _assignedShipmentForVehicle(String vehicleId) {
    for (final entry in _assignments.entries) {
      if (entry.value.vehicleId == vehicleId) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> _confirmAssignment() async {
    if (!_canConfirm) {
      return;
    }

    final shipment = _selectedShipment!;
    final driver = _selectedDriver!;
    final vehicle = _selectedVehicle!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.assignment_turned_in_outlined,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Confirm assignment ${shipment.id}')),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DialogSummaryRow(label: 'Shipment', value: shipment.id),
                _DialogSummaryRow(label: 'Route', value: shipment.route),
                _DialogSummaryRow(label: 'Driver', value: driver.name),
                _DialogSummaryRow(label: 'Vehicle', value: vehicle.label),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'The backend will validate active driver and vehicle conflicts before creating or replacing this assignment.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Review'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.check_rounded),
              label: Text(
                shipment.assignmentBackendId == null
                    ? 'Confirm assignment'
                    : 'Confirm reassignment',
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _serverValidationMessages = [];
    });

    try {
      final service = ref.read(adminApiServiceProvider);
      final validation = await service.validateAssignment(
        shipment: shipment,
        driver: driver,
        vehicle: vehicle,
      );

      if (!validation.canAssign) {
        setState(() {
          _isSubmitting = false;
          _serverValidationMessages = validation.messages;
        });
        return;
      }

      await service.assignShipment(
        shipment: shipment,
        driver: driver,
        vehicle: vehicle,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _assignments[shipment.id] = _AssignmentRecord(
          driverId: driver.id,
          vehicleId: vehicle.id,
          driverName: driver.name,
          vehicleLabel: vehicle.label,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shipment.assignmentBackendId == null
                ? '${shipment.id} assigned to ${driver.name} with ${vehicle.label}.'
                : '${shipment.id} reassigned to ${driver.name} with ${vehicle.label}.',
          ),
        ),
      );
      await _loadAssignmentData();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
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
    final shipment = _selectedShipment;
    final validationMessages = _validationMessages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AssignmentHeader(onBack: () => context.go(AppRoutes.shipments)),
        const SizedBox(height: AppSpacing.lg),
        if (_isLoading)
          const AdminLoadingState(message: 'Loading assignment resources...')
        else if (_errorMessage != null)
          AdminErrorState(
            title: 'Assignment resources unavailable',
            message: _errorMessage!,
            onRetry: _loadAssignmentData,
          )
        else ...[
          _ShipmentSelectorCard(
            shipments: _shipments,
            selectedShipmentId: _selectedShipmentId,
            onChanged: (value) {
              setState(() {
                _selectedShipmentId = value;
                _selectedDriverId = null;
                _selectedVehicleId = null;
                _serverValidationMessages = [];
              });
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final driverList = _DriverListCard(
                drivers: _drivers,
                selectedDriverId: _selectedDriverId,
                isAssigned: _isDriverAlreadyAssigned,
                onSelected: (driver) {
                  setState(() {
                    _selectedDriverId = driver.id;
                    _serverValidationMessages = [];
                  });
                },
              );
              final vehicleList = _VehicleListCard(
                vehicles: _vehicles,
                selectedVehicleId: _selectedVehicleId,
                isAssigned: _isVehicleAlreadyAssigned,
                onSelected: (vehicle) {
                  setState(() {
                    _selectedVehicleId = vehicle.id;
                    _serverValidationMessages = [];
                  });
                },
              );

              if (constraints.maxWidth >= 980) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: driverList),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: vehicleList),
                  ],
                );
              }

              return Column(
                children: [
                  driverList,
                  const SizedBox(height: AppSpacing.md),
                  vehicleList,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _AssignmentSummaryCard(
            shipment: shipment,
            driver: _selectedDriver,
            vehicle: _selectedVehicle,
            validationMessages: validationMessages,
            existingAssignment: shipment == null
                ? null
                : _assignments[shipment.id],
            canConfirm: _canConfirm,
            onConfirm: _confirmAssignment,
          ),
        ],
      ],
    );
  }
}

class _AssignmentHeader extends StatelessWidget {
  const _AssignmentHeader({required this.onBack});

  final VoidCallback onBack;

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
                OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to shipments'),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Shipment assignment',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Select one shipment, one available driver, and one available vehicle. Backend validation blocks already assigned resources.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            );

            final badge = const AdminStatusBadge(
              label: 'Backend validation',
              tone: AdminStatusTone.info,
            );

            if (constraints.maxWidth >= 760) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: AppSpacing.md),
                  badge,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.md),
                badge,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ShipmentSelectorCard extends StatelessWidget {
  const _ShipmentSelectorCard({
    required this.shipments,
    required this.selectedShipmentId,
    required this.onChanged,
  });

  final List<AdminShipmentManagementMock> shipments;
  final String? selectedShipmentId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final selector = DropdownButtonFormField<String>(
              initialValue: selectedShipmentId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Select shipment',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              items: [
                for (final shipment in shipments)
                  DropdownMenuItem(
                    value: shipment.id,
                    child: Text(
                      '${shipment.id} - ${shipment.customer} - ${shipment.route}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: onChanged,
            );

            AdminShipmentManagementMock? selected;
            for (final shipment in shipments) {
              if (shipment.id == selectedShipmentId) {
                selected = shipment;
                break;
              }
            }

            final details = selected == null
                ? const SizedBox.shrink()
                : _SelectedShipmentDetails(shipment: selected);

            if (constraints.maxWidth >= 860) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: selector),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: details),
                ],
              );
            }

            return Column(
              children: [
                selector,
                const SizedBox(height: AppSpacing.md),
                details,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SelectedShipmentDetails extends StatelessWidget {
  const _SelectedShipmentDetails({required this.shipment});

  final AdminShipmentManagementMock shipment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          _MiniInfo(label: 'Status', value: shipment.status),
          _MiniInfo(label: 'Category', value: shipment.category),
          _MiniInfo(label: 'Pickup', value: shipment.pickupDate),
          _MiniInfo(label: 'Driver', value: shipment.driver),
        ],
      ),
    );
  }
}

class _DriverListCard extends StatelessWidget {
  const _DriverListCard({
    required this.drivers,
    required this.selectedDriverId,
    required this.isAssigned,
    required this.onSelected,
  });

  final List<AdminDriverAssignmentMock> drivers;
  final String? selectedDriverId;
  final bool Function(AdminDriverAssignmentMock driver) isAssigned;
  final ValueChanged<AdminDriverAssignmentMock> onSelected;

  @override
  Widget build(BuildContext context) {
    return _AssignmentListCard(
      title: 'Available driver list',
      icon: Icons.badge_outlined,
      children: [
        for (final driver in drivers)
          _DriverOptionCard(
            driver: driver,
            selected: selectedDriverId == driver.id,
            blocked: isAssigned(driver),
            onTap: () => onSelected(driver),
          ),
      ],
    );
  }
}

class _VehicleListCard extends StatelessWidget {
  const _VehicleListCard({
    required this.vehicles,
    required this.selectedVehicleId,
    required this.isAssigned,
    required this.onSelected,
  });

  final List<AdminVehicleAssignmentMock> vehicles;
  final String? selectedVehicleId;
  final bool Function(AdminVehicleAssignmentMock vehicle) isAssigned;
  final ValueChanged<AdminVehicleAssignmentMock> onSelected;

  @override
  Widget build(BuildContext context) {
    return _AssignmentListCard(
      title: 'Available vehicle list',
      icon: Icons.local_shipping_outlined,
      children: [
        for (final vehicle in vehicles)
          _VehicleOptionCard(
            vehicle: vehicle,
            selected: selectedVehicleId == vehicle.id,
            blocked: isAssigned(vehicle),
            onTap: () => onSelected(vehicle),
          ),
      ],
    );
  }
}

class _AssignmentListCard extends StatelessWidget {
  const _AssignmentListCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DriverOptionCard extends StatelessWidget {
  const _DriverOptionCard({
    required this.driver,
    required this.selected,
    required this.blocked,
    required this.onTap,
  });

  final AdminDriverAssignmentMock driver;
  final bool selected;
  final bool blocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableResourceCard(
      selected: selected,
      blocked: blocked,
      onTap: onTap,
      title: driver.name,
      subtitle: '${driver.zone} - Rating ${driver.rating}',
      meta: driver.phone,
      statusLabel: blocked ? 'Conflict' : driver.status,
      icon: Icons.person_pin_circle_outlined,
    );
  }
}

class _VehicleOptionCard extends StatelessWidget {
  const _VehicleOptionCard({
    required this.vehicle,
    required this.selected,
    required this.blocked,
    required this.onTap,
  });

  final AdminVehicleAssignmentMock vehicle;
  final bool selected;
  final bool blocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableResourceCard(
      selected: selected,
      blocked: blocked,
      onTap: onTap,
      title: vehicle.label,
      subtitle: '${vehicle.type} - ${vehicle.capacity}',
      meta: vehicle.registration,
      statusLabel: blocked ? 'Conflict' : vehicle.status,
      icon: Icons.fire_truck_outlined,
    );
  }
}

class _SelectableResourceCard extends StatelessWidget {
  const _SelectableResourceCard({
    required this.selected,
    required this.blocked,
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.statusLabel,
    required this.icon,
  });

  final bool selected;
  final bool blocked;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final String meta;
  final String statusLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.primaryBlue
        : blocked
        ? AppColors.danger.withValues(alpha: 0.35)
        : AppColors.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected
            ? AppColors.primaryBlue.withValues(alpha: 0.06)
            : blocked
            ? AppColors.danger.withValues(alpha: 0.04)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: blocked ? AppColors.danger : AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(meta, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AdminStatusBadge(
                  label: statusLabel,
                  tone: blocked
                      ? AdminStatusTone.danger
                      : AdminStatusTone.success,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssignmentSummaryCard extends StatelessWidget {
  const _AssignmentSummaryCard({
    required this.shipment,
    required this.driver,
    required this.vehicle,
    required this.validationMessages,
    required this.existingAssignment,
    required this.canConfirm,
    required this.onConfirm,
  });

  final AdminShipmentManagementMock? shipment;
  final AdminDriverAssignmentMock? driver;
  final AdminVehicleAssignmentMock? vehicle;
  final List<String> validationMessages;
  final _AssignmentRecord? existingAssignment;
  final bool canConfirm;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Assignment summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _SummaryTile(label: 'Shipment', value: shipment?.id ?? 'None'),
                _SummaryTile(label: 'Driver', value: driver?.name ?? 'None'),
                _SummaryTile(label: 'Vehicle', value: vehicle?.label ?? 'None'),
                _SummaryTile(
                  label: 'Route',
                  value: shipment?.route ?? 'Select a shipment',
                ),
              ],
            ),
            if (existingAssignment != null) ...[
              const SizedBox(height: AppSpacing.md),
              _ValidationBanner(
                messages: [
                  'Assignment exists: ${existingAssignment!.driverName} with ${existingAssignment!.vehicleLabel}.',
                ],
                tone: AdminStatusTone.info,
              ),
            ],
            if (validationMessages.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _ValidationBanner(messages: validationMessages),
            ],
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: canConfirm ? onConfirm : null,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Confirm assignment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidationBanner extends StatelessWidget {
  const _ValidationBanner({
    required this.messages,
    this.tone = AdminStatusTone.danger,
  });

  final List<String> messages;
  final AdminStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = tone == AdminStatusTone.info
        ? AppColors.info
        : AppColors.danger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final message in messages)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    tone == AdminStatusTone.info
                        ? Icons.info_outline_rounded
                        : Icons.error_outline_rounded,
                    size: 18,
                    color: color,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(message)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _DialogSummaryRow extends StatelessWidget {
  const _DialogSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _AssignmentRecord {
  const _AssignmentRecord({
    required this.driverId,
    required this.vehicleId,
    required this.driverName,
    required this.vehicleLabel,
  });

  final String driverId;
  final String vehicleId;
  final String driverName;
  final String vehicleLabel;
}
