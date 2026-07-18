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
import 'data/customer_shipment_api.dart';

class ShipmentScreen extends ConsumerStatefulWidget {
  const ShipmentScreen({super.key});

  @override
  ConsumerState<ShipmentScreen> createState() => _ShipmentScreenState();
}

class _ShipmentScreenState extends ConsumerState<ShipmentScreen> {
  _CargoCategory? _selectedCategory;
  late Future<List<_CargoCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _loadCategories();
  }

  Future<List<_CargoCategory>> _loadCategories() async {
    final categories = await ref
        .read(customerShipmentApiProvider)
        .listCategories();
    return categories.map(_CargoCategory.fromApi).toList(growable: false);
  }

  void _retryCategories() {
    setState(() {
      _selectedCategory = null;
      _categoriesFuture = _loadCategories();
    });
  }

  bool get _hasSelection => _selectedCategory != null;

  void _continueWithSelection() {
    final category = _selectedCategory;
    if (category == null) {
      return;
    }

    context.go(
      Uri(
        path: AppRoutes.createShipment,
        queryParameters: {
          'category': category.title,
          'categoryCode': category.code,
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppScaffold(
      title: 'Select cargo category',
      subtitle:
          'Choose the shipment type so CargoConnect can suggest the right vehicle and starting estimate.',
      bottomNavigationIndex: 1,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CategoryIntroCard(),
          const SizedBox(height: AppSpacing.lg),
          FutureBuilder<List<_CargoCategory>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget(message: 'Loading cargo categories');
              }

              if (snapshot.hasError) {
                final message = snapshot.error is ApiException
                    ? (snapshot.error! as ApiException).message
                    : 'Unable to load shipment categories.';

                return ErrorStateWidget(
                  title: 'Categories unavailable',
                  message: message,
                  onRetry: _retryCategories,
                );
              }

              final categories = snapshot.data ?? const [];
              if (categories.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.category_outlined,
                  title: 'No active categories',
                  message: 'Shipment categories will appear here once active.',
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final useTwoColumns = constraints.maxWidth >= 620;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: useTwoColumns ? 2 : 1,
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                      childAspectRatio: useTwoColumns ? 1.2 : 1.72,
                    ),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _CategoryCard(
                        category: category,
                        isSelected: category == _selectedCategory,
                        onTap: () {
                          setState(() => _selectedCategory = category);
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _SelectedSummary(category: _selectedCategory),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: _hasSelection ? _continueWithSelection : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _CategoryIntroCard extends StatelessWidget {
  const _CategoryIntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.textInverse.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: const Icon(
              Icons.category_outlined,
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
                  'Match cargo to capacity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Base prices are current starting estimates for selection.',
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final _CargoCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? category.accentColor : AppColors.border;
    final backgroundColor = isSelected
        ? category.accentColor.withValues(alpha: 0.08)
        : AppColors.surface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: borderColor, width: isSelected ? 1.6 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: category.accentColor.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: category.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Icon(category.icon, color: category.accentColor),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    category.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          key: const ValueKey('selected'),
                          color: category.accentColor,
                        )
                      : const Icon(
                          Icons.radio_button_unchecked_rounded,
                          key: ValueKey('unselected'),
                          color: AppColors.textSecondary,
                        ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              category.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _CardFact(
                    label: 'Base price',
                    value: category.basePrice,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _CardFact(
                    label: 'Vehicle',
                    value: category.vehicleSuggestion,
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

class _CardFact extends StatelessWidget {
  const _CardFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class _SelectedSummary extends StatelessWidget {
  const _SelectedSummary({required this.category});

  final _CargoCategory? category;

  @override
  Widget build(BuildContext context) {
    final selected = category;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            selected == null ? Icons.touch_app_outlined : selected.icon,
            color: selected?.accentColor ?? AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              selected == null
                  ? 'Select a cargo category to continue.'
                  : '${selected.title} selected • ${selected.basePrice} base • ${selected.vehicleSuggestion}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected == null
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontWeight: selected == null
                    ? FontWeight.w500
                    : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CargoCategory {
  const _CargoCategory({
    required this.code,
    required this.title,
    required this.description,
    required this.basePrice,
    required this.vehicleSuggestion,
    required this.icon,
    required this.accentColor,
  });

  factory _CargoCategory.fromApi(ShipmentCategory category) {
    return _CargoCategory(
      code: category.code,
      title: _categoryDisplayName(category.name),
      description: category.description,
      basePrice: _money(category.basePrice),
      vehicleSuggestion: _vehicleLabel(category.vehicleSuggestion),
      icon: _iconFor(category.iconKey, category.code),
      accentColor: _accentFor(category.code),
    );
  }

  final String code;
  final String title;
  final String description;
  final String basePrice;
  final String vehicleSuggestion;
  final IconData icon;
  final Color accentColor;
}

String _categoryDisplayName(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) {
    return 'Shipment';
  }

  return normalized[0].toUpperCase() + normalized.substring(1);
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

IconData _iconFor(String iconKey, String code) {
  final key = iconKey.isEmpty ? code : iconKey;
  return switch (key) {
    'package-small' || 'small_parcel' => Icons.inventory_2_outlined,
    'boxes' || 'medium_goods' => Icons.local_shipping_outlined,
    'container' || 'heavy_cargo' => Icons.fire_truck_outlined,
    'snowflake' || 'refrigerated' => Icons.ac_unit_rounded,
    'shield-alert' || 'fragile' => Icons.wine_bar_outlined,
    'zap' || 'urgent' => Icons.bolt_rounded,
    _ => Icons.category_outlined,
  };
}

Color _accentFor(String code) {
  return switch (code) {
    'small_parcel' => AppColors.info,
    'medium_goods' => AppColors.primaryBlue,
    'heavy_cargo' => AppColors.primaryNavy,
    'refrigerated' => const Color(0xFF0891B2),
    'fragile' => AppColors.warning,
    'urgent' => AppColors.accentOrange,
    _ => AppColors.primaryBlue,
  };
}

String _money(double value) {
  final rounded = value.round().toString();
  if (rounded.length <= 3) {
    return 'INR $rounded';
  }

  final lastThree = rounded.substring(rounded.length - 3);
  var leading = rounded.substring(0, rounded.length - 3);
  final groups = <String>[];

  while (leading.length > 2) {
    groups.insert(0, leading.substring(leading.length - 2));
    leading = leading.substring(0, leading.length - 2);
  }

  if (leading.isNotEmpty) {
    groups.insert(0, leading);
  }

  return 'INR ${[...groups, lastThree].join(',')}';
}
