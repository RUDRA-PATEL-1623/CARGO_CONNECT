import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/mock_admin_data.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/admin_data_table.dart';
import '../../core/widgets/admin_dialog.dart';
import '../../core/widgets/admin_state_widgets.dart';
import '../../core/widgets/admin_status_badge.dart';
import 'widgets/shipment_decision_dialogs.dart';

class ShipmentsScreen extends ConsumerStatefulWidget {
  const ShipmentsScreen({super.key});

  @override
  ConsumerState<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends ConsumerState<ShipmentsScreen> {
  final _searchController = TextEditingController();
  final Set<String> _selectedShipmentIds = {};
  final Map<String, String> _statusOverrides = {};
  final Map<String, String> _driverOverrides = {};
  final Map<String, String> _decisionAudit = {};
  List<AdminShipmentManagementMock> _shipments = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _query = '';
  String _statusFilter = 'All';
  String _dateFilter = 'All dates';
  String _categoryFilter = 'All categories';

  static const _statusFilters = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
    'Assigned',
    'Accepted',
    'In Transit',
    'Delivered',
    'Cancelled',
  ];

  static const _dateFilters = [
    'All dates',
    'Today',
    'This Week',
    'This Month',
    'Past',
  ];

  static const _categoryFilters = [
    'All categories',
    'Small Parcel',
    'Medium Goods',
    'Heavy Cargo',
    'Refrigerated',
    'Fragile',
    'Urgent',
  ];

