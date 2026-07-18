import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../router/app_routes.dart';

class CustomerBottomNavigation extends StatelessWidget {
  const CustomerBottomNavigation({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.surfaceMuted,
      onDestinationSelected: (index) {
        if (index == selectedIndex) {
          return;
        }

        final route = switch (index) {
          0 => AppRoutes.home,
          1 => AppRoutes.shipment,
          2 => AppRoutes.tracking,
          _ => AppRoutes.profile,
        };
        context.go(route);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2_rounded),
          label: 'Shipments',
        ),
        NavigationDestination(
          icon: Icon(Icons.location_on_outlined),
          selectedIcon: Icon(Icons.location_on_rounded),
          label: 'Track',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
