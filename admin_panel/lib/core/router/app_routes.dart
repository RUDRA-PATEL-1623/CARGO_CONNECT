import 'package:flutter/material.dart';

class AppRoutes {
  const AppRoutes._();

  static const String auth = '/auth';
  static const String dashboard = '/dashboard';
  static const String notifications = '/notifications';
  static const String shipments = '/shipments';
  static const String shipmentAssignment = '/shipments/assign';
  static const String shipmentDetailsPattern = '/shipments/:shipmentId';
  static const String drivers = '/drivers';
  static const String driverCreate = '/drivers/new';
  static const String driverEditPattern = '/drivers/:driverId/edit';
  static const String vehicles = '/vehicles';
  static const String vehicleCreate = '/vehicles/new';
  static const String vehicleEditPattern = '/vehicles/:vehicleId/edit';
  static const String customers = '/customers';
  static const String payments = '/payments';
  static const String invoices = '/invoices';
  static const String reports = '/reports';
  static const String shipmentReports = '/reports/shipments';
  static const String driverReports = '/reports/drivers';
  static const String paymentReports = '/reports/payments';
  static const String vehicleReports = '/reports/vehicles';
  static const String settings = '/settings';
  static const String profile = '/profile';

  static String shipmentAssignmentFor(String shipmentId) {
    return '$shipmentAssignment?shipmentId=$shipmentId';
  }

  static String shipmentDetails(String shipmentId) => '$shipments/$shipmentId';

  static String driverEdit(String driverId) => '$drivers/$driverId/edit';

  static String vehicleEdit(String vehicleId) => '$vehicles/$vehicleId/edit';
}

class AdminNavItem {
  const AdminNavItem({
    required this.label,
    required this.path,
    required this.icon,
  });

  final String label;
  final String path;
  final IconData icon;
}

const adminNavigationItems = [
  AdminNavItem(
    label: 'Dashboard',
    path: AppRoutes.dashboard,
    icon: Icons.dashboard_outlined,
  ),
  AdminNavItem(
    label: 'Shipments',
    path: AppRoutes.shipments,
    icon: Icons.inventory_2_outlined,
  ),
  AdminNavItem(
    label: 'Drivers',
    path: AppRoutes.drivers,
    icon: Icons.badge_outlined,
  ),
  AdminNavItem(
    label: 'Vehicles',
    path: AppRoutes.vehicles,
    icon: Icons.local_shipping_outlined,
  ),
  AdminNavItem(
    label: 'Customers',
    path: AppRoutes.customers,
    icon: Icons.people_outline,
  ),
  AdminNavItem(
    label: 'Payments',
    path: AppRoutes.payments,
    icon: Icons.payments_outlined,
  ),
  AdminNavItem(
    label: 'Invoices',
    path: AppRoutes.invoices,
    icon: Icons.receipt_long_outlined,
  ),
  AdminNavItem(
    label: 'Reports',
    path: AppRoutes.reports,
    icon: Icons.insights_outlined,
  ),
  AdminNavItem(
    label: 'Settings',
    path: AppRoutes.settings,
    icon: Icons.settings_outlined,
  ),
  AdminNavItem(
    label: 'Profile',
    path: AppRoutes.profile,
    icon: Icons.person_outline,
  ),
];
