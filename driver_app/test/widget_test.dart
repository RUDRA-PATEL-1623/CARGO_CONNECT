import 'package:driver_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders splash, validates login, and opens dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DriverApp()));

    expect(find.text('CargoConnect Driver'), findsOneWidget);
    expect(find.text('Move every shipment with confidence.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.text('Driver login'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    await tester.tap(find.text('Login'));
    await tester.pump();
    expect(find.text('Enter your driver username'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).at(0), 'driver.ops');
    await tester.enterText(find.byType(EditableText).at(1), 'driver123');
    await tester.tap(find.text('Login'));
    await tester.pump();
    expect(find.text('Signing in...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();

    expect(find.text('Driver dashboard'), findsOneWidget);
    expect(find.text('CargoConnect Driver'), findsOneWidget);
    expect(find.text('Today\'s route'), findsOneWidget);
  });
}
