import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_screen.dart';
import '../../features/auth/data/admin_auth_controller.dart';
import '../../features/customers/customers_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/drivers/driver_form_screen.dart';
import '../../features/drivers/drivers_screen.dart';
import '../../features/invoices/invoices_screen.dart';
import '../../features/notifications/admin_notifications_screen.dart';
import '../../features/payments/payments_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/reports/driver_reports_screen.dart';
import '../../features/reports/payment_reports_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/reports/shipment_reports_screen.dart';
import '../../features/reports/vehicle_reports_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shipments/shipment_assignment_screen.dart';
import '../../features/shipments/shipment_details_screen.dart';
import '../../features/shipments/shipments_screen.dart';
import '../../features/vehicles/vehicle_form_screen.dart';
import '../../features/vehicles/vehicles_screen.dart';
import '../../layout/admin_shell.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authController = ref.watch(adminAuthControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.auth,
    refreshListenable: authController,
    redirect: (context, state) => _authRedirect(authController, state),
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => authController.isAuthenticated
            ? AppRoutes.dashboard
            : AppRoutes.auth,
      ),
      GoRoute(
        path: AppRoutes.auth,
        name: 'adminAuth',
        builder: (context, state) => const AuthScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AdminShell(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'adminDashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            name: 'adminNotifications',
            builder: (context, state) => const AdminNotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.shipments,
            name: 'adminShipments',
            builder: (context, state) => const ShipmentsScreen(),
          ),
          GoRoute(
            path: AppRoutes.shipmentAssignment,
            name: 'adminShipmentAssignment',
            builder: (context, state) => ShipmentAssignmentScreen(
              initialShipmentId: state.uri.queryParameters['shipmentId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.shipmentDetailsPattern,
            name: 'adminShipmentDetails',
            builder: (context, state) => ShipmentDetailsScreen(
              shipmentId: state.pathParameters['shipmentId'] ?? '',
            ),
          ),
          GoRoute(
            path: AppRoutes.drivers,
            name: 'adminDrivers',
            builder: (context, state) => const DriversScreen(),
          ),
          GoRoute(
            path: AppRoutes.driverCreate,
            name: 'adminDriverCreate',
            builder: (context, state) => const DriverFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.driverEditPattern,
            name: 'adminDriverEdit',
            builder: (context, state) => DriverFormScreen(
              driverId: state.pathParameters['driverId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.vehicles,
            name: 'adminVehicles',
            builder: (context, state) => const VehiclesScreen(),
          ),
          GoRoute(
            path: AppRoutes.vehicleCreate,
            name: 'adminVehicleCreate',
            builder: (context, state) => const VehicleFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.vehicleEditPattern,
            name: 'adminVehicleEdit',
            builder: (context, state) => VehicleFormScreen(
              vehicleId: state.pathParameters['vehicleId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.customers,
            name: 'adminCustomers',
            builder: (context, state) => const CustomersScreen(),
          ),
          GoRoute(
            path: AppRoutes.payments,
            name: 'adminPayments',
            builder: (context, state) => const PaymentsScreen(),
          ),
          GoRoute(
            path: AppRoutes.invoices,
            name: 'adminInvoices',
            builder: (context, state) => const InvoicesScreen(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            name: 'adminReports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.shipmentReports,
            name: 'adminShipmentReports',
            builder: (context, state) => const ShipmentReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.driverReports,
            name: 'adminDriverReports',
            builder: (context, state) => const DriverReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.paymentReports,
            name: 'adminPaymentReports',
            builder: (context, state) => const PaymentReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.vehicleReports,
            name: 'adminVehicleReports',
            builder: (context, state) => const VehicleReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'adminSettings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'adminProfile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

String? _authRedirect(AdminAuthController authController, GoRouterState state) {
  if (authController.isInitializing) {
    return null;
  }

  final isAuthRoute = state.matchedLocation == AppRoutes.auth;
  if (!authController.isAuthenticated) {
    if (isAuthRoute) {
      return null;
    }

    final from = Uri.encodeComponent(state.uri.toString());
    return '${AppRoutes.auth}?from=$from';
  }

  if (isAuthRoute) {
    final from = state.uri.queryParameters['from'];
    if (from != null &&
        from.startsWith('/') &&
        !from.startsWith(AppRoutes.auth)) {
      return from;
    }
    return AppRoutes.dashboard;
  }

  return null;
}
