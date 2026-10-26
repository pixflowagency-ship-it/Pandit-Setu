import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pandit_ssetu/screens/admin_dashboard_screen.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: AdminDashboardScreen(),
    );
  }

  testWidgets('AdminDashboardScreen renders tabs and header title', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Verify title
    expect(find.text('SARV MANGAL Admin Desk'), findsOneWidget);

    // Verify Tab headers
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Pandit KYC'), findsOneWidget);
    expect(find.text('Subscriptions'), findsOneWidget);
    expect(find.text('Consultation Desk'), findsOneWidget);
    expect(find.text('Kundli Orders'), findsOneWidget);
  });

  testWidgets('AdminDashboardScreen tab navigation works and displays transparent desk notice',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Switch to Consultation Desk tab
    await tester.tap(find.text('Consultation Desk'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));

    // Verify transparent persistence notice
    expect(find.text('Live Vedic Consultation Desk'), findsOneWidget);
    expect(
      find.textContaining('Database Persistence Notice'),
      findsOneWidget,
    );
    expect(
      find.textContaining('no fabricated appointments'),
      findsOneWidget,
    );
    expect(find.text('+91 98765 43210 / +91 1800 123 7278'), findsOneWidget);

    // Verify consultation filters exist
    expect(find.text('All Requests'), findsOneWidget);
    expect(find.text('Requested'), findsAtLeast(1));

    // Switch to Kundli Orders tab
    await tester.tap(find.text('Kundli Orders'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));

    // Verify Kundli orders desk header and filters
    expect(find.text('Handmade Kundli Orders Desk'), findsOneWidget);
    expect(find.text('All Orders'), findsOneWidget);

    // Switch to Pandit KYC tab
    await tester.tap(find.text('Pandit KYC'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));

    // Verify filter chips exist
    expect(find.text('Pending Review'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);

    // Switch to Subscriptions tab
    await tester.tap(find.text('Subscriptions'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));

    // Verify subscription filters exist
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Created'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
  });
}