  @override
  void initState() {
    super.initState();
    _loadShipments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadShipments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final shipments = await ref
          .read(adminApiServiceProvider)
          .fetchShipments();
      if (!mounted) {
        return;
      }
      setState(() {
        _shipments = shipments;
        _isLoading = false;
        _selectedShipmentIds.clear();
        _statusOverrides.clear();
        _driverOverrides.clear();
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

  List<AdminShipmentManagementMock> get _filteredShipments {
    final query = _query.trim().toLowerCase();

    return _shipments.where((shipment) {
      final status = _statusFor(shipment);
      final driver = _driverFor(shipment);
      final matchesSearch =
          query.isEmpty ||
          shipment.id.toLowerCase().contains(query) ||
          shipment.customer.toLowerCase().contains(query) ||
          shipment.route.toLowerCase().contains(query) ||
          shipment.category.toLowerCase().contains(query) ||
          driver.toLowerCase().contains(query) ||
          shipment.vehicle.toLowerCase().contains(query);
      final matchesStatus = _statusFilter == 'All' || status == _statusFilter;
      final matchesDate =
          _dateFilter == 'All dates' || shipment.dateFilter == _dateFilter;
      final matchesCategory =
          _categoryFilter == 'All categories' ||
          shipment.category == _categoryFilter;

      return matchesSearch && matchesStatus && matchesDate && matchesCategory;
    }).toList();
  }

  String _statusFor(AdminShipmentManagementMock shipment) {
    return _statusOverrides[shipment.id] ?? shipment.status;
  }

  String _driverFor(AdminShipmentManagementMock shipment) {
    return _driverOverrides[shipment.id] ?? shipment.driver;
  }

  bool get _allFilteredSelected {
    final filtered = _filteredShipments;
    return filtered.isNotEmpty &&
        filtered.every(
          (shipment) => _selectedShipmentIds.contains(shipment.id),
        );
  }

  void _toggleAllFiltered(bool? selected) {
    setState(() {
      if (selected ?? false) {
        _selectedShipmentIds.addAll(
          _filteredShipments.map((shipment) => shipment.id),
        );
      } else {
        _selectedShipmentIds.removeAll(
          _filteredShipments.map((shipment) => shipment.id),
        );
      }
    });
  }

  void _toggleShipment(String shipmentId, bool? selected) {
    setState(() {
      if (selected ?? false) {
        _selectedShipmentIds.add(shipmentId);
      } else {
        _selectedShipmentIds.remove(shipmentId);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _query = '';
      _statusFilter = 'All';
      _dateFilter = 'All dates';
      _categoryFilter = 'All categories';
      _selectedShipmentIds.clear();
    });
  }

  void _updateStatus(
    AdminShipmentManagementMock shipment,
    String status, {
    String? driver,
    String? auditMessage,
  }) {
    setState(() {
      _statusOverrides[shipment.id] = status;
      if (driver != null) {
        _driverOverrides[shipment.id] = driver;
      }
      if (auditMessage != null) {
        _decisionAudit[shipment.id] = auditMessage;
      }
    });

    final audit = _decisionAudit[shipment.id];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          audit == null || audit.isEmpty
              ? '${shipment.id} marked as $status.'
              : '${shipment.id} marked as $status. $audit',
        ),
      ),
    );
  }

  void _applyUpdatedShipment(AdminShipmentManagementMock updatedShipment) {
    setState(() {
      _shipments = _shipments.map((shipment) {
        if (shipment.id == updatedShipment.id ||
            shipment.backendId == updatedShipment.backendId) {
          return updatedShipment;
        }
        return shipment;
      }).toList();
      _statusOverrides.remove(updatedShipment.id);
      _driverOverrides.remove(updatedShipment.id);
    });
  }

  Future<void> _approveShipment(AdminShipmentManagementMock shipment) async {
    final result = await showShipmentApprovalDialog(
      context: context,
      shipmentId: shipment.id,
      customerName: shipment.customer,
    );
    if (!mounted || result == null) {
      return;
    }

    try {
      final updatedShipment = await ref
          .read(adminApiServiceProvider)
          .approveShipment(shipment: shipment, notes: result.notes);
      if (!mounted) {
        return;
      }
      _applyUpdatedShipment(updatedShipment);
      _updateStatus(
        updatedShipment,
        updatedShipment.status,
        auditMessage: result.notes.isEmpty
            ? 'Approved without extra notes.'
            : 'Notes: ${result.notes}',
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error.message);
    }
  }

  Future<void> _cancelShipment(AdminShipmentManagementMock shipment) async {
    final isPendingShipment = _statusFor(shipment) == 'Pending';
    final result = await showShipmentCancellationDialog(
      context: context,
      shipmentId: shipment.id,
      customerName: shipment.customer,
      isPendingShipment: isPendingShipment,
    );
    if (!mounted || result == null) {
      return;
    }

    final notes = result.notes.isEmpty ? '' : ' Notes: ${result.notes}';
    try {
      final service = ref.read(adminApiServiceProvider);
      final updatedShipment = isPendingShipment
          ? await service.rejectShipment(
              shipment: shipment,
              reason: result.reason,
            )
          : await service.cancelShipment(
              shipment: shipment,
              reason: result.reason,
            );
      if (!mounted) {
        return;
      }
      _applyUpdatedShipment(updatedShipment);
      _updateStatus(
        updatedShipment,
        updatedShipment.status,
        auditMessage: 'Reason: ${result.reason}.$notes',
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error.message);
    }
  }

  void _showDetails(AdminShipmentManagementMock shipment) {
    context.go(AppRoutes.shipmentDetails(shipment.id));
  }

  void _showBulkPlaceholder() {
    showAdminDialog(
      context: context,
      title: 'Bulk action placeholder',
      message:
          '${_selectedShipmentIds.length} shipment(s) selected. Bulk approve, assign, and cancel actions will be connected in a later workflow prompt.',
      icon: Icons.playlist_add_check_rounded,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.danger, content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredShipments = _filteredShipments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShipmentsHeader(shipments: _shipments),
        const SizedBox(height: AppSpacing.lg),
        _ShipmentFilterPanel(
          searchController: _searchController,
          statusFilters: _statusFilters,
          dateFilters: _dateFilters,
          categoryFilters: _categoryFilters,
          selectedStatus: _statusFilter,
          selectedDate: _dateFilter,
          selectedCategory: _categoryFilter,
          onSearchChanged: (value) => setState(() => _query = value),
          onStatusChanged: (value) => setState(() => _statusFilter = value),
          onDateChanged: (value) => setState(() => _dateFilter = value),
          onCategoryChanged: (value) => setState(() => _categoryFilter = value),
          onClear: _clearFilters,
        ),
        const SizedBox(height: AppSpacing.lg),
        _BulkActionsBar(
          selectedCount: _selectedShipmentIds.length,
          visibleCount: filteredShipments.length,
          totalCount: _shipments.length,
          onBulkAction: _showBulkPlaceholder,
        ),
        const SizedBox(height: AppSpacing.md),
        if (_isLoading)
          const AdminLoadingState(message: 'Loading shipments...')
        else if (_errorMessage != null)
          AdminErrorState(
            title: 'Shipment list unavailable',
            message: _errorMessage!,
            onRetry: _loadShipments,
          )
        else if (filteredShipments.isEmpty)
          AdminEmptyState(
            title: 'No shipments found',
            message:
                'Try clearing filters or searching by shipment ID, customer, route, driver, category, or vehicle.',
            icon: Icons.manage_search_rounded,
          )
        else
          AdminDataTable(
            columns: const [
              AdminTableColumn('Select'),
              AdminTableColumn('Shipment'),
              AdminTableColumn('Customer'),
              AdminTableColumn('Category'),
              AdminTableColumn('Route'),
              AdminTableColumn('Pickup date'),
              AdminTableColumn('Driver'),
              AdminTableColumn('Vehicle'),
              AdminTableColumn('Status'),
              AdminTableColumn('Amount'),
              AdminTableColumn('Actions'),
            ],
            rows: [
              [
                Checkbox(
                  value: _allFilteredSelected,
                  onChanged: _toggleAllFiltered,
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  'All visible',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
              ],
              for (final shipment in filteredShipments)
                [
                  Checkbox(
                    value: _selectedShipmentIds.contains(shipment.id),
                    onChanged: (value) => _toggleShipment(shipment.id, value),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(shipment.id),
                  _CustomerCell(name: shipment.customer, route: shipment.route),
                  Text(shipment.category),
                  SizedBox(width: 190, child: Text(shipment.route)),
                  Text(shipment.pickupDate),
                  Text(_driverFor(shipment)),
                  Text(shipment.vehicle),
                  AdminStatusBadge.fromStatus(_statusFor(shipment)),
                  Text(shipment.amount),
                  _ShipmentActions(
                    status: _statusFor(shipment),
                    onView: () => _showDetails(shipment),
                    onApprove: () => _approveShipment(shipment),
                    onCancel: () => _cancelShipment(shipment),
                    onAssign: () => context.go(
                      AppRoutes.shipmentAssignmentFor(shipment.id),
                    ),
                  ),
                ],
            ],
          ),
      ],
    );
  }
}

class _ShipmentsHeader extends StatelessWidget {
  const _ShipmentsHeader({required this.shipments});

  final List<AdminShipmentManagementMock> shipments;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pending = shipments
                .where((shipment) => shipment.status == 'Pending')
                .length;
            final active = shipments
                .where(
                  (shipment) =>
                      shipment.status == 'Approved' ||
                      shipment.status == 'Assigned' ||
                      shipment.status == 'Accepted' ||
                      shipment.status == 'In Transit',
                )
                .length;
            final delivered = shipments
                .where(
                  (shipment) =>
                      shipment.status == 'Delivered' ||
                      shipment.status == 'Completed',
                )
                .length;

            final summary = Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AdminStatusBadge(
                  label: '$pending pending',
                  tone: AdminStatusTone.warning,
                ),
                AdminStatusBadge(
                  label: '$active active',
                  tone: AdminStatusTone.primary,
                ),
                AdminStatusBadge(
                  label: '$delivered delivered',
                  tone: AdminStatusTone.success,
                ),
              ],
            );

            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shipment management',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Search, filter, review, approve, assign, and cancel shipments from backend operations data.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            );

