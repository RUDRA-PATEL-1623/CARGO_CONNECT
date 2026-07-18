import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/customer_auth_controller.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/create_password_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/otp_verification_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/invoice/invoice_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/payment/order_confirmation_screen.dart';
import '../../features/payment/payment_screen.dart';
import '../../features/profile/change_password_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/shipment/create_shipment_screen.dart';
import '../../features/shipment/shipment_details_screen.dart';
import '../../features/shipment/shipment_history_screen.dart';
import '../../features/shipment/shipment_proof_viewer_screen.dart';
import '../../features/shipment/shipment_proof_screen.dart';
import '../../features/shipment/shipment_screen.dart';
import '../../features/shipment/shipment_summary_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/support/feedback_screen.dart';
import '../../features/support/support_screen.dart';
import '../../features/tracking/timeline_screen.dart';
import '../../features/tracking/tracking_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authController = ref.watch(customerAuthControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authController,
    redirect: (context, state) => _authRedirect(authController, state),
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppRoutes.splash),
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        name: 'otpVerification',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          final editRoute = switch (query['edit']) {
            'forgot-password' => AppRoutes.forgotPassword,
            _ => AppRoutes.register,
          };
          return OtpVerificationScreen(
            destination: query['destination'] ?? 'aarav.mehta@example.com',
            next: OtpVerificationNext.fromQuery(query['next']),
            editRoute: editRoute,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.createPassword,
        name: 'createPassword',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return CreatePasswordScreen(
            identifier: query['identifier'],
            resetToken: query['resetToken'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.shipment,
        name: 'shipment',
        builder: (context, state) => const ShipmentScreen(),
      ),
      GoRoute(
        path: AppRoutes.shipmentHistory,
        name: 'shipmentHistory',
        builder: (context, state) => const ShipmentHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.shipmentDetails,
        name: 'shipmentDetails',
        builder: (context, state) => ShipmentDetailsScreen(
          shipmentId: state.uri.queryParameters['shipmentId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.shipmentProof,
        name: 'shipmentProof',
        builder: (context, state) => ShipmentProofScreen(
          shipmentId: state.uri.queryParameters['shipmentId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.shipmentProofViewer,
        name: 'shipmentProofViewer',
        builder: (context, state) => ShipmentProofViewerScreen(
          shipmentId: state.uri.queryParameters['shipmentId'] ?? '',
          proofId: int.tryParse(state.uri.queryParameters['proofId'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.shipmentTimeline,
        name: 'shipmentTimeline',
        builder: (context, state) => ShipmentTimelineScreen(
          shipmentId: state.uri.queryParameters['shipmentId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.createShipment,
        name: 'createShipment',
        builder: (context, state) => CreateShipmentScreen(
          initialPackageType: state.uri.queryParameters['category'],
          initialCategoryCode: state.uri.queryParameters['categoryCode'],
        ),
      ),
      GoRoute(
        path: AppRoutes.shipmentSummary,
        name: 'shipmentSummary',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return ShipmentSummaryScreen(
            shipmentId: query['shipmentId'] ?? '',
            packageType: query['packageType'] ?? 'Medium goods',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.payment,
        name: 'payment',
        builder: (context, state) =>
            PaymentScreen(shipmentId: state.uri.queryParameters['shipmentId']),
      ),
      GoRoute(
        path: AppRoutes.orderConfirmation,
        name: 'orderConfirmation',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return OrderConfirmationScreen(
            bookingId: query['bookingId'] ?? 'Shipment booked',
            estimatedPickup: _formatRouteDateTime(query['pickup']),
            shipmentId: query['shipmentId'],
            invoiceId: query['invoiceId'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.invoice,
        name: 'invoice',
        builder: (context, state) =>
            InvoiceScreen(invoiceId: state.uri.queryParameters['invoiceId']),
      ),
      GoRoute(
        path: AppRoutes.tracking,
        name: 'tracking',
        builder: (context, state) =>
            TrackingScreen(shipmentId: state.uri.queryParameters['shipmentId']),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        name: 'changePassword',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.support,
        name: 'support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.feedback,
        name: 'feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
    ],
  );
});

const Set<String> _publicRoutes = {
  '/',
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.auth,
  AppRoutes.forgotPassword,
  AppRoutes.register,
  AppRoutes.otpVerification,
  AppRoutes.createPassword,
};

String? _authRedirect(
  CustomerAuthController authController,
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
    return AppRoutes.home;
  }

  return null;
}

String _formatRouteDateTime(String? value) {
  final parsed = DateTime.tryParse(value ?? '');
  if (parsed == null) {
    return 'Pickup slot pending';
  }

  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final year = parsed.year.toString();
  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final period = parsed.hour >= 12 ? 'PM' : 'AM';
  return '$day/$month/$year, $hour:$minute $period';
}
