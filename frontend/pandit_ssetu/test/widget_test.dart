// This is a basic Flutter widget test for Pandit Setu.

import 'package:flutter_test/flutter_test.dart';
import 'package:pandit_ssetu/main.dart';

void main() {
  testWidgets('Splash Screen renders title and subtitle, then navigates to Role Selection', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PanditSetuApp());

    // Verify that the title 'Pandit Setu' and subtitle are displayed.
    expect(find.text('Pandit Setu'), findsOneWidget);
    expect(find.text('connecting pandits with yajmans'), findsOneWidget);

    // Pump to trigger animation and let the 2-second timer fire.
    await tester.pump(const Duration(seconds: 2));
    // Let the GoRouter transition and the new page build/settle.
    await tester.pumpAndSettle();

    // Verify that we are now on the Role Selection Screen.
    expect(find.text('SELECT PROFILE'), findsOneWidget);
  });
}
