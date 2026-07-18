import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/driver_auth_controller.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/emergency/breakdown_report_screen.dart';
import '../../features/emergency/emergency_screen.dart';
import '../../features/fuel/fuel_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/profile/change_password_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/proof_upload/delivery_proof_screen.dart';
import '../../features/proof_upload/proof_upload_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/trips/complete_trip_screen.dart';
import '../../features/trips/in_transit_update_screen.dart';
import '../../features/trips/start_trip_screen.dart';
import '../../features/trips/trip_details_screen.dart';
import '../../features/trips/trips_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authController = ref.watch(driverAuthControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authController,
    redirect: (context, state) => _authRedirect(authController, state),
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppRoutes.splash),
      GoRoute(
        path: AppRoutes.splash,
        name: 'driverSplash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        name: 'driverAuth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'driverDashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.trips,
        name: 'driverTrips',
        builder: (context, state) => const TripsScreen(),
      ),
      GoRoute(
        path: AppRoutes.tripDetails,
        name: 'driverTripDetails',
        builder: (context, state) => TripDetailsScreen(
          shipmentId:
              state.uri.queryParameters['assignmentId'] ??
              state.uri.queryParameters['shipmentId'] ??
              'CC-24061',
        ),
      ),
      GoRoute(
        path: AppRoutes.startTrip,
        name: 'driverStartTrip',
        builder: (context, state) => StartTripScreen(
          shipmentId:
              state.uri.queryParameters['assignmentId'] ??
              state.uri.queryParameters['shipmentId'] ??
              'CC-24052',
        ),
      ),
      GoRoute(
        path: AppRoutes.inTransitUpdate,
        name: 'driverInTransitUpdate',
        builder: (context, state) => InTransitUpdateScreen(
          shipmentId:
              state.uri.queryParameters['assignmentId'] ??
              state.uri.queryParameters['shipmentId'] ??
              'CC-24031',
        ),
      ),
      GoRoute(
        path: AppRoutes.completeTrip,
        name: 'driverCompleteTrip',
        builder: (context, state) => CompleteTripScreen(
          shipmentId:
              state.uri.queryParameters['assignmentId'] ??
              state.uri.queryParameters['shipmentId'] ??
              'CC-24031',
        ),
      ),
      GoRoute(
        path: AppRoutes.proofUpload,
        name: 'driverProofUpload',
        builder: (context, state) => ProofUploadScreen(
          shipmentId:
              state.uri.queryParameters['assignmentId'] ??
              state.uri.queryParameters['shipmentId'] ??
              'CC-24031',
        ),
      ),
      GoRoute(
        path: AppRoutes.deliveryProof,
        name: 'driverDeliveryProof',
        builder: (context, state) => DeliveryProofScreen(
          shipmentId:
              state.uri.queryParameters['assignmentId'] ??
              state.uri.queryParameters['shipmentId'] ??
              'CC-24031',
        ),
      ),
      GoRoute(
        path: AppRoutes.history,
        name: 'driverHistory',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.emergency,
        name: 'driverEmergency',
        builder: (context, state) => const EmergencyScreen(),
      ),
      GoRoute(
        path: AppRoutes.breakdownReport,
        name: 'driverBreakdownReport',
        builder: (context, state) => const BreakdownReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.fuel,
        name: 'driverFuel',
        builder: (context, state) => const FuelScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'driverProfile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        name: 'driverChangePassword',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
    ],
  );
});

const Set<String> _publicRoutes = {
  '/',
  AppRoutes.splash,
  AppRoutes.auth,
};

String? _authRedirect(
  DriverAuthController authController,
  GoRouterState state,
) {
  if (authController.isInitializing) {
    return null;
  }

  final location = state.matchedLocation;
  final isPublicRoute = _publicRoutes.contains(location);

  if (!authController.isAuthenticated && !isPublicRoute) {
    final from = Uri.encodeComponent(state.uri.toString());
    return '${AppRoutes.auth}?from=$from';
  }

  if (authController.isAuthenticated && location == AppRoutes.auth) {
    final from = state.uri.queryParameters['from'];
    if (from != null &&
        from.startsWith('/') &&
        !_publicRoutes.contains(Uri.parse(from).path)) {
      return from;
    }
    return AppRoutes.dashboard;
  }

  return null;
}
