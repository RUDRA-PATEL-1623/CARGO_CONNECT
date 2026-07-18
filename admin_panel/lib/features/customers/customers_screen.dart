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

String _formatDate(BuildContext context, DateTime date) {
  return MaterialLocalizations.of(context).formatMediumDate(date);
}

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  static const _statusFilters = ['All', 'Active', 'Inactive', 'Blocked'];

  final _searchController = TextEditingController();
  final Set<String> _busyCustomerIds = <String>{};

  List<AdminCustomerManagementMock> _customers =
      <AdminCustomerManagementMock>[];
  String _query = '';
  String _statusFilter = _statusFilters.first;
  bool _isLoading = true;
  bool _hasLoadError = false;

  List<AdminCustomerManagementMock> get _summaryCustomers => _customers;

  List<AdminCustomerManagementMock> get _filteredCustomers {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = _customers.where((customer) {
      final matchesSearch =
          normalizedQuery.isEmpty ||
          customer.id.toLowerCase().contains(normalizedQuery) ||
          customer.name.toLowerCase().contains(normalizedQuery) ||
          customer.email.toLowerCase().contains(normalizedQuery) ||
          customer.phone.toLowerCase().contains(normalizedQuery) ||
          customer.address.toLowerCase().contains(normalizedQuery) ||
          customer.preferredCategory.toLowerCase().contains(normalizedQuery) ||
          (customer.lastShipmentId ?? '').toLowerCase().contains(
            normalizedQuery,
          );
      final matchesStatus =
          _statusFilter == _statusFilters.first ||
          customer.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    filtered.sort((left, right) {
      final statusPriority = _statusRank(
        left.status,
      ).compareTo(_statusRank(right.status));
      if (statusPriority != 0) {
        return statusPriority;
      }
      return right.totalShipments.compareTo(left.totalShipments);
    });

    return filtered;
  }

  int get _activeCount =>
      _summaryCustomers.where((customer) => customer.status == 'Active').length;

  int get _inactiveCount => _summaryCustomers
      .where((customer) => customer.status == 'Inactive')
      .length;

  int get _blockedCount => _summaryCustomers
      .where((customer) => customer.status == 'Blocked')
      .length;

  int get _openIssueCount => _summaryCustomers.fold<int>(
    0,
    (sum, customer) => sum + customer.openIssues,
  );

  int _statusRank(String status) {
    switch (status) {
      case 'Active':
        return 0;
      case 'Inactive':
        return 1;
      case 'Blocked':
        return 2;
      default:
        return 3;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });

    try {
      final customers = await ref
          .read(adminApiServiceProvider)
          .fetchCustomers();
      if (!mounted) {
        return;
      }
      setState(() {
        _customers = customers;
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
      _statusFilter = _statusFilters.first;
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

  Future<void> _showCustomerDetails(
    AdminCustomerManagementMock customer,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _CustomerDetailsDialog(customer: customer),
    );
  }

  Future<void> _toggleCustomerStatus(
    AdminCustomerManagementMock customer,
  ) async {
    final shouldActivate = customer.status != 'Active';

    setState(() => _busyCustomerIds.add(customer.id));

    try {
      final service = ref.read(adminApiServiceProvider);
      final updatedCustomer = shouldActivate
          ? await service.activateCustomer(customer)
          : await service.deactivateCustomer(customer);

      if (!mounted) {
        return;
      }

      setState(() {
        _busyCustomerIds.remove(customer.id);
        _customers = _customers.map((item) {
          if (item.id == customer.id) {
            return updatedCustomer;
          }
          return item;
        }).toList();
      });

      _showMessage(
        '${updatedCustomer.name} ${shouldActivate ? 'activated' : 'deactivated'} successfully.',
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyCustomerIds.remove(customer.id));
      _showMessage(error.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = _filteredCustomers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CustomersHeader(
          totalCount: _summaryCustomers.length,
          activeCount: _activeCount,
          inactiveCount: _inactiveCount,
          blockedCount: _blockedCount,
        ),
        const SizedBox(height: AppSpacing.lg),
        _CustomerSummaryGrid(
          totalCount: _summaryCustomers.length,
          activeCount: _activeCount,
          blockedCount: _blockedCount,
          openIssueCount: _openIssueCount,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_isLoading)
          const AdminLoadingState(message: 'Loading customer directory...')
        else if (_hasLoadError)
          AdminErrorState(
            title: 'Customer directory unavailable',
            message:
                'Customer records could not be loaded from the backend. Retry to restore the customer list.',
            onRetry: _loadCustomers,
          )
        else ...[
          AdminSearchFilterBar(
            controller: _searchController,
            hintText: 'Name, email, phone, address, shipment, category',
            filters: _statusFilters,
            selectedFilter: _statusFilter,
            onSearchChanged: (value) => setState(() => _query = value),
            onFilterChanged: (value) => setState(() => _statusFilter = value),
            onClear: _clearFilters,
          ),
          const SizedBox(height: AppSpacing.md),
          _CustomerListMetaCard(
            visibleCount: filteredCustomers.length,
            totalCount: _customers.length,
            selectedFilter: _statusFilter,
          ),
          const SizedBox(height: AppSpacing.md),
          if (filteredCustomers.isEmpty)
            const AdminEmptyState(
              title: 'No customers found',
              message:
                  'Try clearing the current search or status filter to view all customers.',
              icon: Icons.people_outline,
            )
          else
            AdminDataTable(
              dataRowMinHeight: 88,
              dataRowMaxHeight: 116,
              columns: const [
                AdminTableColumn('Name'),
                AdminTableColumn('Email'),
                AdminTableColumn('Phone'),
                AdminTableColumn('Total shipments'),
                AdminTableColumn('Status'),
                AdminTableColumn('Registered date'),
                AdminTableColumn('Actions'),
              ],
              rows: [
                for (final customer in filteredCustomers)
                  [
                    _CustomerNameCell(customer: customer),
                    SizedBox(
                      width: 260,
                      child: Text(
                        customer.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: Text(
                        customer.phone,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    _ShipmentCountCell(customer: customer),
                    AdminStatusBadge.fromStatus(customer.status),
                    SizedBox(
                      width: 150,
                      child: Text(
                        _formatDate(context, customer.registeredDate),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    _CustomerActions(
                      isBusy: _busyCustomerIds.contains(customer.id),
                      isActive: customer.status == 'Active',
                      onView: () => _showCustomerDetails(customer),
                      onToggleStatus: () => _toggleCustomerStatus(customer),
                    ),
                  ],
              ],
            ),
        ],
      ],
    );
  }
}

class _CustomersHeader extends StatelessWidget {
  const _CustomersHeader({
    required this.totalCount,
    required this.activeCount,
    required this.inactiveCount,
    required this.blockedCount,
  });

  final int totalCount;
  final int activeCount;
  final int inactiveCount;
  final int blockedCount;

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
                  'Customer management',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Review customer accounts, shipment history, account health, and support exposure from backend data.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            );

            final badges = Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AdminStatusBadge(
                  label: '$totalCount customers',
                  tone: AdminStatusTone.primary,
                ),
                AdminStatusBadge(
                  label: '$activeCount active',
                  tone: AdminStatusTone.success,
                ),
                AdminStatusBadge(
                  label: '$inactiveCount inactive',
                  tone: AdminStatusTone.neutral,
                ),
                AdminStatusBadge(
                  label: '$blockedCount blocked',
                  tone: blockedCount > 0
                      ? AdminStatusTone.danger
                      : AdminStatusTone.success,
                ),
              ],
            );

            if (constraints.maxWidth >= 920) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: AppSpacing.lg),
                  Flexible(child: badges),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
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

class _CustomerSummaryGrid extends StatelessWidget {
  const _CustomerSummaryGrid({
    required this.totalCount,
    required this.activeCount,
    required this.blockedCount,
    required this.openIssueCount,
  });

  final int totalCount;
  final int activeCount;
  final int blockedCount;
  final int openIssueCount;

  @override
  Widget build(BuildContext context) {
    final cards = [
      AdminStatCard(
        label: 'Total customers',
        value: '$totalCount',
        delta: 'Registered customer accounts',
        icon: Icons.people_outline,
        isPositive: true,
        accentColor: AppColors.primaryBlue,
      ),
      AdminStatCard(
        label: 'Active accounts',
        value: '$activeCount',
        delta: 'Eligible to book shipments',
        icon: Icons.verified_user_outlined,
        isPositive: true,
        accentColor: AppColors.success,
      ),
      AdminStatCard(
        label: 'Blocked accounts',
        value: '$blockedCount',
        delta: blockedCount == 0 ? 'No restrictions' : 'Require admin review',
        icon: Icons.block_outlined,
        isPositive: blockedCount == 0,
        accentColor: AppColors.danger,
      ),
      AdminStatCard(
        label: 'Open issues',
        value: '$openIssueCount',
        delta: openIssueCount == 0
            ? 'No support exposure'
            : 'Across customer accounts',
        icon: Icons.support_agent_outlined,
        isPositive: openIssueCount == 0,
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

class _CustomerListMetaCard extends StatelessWidget {
  const _CustomerListMetaCard({
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
                Icons.people_outline,
                color: AppColors.primaryBlue,
              ),
            ),
            Text(
              '$visibleCount visible of $totalCount customers',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            AdminStatusBadge(
              label: selectedFilter == 'All'
                  ? 'All statuses'
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

class _CustomerNameCell extends StatelessWidget {
  const _CustomerNameCell({required this.customer});

  final AdminCustomerManagementMock customer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            customer.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(customer.id, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            customer.preferredCategory,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ShipmentCountCell extends StatelessWidget {
  const _ShipmentCountCell({required this.customer});

  final AdminCustomerManagementMock customer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${customer.totalShipments}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            customer.lastShipmentId ?? 'No shipments',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CustomerActions extends StatelessWidget {
  const _CustomerActions({
    required this.isBusy,
    required this.isActive,
    required this.onView,
    required this.onToggleStatus,
  });

  final bool isBusy;
  final bool isActive;
  final VoidCallback onView;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
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

class _CustomerDetailsDialog extends StatelessWidget {
  const _CustomerDetailsDialog({required this.customer});

  final AdminCustomerManagementMock customer;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${customer.name} details'),
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
                  AdminStatusBadge.fromStatus(customer.status),
                  AdminStatusBadge(
                    label: '${customer.totalShipments} shipments',
                    tone: AdminStatusTone.primary,
                  ),
                  AdminStatusBadge(
                    label: '${customer.openIssues} open issues',
                    tone: customer.openIssues == 0
                        ? AdminStatusTone.success
                        : AdminStatusTone.warning,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _CustomerDetailSection(
                title: 'Customer profile',
                children: [
                  _CustomerDetailTile(label: 'Customer ID', value: customer.id),
                  _CustomerDetailTile(label: 'Name', value: customer.name),
                  _CustomerDetailTile(label: 'Email', value: customer.email),
                  _CustomerDetailTile(label: 'Phone', value: customer.phone),
                  _CustomerDetailTile(
                    label: 'Registered date',
                    value: _formatDate(context, customer.registeredDate),
                  ),
                  _CustomerDetailTile(
                    label: 'Address',
                    value: customer.address,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _CustomerDetailSection(
                title: 'Shipment summary',
                children: [
                  _CustomerDetailTile(
                    label: 'Total shipments',
                    value: '${customer.totalShipments}',
                  ),
                  _CustomerDetailTile(
                    label: 'Last shipment',
                    value: customer.lastShipmentId ?? 'No shipments',
                  ),
                  _CustomerDetailTile(
                    label: 'Preferred category',
                    value: customer.preferredCategory,
                  ),
                  _CustomerDetailTile(
                    label: 'Lifetime value',
                    value: customer.lifetimeValue,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _CustomerDetailSection(
                title: 'Account activity',
                children: [
                  _CustomerDetailTile(label: 'Status', value: customer.status),
                  _CustomerDetailTile(
                    label: 'Open issues',
                    value: '${customer.openIssues}',
                  ),
                  _CustomerDetailTile(
                    label: 'Latest activity',
                    value: customer.lastActivity,
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

class _CustomerDetailSection extends StatelessWidget {
  const _CustomerDetailSection({required this.title, required this.children});

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

class _CustomerDetailTile extends StatelessWidget {
  const _CustomerDetailTile({required this.label, required this.value});

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
