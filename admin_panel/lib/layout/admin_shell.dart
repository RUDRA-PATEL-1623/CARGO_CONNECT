import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/router/app_routes.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String get _title {
    if (widget.location == AppRoutes.notifications) {
      return 'Notifications';
    }
    if (widget.location == AppRoutes.driverCreate ||
        widget.location.startsWith('${AppRoutes.drivers}/')) {
      return widget.location.endsWith('/edit') ? 'Edit Driver' : 'Add Driver';
    }
    if (widget.location == AppRoutes.vehicleCreate ||
        widget.location.startsWith('${AppRoutes.vehicles}/')) {
      return widget.location.endsWith('/edit') ? 'Edit Vehicle' : 'Add Vehicle';
    }
    return adminNavigationItems
        .firstWhere(_isSelected, orElse: () => adminNavigationItems.first)
        .label;
  }

  bool _isSelected(AdminNavItem item) {
    return widget.location == item.path ||
        widget.location.startsWith('${item.path}/');
  }

  void _navigate(String path) {
    if (widget.location != path) {
      context.go(path);
    }
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasSidebar = constraints.maxWidth >= 900;
        final isExpandedSidebar = constraints.maxWidth >= 1280;
        final sidebarWidth = isExpandedSidebar ? AppSpacing.sidebarWidth : 84.0;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          drawer: hasSidebar
              ? null
              : Drawer(
                  width: AppSpacing.sidebarWidth,
                  child: AdminSidebar(
                    location: widget.location,
                    compact: false,
                    onNavigate: _navigate,
                  ),
                ),
          body: Row(
            children: [
              if (hasSidebar)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: sidebarWidth,
                  child: AdminSidebar(
                    location: widget.location,
                    compact: !isExpandedSidebar,
                    onNavigate: _navigate,
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    AdminTopBar(
                      title: _title,
                      showMenuButton: !hasSidebar,
                      onMenuPressed: () =>
                          _scaffoldKey.currentState?.openDrawer(),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(
                          constraints.maxWidth < 640
                              ? AppSpacing.md
                              : AppSpacing.pagePadding,
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppSpacing.maxContentWidth,
                            ),
                            child: widget.child,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.location,
    required this.compact,
    required this.onNavigate,
  });

  final String location;
  final bool compact;
  final ValueChanged<String> onNavigate;

  bool _isSelected(AdminNavItem item) {
    return location == item.path || location.startsWith('${item.path}/');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryNavy,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AdminBrand(compact: compact),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView.separated(
                  itemCount: adminNavigationItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final item = adminNavigationItems[index];
                    final selected = _isSelected(item);

                    return _SidebarItem(
                      item: item,
                      selected: selected,
                      compact: compact,
                      onTap: () => onNavigate(item.path),
                    );
                  },
                ),
              ),
              _SidebarFooter(compact: compact),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminBrand extends StatelessWidget {
  const _AdminBrand({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.roadYellow,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: const Icon(
        Icons.local_shipping_rounded,
        color: AppColors.primaryNavy,
      ),
    );

    if (compact) {
      return Center(
        child: Tooltip(message: 'CargoConnect Admin Panel', child: mark),
      );
    }

    return Row(
      children: [
        mark,
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Column(
              key: const ValueKey('expanded-brand'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CargoConnect',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                Text(
                  'Admin Panel',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.surfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final AdminNavItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final itemContent = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.textInverse.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: selected
              ? AppColors.roadYellow.withValues(alpha: 0.28)
              : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  item.icon,
                  color: selected
                      ? AppColors.roadYellow
                      : AppColors.surfaceMuted,
                ),
                if (!compact) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textInverse,
                        fontWeight: selected
                            ? FontWeight.w900
                            : FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (compact) {
      return Tooltip(message: item.label, child: itemContent);
    }

    return itemContent;
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Tooltip(
        message: 'Backend APIs connected. Operations data is live.',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.textInverse.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: const Icon(
            Icons.storage_outlined,
            color: AppColors.surfaceMuted,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.textInverse.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Text(
        'Backend APIs connected\nOperations data live',
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: AppColors.surfaceMuted),
      ),
    );
  }
}

class AdminTopBar extends StatelessWidget {
  const AdminTopBar({
    super.key,
    required this.title,
    required this.showMenuButton,
    required this.onMenuPressed,
  });

  final String title;
  final bool showMenuButton;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hideSubtitle = constraints.maxWidth < 520;

        return Container(
          height: AppSpacing.topBarHeight,
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth < 640
                ? AppSpacing.md
                : AppSpacing.lg,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              if (showMenuButton) ...[
                IconButton(
                  tooltip: 'Open navigation',
                  onPressed: onMenuPressed,
                  icon: const Icon(Icons.menu_rounded),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (!hideSubtitle)
                      Text(
                        'Operations control center',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => context.go(AppRoutes.notifications),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              const SizedBox(width: AppSpacing.sm),
              Tooltip(
                message: 'Admin profile',
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => context.go(AppRoutes.profile),
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.surfaceMuted,
                      child: Text('AD'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