            if (constraints.maxWidth >= 840) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: AppSpacing.lg),
                  summary,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.md),
                summary,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ShipmentFilterPanel extends StatelessWidget {
  const _ShipmentFilterPanel({
    required this.searchController,
    required this.statusFilters,
    required this.dateFilters,
    required this.categoryFilters,
    required this.selectedStatus,
    required this.selectedDate,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onDateChanged,
    required this.onCategoryChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final List<String> statusFilters;
  final List<String> dateFilters;
  final List<String> categoryFilters;
  final String selectedStatus;
  final String selectedDate;
  final String selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onDateChanged;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final searchField = TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    labelText: 'Search shipments',
                    hintText: 'Shipment ID, customer, route, driver, category',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: onClear,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                );

                final dateFilter = _FilterDropdown(
                  label: 'Date',
                  icon: Icons.calendar_today_outlined,
                  value: selectedDate,
                  items: dateFilters,
                  onChanged: onDateChanged,
                );

                final categoryFilter = _FilterDropdown(
                  label: 'Category',
                  icon: Icons.category_outlined,
                  value: selectedCategory,
                  items: categoryFilters,
                  onChanged: onCategoryChanged,
                );

                if (constraints.maxWidth >= 1100) {
                  return Row(
                    children: [
                      Expanded(flex: 4, child: searchField),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(flex: 2, child: dateFilter),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(flex: 2, child: categoryFilter),
                      const SizedBox(width: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: onClear,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reset'),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    searchField,
                    const SizedBox(height: AppSpacing.md),
                    dateFilter,
                    const SizedBox(height: AppSpacing.md),
                    categoryFilter,
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: onClear,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reset filters'),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Status filters',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final status in statusFilters)
                  FilterChip(
                    label: Text(status),
                    selected: selectedStatus == status,
                    onSelected: (_) => onStatusChanged(status),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: [
        for (final item in items)
          DropdownMenuItem(
            value: item,
            child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _BulkActionsBar extends StatelessWidget {
  const _BulkActionsBar({
    required this.selectedCount,
    required this.visibleCount,
    required this.totalCount,
    required this.onBulkAction,
  });

  final int selectedCount;
  final int visibleCount;
  final int totalCount;
  final VoidCallback onBulkAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final copy = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: const Icon(
                    Icons.playlist_add_check_rounded,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Flexible(
                  child: Text(
                    '$selectedCount selected - $visibleCount visible - $totalCount total',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            );

            final actions = Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: selectedCount == 0 ? null : onBulkAction,
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Approve selected'),
                ),
                OutlinedButton.icon(
                  onPressed: selectedCount == 0 ? null : onBulkAction,
                  icon: const Icon(Icons.assignment_ind_outlined),
                  label: const Text('Assign selected'),
                ),
                OutlinedButton.icon(
                  onPressed: selectedCount == 0 ? null : onBulkAction,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel selected'),
                ),
              ],
            );

            if (constraints.maxWidth >= 900) {
              return Row(
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: AppSpacing.md),
                  actions,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.md),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CustomerCell extends StatelessWidget {
  const _CustomerCell({required this.name, required this.route});

  final String name;
  final String route;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Tooltip(
        message: route,
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}

class _ShipmentActions extends StatelessWidget {
  const _ShipmentActions({
    required this.status,
    required this.onView,
    required this.onApprove,
    required this.onCancel,
    required this.onAssign,
  });

  final String status;
  final VoidCallback onView;
  final VoidCallback onApprove;
  final VoidCallback onCancel;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final terminal =
        status == 'Delivered' || status == 'Cancelled' || status == 'Rejected';
    final canApprove = status == 'Pending';
    final canAssign = !terminal && status != 'In Transit';
    final canCancel = !terminal;

    return SizedBox(
      width: 360,
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          TextButton.icon(
            onPressed: onView,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('View'),
          ),
          TextButton.icon(
            onPressed: canApprove ? onApprove : null,
            icon: const Icon(Icons.verified_outlined, size: 18),
            label: const Text('Approve'),
          ),
          TextButton.icon(
            onPressed: canAssign ? onAssign : null,
            icon: const Icon(Icons.assignment_ind_outlined, size: 18),
            label: const Text('Assign'),
          ),
          TextButton.icon(
            onPressed: canCancel ? onCancel : null,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: Text(status == 'Pending' ? 'Reject' : 'Cancel'),
          ),
        ],
      ),
    );
  }
}
