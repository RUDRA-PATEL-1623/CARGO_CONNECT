import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_panel/core/theme/app_theme.dart';
import 'package:admin_panel/features/customers/customers_screen.dart';
import 'package:admin_panel/features/drivers/drivers_screen.dart';
import 'package:admin_panel/features/invoices/invoices_screen.dart';
import 'package:admin_panel/features/payments/payments_screen.dart';
import 'package:admin_panel/features/profile/profile_screen.dart';
import 'package:admin_panel/features/reports/driver_reports_screen.dart';
import 'package:admin_panel/features/reports/payment_reports_screen.dart';
import 'package:admin_panel/features/reports/reports_screen.dart';
import 'package:admin_panel/features/reports/shipment_reports_screen.dart';
import 'package:admin_panel/features/reports/vehicle_reports_screen.dart';
import 'package:admin_panel/features/settings/settings_screen.dart';
import 'package:admin_panel/features/shipments/shipment_assignment_screen.dart';
import 'package:admin_panel/features/shipments/shipment_details_screen.dart';
import 'package:admin_panel/features/shipments/shipments_screen.dart';
import 'package:admin_panel/features/vehicles/vehicles_screen.dart';
import 'package:admin_panel/main.dart';

void main() {
  testWidgets('renders admin login and mock navigates to dashboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CargoConnectAdminApp());
    await tester.pump();

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Email or username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'admin@cargoconnect.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secure123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Signing in...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    expect(find.text('Operations dashboard'), findsOneWidget);
    expect(find.text('Total shipments'), findsOneWidget);
    expect(find.text('Vehicle utilization'), findsWidgets);
    expect(find.text('Recent activity'), findsOneWidget);
  });

  testWidgets('renders shipment management list screen', (tester) async {
    tester.view.physicalSize = const Size(1440, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: ShipmentsScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Shipment management'), findsOneWidget);
    expect(find.text('Status filters'), findsOneWidget);
    expect(find.text('Approve selected'), findsOneWidget);
    expect(find.text('CC-24061'), findsWidgets);
  });

  testWidgets('renders shipment details screen', (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: ShipmentDetailsScreen(shipmentId: 'CC-24061'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('CC-24061'), findsWidgets);
    expect(find.text('Customer and receiver'), findsOneWidget);
    expect(find.text('Pickup and delivery'), findsOneWidget);
    expect(find.text('Payment and invoice'), findsOneWidget);
    expect(find.text('Current status timeline'), findsOneWidget);
    expect(find.text('Proof placeholders'), findsOneWidget);
    expect(find.text('Admin actions'), findsOneWidget);

    final rejectButton = find.widgetWithText(OutlinedButton, 'Reject');
    await tester.ensureVisible(rejectButton);
    await tester.pump();
    await tester.tap(rejectButton);
    await tester.pump();

    expect(find.text('Reject shipment'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Reject'));
    await tester.pump();

    expect(find.text('Select a reason'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pump();

    final approveButton = find.widgetWithText(ElevatedButton, 'Approve');
    await tester.ensureVisible(approveButton);
    await tester.pump();
    await tester.tap(approveButton);
    await tester.pump();

    expect(find.text('Approve shipment'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Ready for dispatch.');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Approve').last);
    await tester.pump();

    expect(find.text('Approved'), findsWidgets);
  });

  testWidgets('renders assignment UI and prevents double assignment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: ShipmentAssignmentScreen(initialShipmentId: 'CC-24044'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Shipment assignment'), findsOneWidget);
    expect(find.text('Available driver list'), findsOneWidget);
    expect(find.text('Available vehicle list'), findsOneWidget);
    expect(find.text('Select an available driver.'), findsOneWidget);
    expect(find.text('Select an available vehicle.'), findsOneWidget);

    await tester.tap(find.text('Rohit Kulkarni'));
    await tester.pump();
    await tester.tap(find.text('Mini Truck B07'));
    await tester.pump();

    final confirmButton = find.widgetWithText(
      ElevatedButton,
      'Confirm assignment',
    );
    await tester.ensureVisible(confirmButton);
    await tester.pump();
    await tester.tap(confirmButton.first);
    await tester.pump();

    expect(find.text('Confirm assignment CC-24044'), findsOneWidget);

    await tester.tap(confirmButton.last);
    await tester.pump();

    expect(
      find.text('Mock assignment exists: Rohit Kulkarni with Mini Truck B07.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('CC-24044 already has an active assignment'),
      findsOneWidget,
    );
  });

  testWidgets('renders driver management list and validates create driver', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: DriversScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loading driver roster...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Driver management'), findsOneWidget);
    expect(find.text('Status filter'), findsOneWidget);
    expect(find.text('Availability'), findsWidgets);
    expect(find.text('Available now'), findsOneWidget);
    expect(find.text('Amit Verma'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('driver-availability-All availability')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('On Trip').last);
    await tester.pumpAndSettle();

    expect(find.text('Farhan Ali'), findsWidgets);
    expect(find.text('Pooja Soman'), findsWidgets);
    expect(find.text('Sana Sheikh'), findsNothing);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create driver'));
    await tester.pumpAndSettle();

    expect(find.text('Create driver'), findsWidgets);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Generated password'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('License expiry'), findsOneWidget);
    expect(find.text('Address'), findsOneWidget);
    expect(find.text('Availability status'), findsOneWidget);
    expect(find.text('Active status'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create driver').last);
    await tester.pump();

    expect(find.text('Enter the driver name'), findsOneWidget);
    expect(find.text('Enter the username'), findsOneWidget);
    expect(find.text('Enter the email address'), findsOneWidget);
    expect(find.text('Enter the phone number'), findsOneWidget);
    expect(find.text('Enter the license number'), findsOneWidget);
    expect(find.text('Enter the driver address'), findsOneWidget);
  });

  testWidgets('renders vehicle management list screen', (tester) async {
    tester.view.physicalSize = const Size(2400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: VehiclesScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loading fleet inventory...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Vehicle management'), findsOneWidget);
    expect(find.text('Fleet size'), findsOneWidget);
    expect(find.text('Vehicle number'), findsOneWidget);
    expect(find.text('Type / capacity'), findsOneWidget);
    expect(find.text('Registration'), findsOneWidget);
    expect(find.text('Service due'), findsOneWidget);
    expect(find.text('Assigned driver / trip'), findsOneWidget);
    expect(find.text('CC-PV-A12'), findsWidgets);
    expect(find.text('MH 04 HX 2210'), findsWidgets);
    expect(find.widgetWithText(ElevatedButton, 'Add vehicle'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'View'), findsWidgets);
    expect(find.widgetWithText(TextButton, 'Edit'), findsWidgets);
    expect(find.widgetWithText(TextButton, 'Assign'), findsWidgets);
    expect(find.widgetWithText(TextButton, 'Service'), findsWidgets);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Add vehicle'));
    await tester.pumpAndSettle();

    expect(find.text('Registration number'), findsOneWidget);
    expect(find.text('Type'), findsOneWidget);
    expect(find.text('Capacity'), findsOneWidget);
    expect(find.text('Model'), findsOneWidget);
    expect(find.text('Fuel type'), findsOneWidget);
    expect(find.text('Insurance expiry'), findsOneWidget);
    expect(find.text('Service due date'), findsOneWidget);
    expect(find.text('Availability'), findsWidgets);
    expect(find.text('Notes'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Add vehicle').last);
    await tester.pump();

    expect(find.text('Enter the registration number'), findsOneWidget);
    expect(find.text('Enter the vehicle capacity'), findsOneWidget);
    expect(find.text('Enter the vehicle model'), findsOneWidget);
    expect(find.text('Enter vehicle notes'), findsOneWidget);
  });

  testWidgets('renders customer management list and details modal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: CustomersScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loading customer directory...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Customer management'), findsOneWidget);
    expect(find.text('Total customers'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Total shipments'), findsWidgets);
    expect(find.text('Registered date'), findsOneWidget);
    expect(find.text('Priya Menon'), findsWidgets);
    expect(find.text('priya.menon@example.com'), findsWidgets);
    expect(find.widgetWithText(TextButton, 'View'), findsWidgets);
    expect(find.widgetWithText(TextButton, 'Deactivate'), findsWidgets);
    expect(find.widgetWithText(TextButton, 'Activate'), findsWidgets);

    await tester.tap(find.widgetWithText(TextButton, 'View').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('details'), findsOneWidget);
    expect(find.text('Customer profile'), findsOneWidget);
    expect(find.text('Shipment summary'), findsOneWidget);
    expect(find.text('Account activity'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Close'));
    await tester.pump();
  });

  testWidgets('renders payment management list and details modal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: PaymentsScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loading payment ledger...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Payment management'), findsOneWidget);
    expect(find.text('Total payments'), findsOneWidget);
    expect(find.text('Payment ID'), findsOneWidget);
    expect(find.text('Shipment ID'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Method'), findsWidgets);
    expect(find.text('Status'), findsWidgets);
    expect(find.text('Date'), findsWidgets);
    expect(find.text('PAY-24061'), findsWidgets);
    expect(find.text('CC-24061'), findsWidgets);
    expect(find.text('UPI'), findsWidgets);
    expect(find.widgetWithText(TextButton, 'View'), findsWidgets);
    expect(find.widgetWithText(TextButton, 'Reconcile'), findsWidgets);

    await tester.tap(find.widgetWithText(TextButton, 'View').first);
    await tester.pumpAndSettle();

    expect(find.text('Payment details'), findsOneWidget);
    expect(find.text('Payment record'), findsOneWidget);
    expect(find.text('Amount and method'), findsOneWidget);
    expect(find.text('Reconciliation'), findsOneWidget);
    expect(find.text('Transaction reference'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Close'));
    await tester.pump();
  });

  testWidgets('renders invoice management list and preview modal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: InvoicesScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loading invoice register...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Invoice management'), findsOneWidget);
    expect(find.text('Total invoices'), findsOneWidget);
    expect(find.text('Invoice number'), findsOneWidget);
    expect(find.text('Shipment ID'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Payment status'), findsWidgets);
    expect(find.text('Generated date'), findsWidgets);
    expect(find.text('INV-24061'), findsWidgets);
    expect(find.text('CC-24061'), findsWidgets);
    expect(find.widgetWithText(TextButton, 'View'), findsWidgets);
    expect(find.widgetWithText(TextButton, 'Download'), findsWidgets);

    await tester.tap(find.widgetWithText(TextButton, 'View').first);
    await tester.pumpAndSettle();

    expect(find.text('Invoice preview'), findsOneWidget);
    expect(find.text('CargoConnect'), findsOneWidget);
    expect(find.text('Company'), findsOneWidget);
    expect(find.text('Bill to'), findsOneWidget);
    expect(find.text('Shipment'), findsOneWidget);
    expect(find.text('Charge breakdown'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Download PDF'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Close'));
    await tester.pump();
  });

  testWidgets('renders reports dashboard filters charts and exports', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: ReportsScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loading reports dashboard...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Reports dashboard'), findsOneWidget);
    expect(find.text('Export PDF'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Date range'), findsOneWidget);
    expect(find.text('Status'), findsWidgets);
    expect(find.text('Shipment report'), findsWidgets);
    expect(find.text('Driver report'), findsWidgets);
    expect(find.text('Vehicle report'), findsWidgets);
    expect(find.text('Payment report'), findsWidgets);
    expect(find.text('Status distribution for Last 7 days'), findsOneWidget);
    expect(find.text('Collection mix in lakhs'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Export PDF'));
    await tester.pump();

    expect(
      find.text('PDF export queued for Last 7 days with All statuses.'),
      findsOneWidget,
    );
  });

  testWidgets('renders shipment reports screen tables charts and exports', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: ShipmentReportsScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loading shipment reports...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Shipment reports'), findsOneWidget);
    expect(find.text('Export PDF'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Date range'), findsOneWidget);
    expect(find.text('Status'), findsWidgets);
    expect(find.text('Category'), findsWidgets);
    expect(find.text('Total bookings'), findsOneWidget);
    expect(find.text('Date-wise shipment report'), findsOneWidget);
    expect(find.text('Status-wise shipment report'), findsOneWidget);
    expect(find.text('Category-wise shipment report'), findsOneWidget);
    expect(find.text('Date-wise chart'), findsOneWidget);
    expect(find.text('Status-wise chart'), findsOneWidget);
    expect(find.text('Category-wise chart'), findsOneWidget);
    expect(find.text('Bookings'), findsOneWidget);
    expect(find.text('Average weight'), findsOneWidget);
    expect(find.text('Heavy Cargo'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Export PDF'));
    await tester.pump();

    expect(
      find.text(
        'PDF shipment report export queued for Last 7 days, All statuses, All categories.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders driver reports screen metrics charts and exports', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: DriverReportsScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loading driver reports...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Driver reports'), findsOneWidget);
    expect(find.text('Export PDF'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Date range'), findsOneWidget);
    expect(find.text('Status'), findsWidgets);
    expect(find.text('Zone'), findsWidgets);
    expect(find.text('Completed trips'), findsWidgets);
    expect(find.text('Acceptance rate'), findsWidgets);
    expect(find.text('Delays'), findsWidgets);
    expect(find.text('Performance score'), findsWidgets);
    expect(find.text('Emergency count'), findsWidgets);
    expect(find.text('Driver performance table'), findsOneWidget);
    expect(find.text('Amit Verma'), findsWidgets);
    expect(find.text('DRV-104'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Export PDF'));
    await tester.pump();

    expect(
      find.text(
        'PDF driver report export queued for Last 7 days, All statuses, All zones.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders payment reports screen summaries charts and exports', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: PaymentReportsScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loading payment reports...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Payment reports'), findsOneWidget);
    expect(find.text('Export PDF'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Date range'), findsOneWidget);
    expect(find.text('Status'), findsWidgets);
    expect(find.text('Payment method'), findsOneWidget);
    expect(find.text('Revenue summary'), findsWidgets);
    expect(find.text('Revenue trend'), findsOneWidget);
    expect(find.text('Payment methods'), findsWidgets);
    expect(find.text('Payment statuses'), findsWidgets);
    expect(find.text('Paid'), findsWidgets);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Refunded'), findsWidgets);
    expect(find.text('UPI'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Export PDF'));
    await tester.pump();

    expect(
      find.text(
        'PDF payment report export queued for Last 7 days, All statuses, All methods.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders vehicle reports screen metrics tables and exports', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: VehicleReportsScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loading vehicle reports...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Vehicle reports'), findsOneWidget);
    expect(find.text('Export PDF'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Date range'), findsOneWidget);
    expect(find.text('Availability'), findsWidgets);
    expect(find.text('Vehicle type'), findsOneWidget);
    expect(find.text('Utilization'), findsWidgets);
    expect(find.text('Service due'), findsWidgets);
    expect(find.text('Assignment history'), findsWidgets);
    expect(find.text('Breakdowns'), findsWidgets);
    expect(find.text('Vehicle utilization'), findsOneWidget);
    expect(find.text('Assigned driver / trip'), findsOneWidget);
    expect(find.text('CC-TR-T19'), findsWidgets);
    expect(find.text('Hydraulic lift calibration'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Export PDF'));
    await tester.pump();

    expect(
      find.text(
        'PDF vehicle report export queued for Last 7 days, All availability, All vehicle types.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders settings UI and validates mock save', (tester) async {
    tester.view.physicalSize = const Size(2400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: SettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loading admin settings...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Status master'), findsOneWidget);
    expect(find.text('Notification settings'), findsOneWidget);
    expect(find.text('App settings'), findsOneWidget);
    expect(find.text('Business rules'), findsOneWidget);
    expect(find.text('Default shipment status'), findsOneWidget);
    expect(find.text('Support email'), findsOneWidget);
    expect(find.text('Billing currency'), findsOneWidget);
    expect(find.text('Urgent shipment policy'), findsOneWidget);
    expect(find.byType(Switch), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Support email'),
      'invalid-email',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save settings').first);
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Support email'),
      'ops@cargoconnect.in',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save settings').first);
    await tester.pump();

    expect(find.text('Saving...'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(
      find.text('Mock settings saved for the admin panel.'),
      findsOneWidget,
    );
    expect(find.text('Saved locally'), findsOneWidget);
  });

  testWidgets('renders admin profile and validates account actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: ProfileScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loading admin profile...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Admin profile'), findsOneWidget);
    expect(find.text('Ananya Sharma'), findsOneWidget);
    expect(find.text('Super Admin'), findsOneWidget);
    expect(find.text('ananya.admin@cargoconnect.in'), findsOneWidget);
    expect(find.text('+91 98765 43210'), findsOneWidget);
    expect(find.text('Activity summary'), findsOneWidget);
    expect(find.text('Change password'), findsWidgets);
    expect(find.text('Logout'), findsWidgets);

    final changePasswordButton = find.widgetWithText(
      FilledButton,
      'Change password',
    );
    await tester.ensureVisible(changePasswordButton);
    await tester.pump();
    await tester.tap(changePasswordButton);
    await tester.pump();

    expect(find.text('Enter the current password'), findsOneWidget);
    expect(find.text('Enter the new password'), findsOneWidget);
    expect(find.text('Confirm the new password'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Current password'),
      'current123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New password'),
      'Secure123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'Secure123',
    );
    await tester.tap(changePasswordButton);
    await tester.pump();

    expect(find.text('Updating...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(find.text('Mock admin password updated.'), findsOneWidget);
    expect(find.text('Password updated'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Logout').first);
    await tester.pumpAndSettle();

    expect(find.text('Log out admin?'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(
      find.text('Mock logout requested for admin profile.'),
      findsOneWidget,
    );
  });
}
