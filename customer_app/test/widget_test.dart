import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:customer_app/main.dart';

void main() {
  testWidgets('renders splash then opens onboarding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CustomerApp()));

    expect(find.text('CargoConnect'), findsOneWidget);
    expect(find.text('Version 1.0.0'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump();

    expect(find.text('Book shipments easily'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}
