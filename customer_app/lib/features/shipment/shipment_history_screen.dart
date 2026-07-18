import 'dart:async';

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
import '../../core/widgets/status_badge.dart';
import 'data/customer_shipment_api.dart';

class ShipmentHistoryScreen extends ConsumerStatefulWidget {
  const ShipmentHistoryScreen({super.key});

  @override
  ConsumerState<ShipmentHistoryScreen> createState() =>
      _ShipmentHistoryScreenState();
}

class _ShipmentHistoryScreenState extends ConsumerState<ShipmentHistoryScreen> {
  final _searchController = TextEditingController();

  String _statusFilter = _allFilter;
  String _dateFilter = _allFilter;
  String _categoryFilter = _allFilter;
  List<String> _categoryOptions = const [_allFilter];
  Map<String, String> _categoryCodeByLabel = const {};
  var _shipments = <CustomerShipment>[];
  ApiPaginationMeta? _meta;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  Timer? _searchDebounce;

  static const _allFilter = 'All';
  static const _pageSize = 6;

  static const _dateOptions = [
    _allFilter,
    'Last 7 days',
    'This month',
    'Older',
  ];

  static const _statusOptions = [
    _allFilter,
    'Booked',
    'In transit',
    'Delivered',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    unawaited(_loadCategories());
    unawaited(_loadFirstPage());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_loadFirstPage()),
    );
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _fetchPage(page: 1);
      if (!mounted) {
        return;
      }
      setState(() {
        _shipments = result.shipments;
        _meta = result.meta;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      _setError(error.message);
    } catch (_) {
      _setError('Unable to load shipment history.');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ref
          .read(customerShipmentApiProvider)
          .listCategories();
      if (!mounted) {
        return;
      }

      final labels = categories
          .map((category) => _titleCase(category.name))
          .toList(growable: false);
      final codeMap = {
        for (final category in categories)
          _titleCase(category.name): category.code,
      };

      setState(() {
        _categoryOptions = [_allFilter, ...labels];
        _categoryCodeByLabel = codeMap;
      });
    } catch (_) {
      // Keep the "All" category filter if category metadata is temporarily unavailable.
    }
  }

  Future<void> _loadMore() async {
    final meta = _meta;
    if (meta == null || !meta.hasMore || _isLoadingMore) {
      return;
    }

    setState(() => _isLoadingMore = true);

    try {
      final result = await _fetchPage(page: meta.page + 1);
      if (!mounted) {
        return;
      }
      setState(() {
        _shipments = [..._shipments, ...result.shipments];
        _meta = result.meta;
        _isLoadingMore = false;
      });
    } on ApiException catch (error) {
      _showLoadMoreError(error.message);
    } catch (_) {
      _showLoadMoreError('Unable to load more shipments.');
    }
  }

  Future<ShipmentHistoryData> _fetchPage({required int page}) {
    final dateRange = _dateRangeForFilter(_dateFilter);
    return ref
        .read(customerShipmentApiProvider)
        .listShipmentHistory(
          search: _searchController.text.trim(),
          status: _statusFilterValue(_statusFilter),
          categoryCode: _categoryCodeByLabel[_categoryFilter],
          dateFrom: dateRange.$1,
          dateTo: dateRange.$2,
          page: page,
          limit: _pageSize,
        );
  }

  void _setError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _isLoadingMore = false;
      _errorMessage = message;
    });
  }

  void _showLoadMoreError(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _isLoadingMore = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _setFilter({String? status, String? date, String? category}) {
    setState(() {
      _statusFilter = status ?? _statusFilter;
      _dateFilter = date ?? _dateFilter;
      _categoryFilter = category ?? _categoryFilter;
    });
    unawaited(_loadFirstPage());
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _statusFilter = _allFilter;
      _dateFilter = _allFilter;
      _categoryFilter = _allFilter;
    });
    unawaited(_loadFirstPage());
  }

  void _openDetails(CustomerShipment shipment) {
    context.go(
      Uri(
        path: AppRoutes.shipmentDetails,
        queryParameters: {'shipmentId': shipment.id.toString()},
      ).toString(),
    );
  }

  void _openTracking(CustomerShipment shipment) {
    context.go(
      Uri(
        path: AppRoutes.tracking,
        queryParameters: {'shipmentId': shipment.id.toString()},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta;

    return CommonAppScaffold(
      title: 'Shipment history',
      subtitle: 'Search and filter your CargoConnect shipment records.',
      bottomNavigationIndex: 1,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HistoryHeader(totalCount: meta?.total ?? _shipments.length),
          const SizedBox(height: AppSpacing.lg),
          _HistoryFilters(
            searchController: _searchController,
            statusFilter: _statusFilter,
            dateFilter: _dateFilter,
            categoryFilter: _categoryFilter,
            statusOptions: _statusOptions,
            dateOptions: _dateOptions,
            categoryOptions: _categoryOptions,
            onStatusChanged: (value) => _setFilter(status: value),
            onDateChanged: (value) => _setFilter(date: value),
            onCategoryChanged: (value) => _setFilter(category: value),
            onClear: _clearFilters,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_isLoading)
            const LoadingWidget(message: 'Loading shipment history')
          else if (_errorMessage != null)
            ErrorStateWidget(
              title: 'History unavailable',
              message: _errorMessage!,
              onRetry: _loadFirstPage,
            )
          else if (_shipments.isEmpty)
            EmptyStateWidget(
              icon: Icons.manage_search_rounded,
              title: 'No shipments found',
              message:
                  'Try a different search term or clear filters to view your shipment records.',
              action: OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Clear filters'),
              ),
            )
          else ...[
            for (final shipment in _shipments) ...[
              _HistoryShipmentCard(
                shipment: shipment,
                onTap: () => _openDetails(shipment),
                onTrack: () => _openTracking(shipment),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.sm),
            _LoadMoreFooter(
              visibleCount: _shipments.length,
              totalCount: meta?.total ?? _shipments.length,
              hasMore: meta?.hasMore ?? false,
              isLoading: _isLoadingMore,
              onLoadMore: _loadMore,
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.totalCount});

  final int totalCount;

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
              Icons.history_rounded,
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
                  '$totalCount matching shipments',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Review bookings, invoices, and tracking status from one place.',
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

class _HistoryFilters extends StatelessWidget {
  const _HistoryFilters({
    required this.searchController,
    required this.statusFilter,
    required this.dateFilter,
    required this.categoryFilter,
    required this.statusOptions,
    required this.dateOptions,
    required this.categoryOptions,
    required this.onStatusChanged,
    required this.onDateChanged,
    required this.onCategoryChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final String statusFilter;
  final String dateFilter;
  final String categoryFilter;
  final List<String> statusOptions;
  final List<String> dateOptions;
  final List<String> categoryOptions;
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
            TextFormField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Search shipments',
                hintText: 'Search ID, route, receiver, category',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: searchController.clear,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final useWideLayout = constraints.maxWidth >= 620;

                final filters = [
                  _FilterDropdown(
                    label: 'Status',
                    value: statusFilter,
                    items: statusOptions,
                    icon: Icons.flag_rounded,
                    onChanged: onStatusChanged,
                  ),
                  _FilterDropdown(
                    label: 'Date',
                    value: dateFilter,
                    items: dateOptions,
                    icon: Icons.calendar_month_rounded,
                    onChanged: onDateChanged,
                  ),
                  _FilterDropdown(
                    label: 'Category',
                    value: categoryFilter,
                    items: categoryOptions,
                    icon: Icons.category_rounded,
                    onChanged: onCategoryChanged,
                  ),
                ];

                if (!useWideLayout) {
                  return Column(
                    children: [
                      for (final filter in filters) ...[
                        filter,
                        if (filter != filters.last)
                          const SizedBox(height: AppSpacing.sm),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: onClear,
                          icon: const Icon(Icons.filter_alt_off_rounded),
                          label: const Text('Clear'),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    for (final filter in filters) ...[
                      Expanded(child: filter),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    TextButton.icon(
                      onPressed: onClear,
                      icon: const Icon(Icons.filter_alt_off_rounded),
                      label: const Text('Clear'),
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

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: [
        for (final item in items)
          DropdownMenuItem<String>(value: item, child: Text(item)),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _HistoryShipmentCard extends StatelessWidget {
  const _HistoryShipmentCard({
    required this.shipment,
    required this.onTap,
    required this.onTrack,
  });

  final CustomerShipment shipment;
  final VoidCallback onTap;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
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
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          _routeLabel(shipment),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: _statusFromApi(shipment.shipmentStatus)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _HistoryChip(
                    icon: Icons.category_outlined,
                    label: shipment.categoryName ?? 'Shipment',
                  ),
                  _HistoryChip(
                    icon: Icons.calendar_today_rounded,
                    label: _formatDateTime(
                      shipment.pickupDateTime.isEmpty
                          ? shipment.createdAt
                          : shipment.pickupDateTime,
                    ),
                  ),
                  _HistoryChip(
                    icon: Icons.payments_outlined,
                    label: _formatMoney(shipment.estimatedPrice),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _CardDetailRow(
                icon: Icons.inventory_2_outlined,
                label:
                    '${shipment.packageWeightKg.toStringAsFixed(1)} kg ${shipment.packageType}',
              ),
              const SizedBox(height: AppSpacing.xs),
              _CardDetailRow(
                icon: Icons.fire_truck_outlined,
                label: shipment.vehiclePreference,
              ),
              const SizedBox(height: AppSpacing.xs),
              _CardDetailRow(
                icon: Icons.location_on_outlined,
                label: shipment.deliveryAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.description_outlined),
                      label: const Text('Details'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onTrack,
                      icon: const Icon(Icons.route_rounded),
                      label: const Text('Track'),
                    ),
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

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primaryBlue),
          const SizedBox(width: AppSpacing.xxs),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _CardDetailRow extends StatelessWidget {
  const _CardDetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({
    required this.visibleCount,
    required this.totalCount,
    required this.hasMore,
    required this.isLoading,
    required this.onLoadMore,
  });

  final int visibleCount;
  final int totalCount;
  final bool hasMore;
  final bool isLoading;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Showing $visibleCount of $totalCount shipments',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (hasMore)
          OutlinedButton.icon(
            onPressed: isLoading ? null : onLoadMore,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.expand_more_rounded),
            label: Text(isLoading ? 'Loading more...' : 'Load more'),
          )
        else
          const Text('End of shipment history'),
      ],
    );
  }
}

ShipmentStatus _statusFromApi(String status) {
  return switch (status) {
    'in_transit' => ShipmentStatus.inTransit,
    'delivered' || 'completed' => ShipmentStatus.delivered,
    'cancelled' || 'rejected' => ShipmentStatus.cancelled,
    _ => ShipmentStatus.booked,
  };
}

String? _statusFilterValue(String label) {
  return switch (label) {
    'Booked' => 'pending',
    'In transit' => 'in_transit',
    'Delivered' => 'delivered',
    'Cancelled' => 'cancelled',
    _ => null,
  };
}

(String?, String?) _dateRangeForFilter(String label) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return switch (label) {
    'Last 7 days' => (
      _dateOnly(today.subtract(const Duration(days: 7))),
      _dateOnly(today),
    ),
    'This month' => (
      _dateOnly(DateTime(today.year, today.month)),
      _dateOnly(today),
    ),
    'Older' => (
      null,
      _dateOnly(
        DateTime(today.year, today.month).subtract(const Duration(days: 1)),
      ),
    ),
    _ => (null, null),
  };
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _dateOnly(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _routeLabel(CustomerShipment shipment) {
  return '${_shortAddress(shipment.pickupAddress)} to ${_shortAddress(shipment.deliveryAddress)}';
}

String _shortAddress(String value) {
  final firstPart = value.split(',').first.trim();
  return firstPart.isEmpty ? 'Address pending' : firstPart;
}

String _formatMoney(double value) {
  return 'INR ${value.toStringAsFixed(0)}';
}

String _formatDateTime(String? value) {
  final date = DateTime.tryParse(value ?? '');
  if (date == null) {
    return 'Schedule pending';
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final hour = date.hour > 12 ? date.hour - 12 : date.hour;
  final displayHour = hour == 0 ? 12 : hour;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';

  return '${date.day} ${months[date.month - 1]} ${date.year}, '
      '$displayHour:$minute $period';
}
