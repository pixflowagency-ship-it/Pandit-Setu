import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pandit_ssetu/widgets/handmade_kundli_order_modal.dart';
import 'package:pandit_ssetu/widgets/pandit_chat_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HandmadeKundliOrderModal Tests', () {
    Widget buildKundliModal() {
      return const MaterialApp(
        home: Scaffold(
          body: HandmadeKundliOrderModal(),
        ),
      );
    }

    testWidgets('1. Renders HandmadeKundliOrderModal with SARV MANGAL branding and form fields', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildKundliModal());
      await tester.pumpAndSettle();

      expect(find.textContaining('SARV MANGAL'), findsOneWidget);
      expect(find.textContaining('Handmade Kundali Details'), findsOneWidget);
      expect(find.textContaining('TRADITIONAL'), findsOneWidget);

      final proceedBtn = find.textContaining('Proceed to Review Details');
      await tester.scrollUntilVisible(proceedBtn, 100, scrollable: find.byType(Scrollable).first);
      expect(proceedBtn, findsOneWidget);
    });

    testWidgets('2. Advances to Review step and displays service notice with disabled order button', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildKundliModal());
      await tester.pumpAndSettle();

      final proceedBtn = find.textContaining('Proceed to Review Details');
      await tester.scrollUntilVisible(proceedBtn, 100, scrollable: find.byType(Scrollable).first);
      expect(proceedBtn, findsOneWidget);
      await tester.tap(proceedBtn);
      await tester.pumpAndSettle();

      // Verify that review screen displays service notice and genuine submission button
      expect(find.text('Review Birth Details'), findsOneWidget);
      expect(find.text('Online Ordering Unavailable'), findsOneWidget);
      expect(find.textContaining('Submit Kundli Request • ₹1,501'), findsOneWidget);

      // Verify that fake allotment and fake Pandit do not exist
      expect(find.textContaining('Pt. Rameshwar Sharma Shastri'), findsNothing);
      expect(find.textContaining('#SMG-HK-8842'), findsNothing);
    });
  });

  group('PanditChatModal Tests', () {
    Widget buildChatModal() {
      return const MaterialApp(
        home: Scaffold(
          body: PanditChatModal(),
        ),
      );
    }

    testWidgets('1. Renders Vedic Guidance Assistant with AUTOMATED badge and honest welcome', (tester) async {
      await tester.pumpWidget(buildChatModal());
      await tester.pumpAndSettle();

      expect(find.text('Vedic Guidance Assistant'), findsOneWidget);
      expect(find.text('AUTOMATED'), findsOneWidget);
      expect(find.textContaining('SARV MANGAL Vedic Guidance Guide'), findsOneWidget);
    });

    testWidgets('2. Provides automated guidance on marriage topic without crashing', (tester) async {
      await tester.pumpWidget(buildChatModal());
      await tester.pumpAndSettle();

      final topicChip = find.textContaining('Marriage & Kundli Dosha');
      expect(topicChip, findsOneWidget);
      await tester.tap(topicChip);
      await tester.pump();

      // Wait for 1200ms simulated response
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();

      expect(find.textContaining('Manglik Dosh'), findsOneWidget);
    });
  });
}
