import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pandit_ssetu/screens/phool_mala_screen.dart';
import 'package:pandit_ssetu/user_data.dart';
import 'package:pandit_ssetu/widgets/handmade_kundli_order_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SARV MANGAL Master UI Repair & Persistence Tests', () {
    testWidgets('1. Kundli Type Selector: Renders Patrika and Online Kundli options', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HandmadeKundliOrderModal()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select Your Kundli Type'), findsOneWidget);
      expect(find.text('Patrika'), findsOneWidget);
      expect(find.text('(32 Page Kundli)'), findsOneWidget);
      expect(find.text('Online Kundli'), findsOneWidget);
      expect(find.text('(Digital PDF Chart)'), findsOneWidget);

      // Tap on Online Kundli to change selection
      await tester.tap(find.text('Online Kundli'));
      await tester.pumpAndSettle();
    });

    testWidgets('2. Kundli Concern Categories: Hides custom text field on standard category, shows on Others', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HandmadeKundliOrderModal()),
        ),
      );
      await tester.pumpAndSettle();

      // Default category is Marriage & Kundli Dosha, custom concern text field must NOT be present
      expect(find.text('Select Your Concern'), findsOneWidget);
      expect(find.textContaining('Describe Your Specific Concern'), findsNothing);

      // Select 'Others' from dropdown
      final dropdown = find.byType(DropdownButtonFormField<String>).last;
      await tester.scrollUntilVisible(dropdown, 100, scrollable: find.byType(Scrollable).first);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Find 'Others' and tap it
      final othersOption = find.text('Others').last;
      await tester.tap(othersOption);
      await tester.pumpAndSettle();

      // Custom concern field is now revealed
      expect(find.textContaining('Describe Your Specific Concern'), findsOneWidget);

      // Attempt to proceed without entering custom concern -> blocked by validation SnackBar
      final proceedBtn = find.textContaining('Proceed to Review Details');
      await tester.scrollUntilVisible(proceedBtn, 100, scrollable: find.byType(Scrollable).first);
      await tester.tap(proceedBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please describe your specific concern before proceeding.'), findsOneWidget);
      // Still on step 0
      expect(find.text('Review Birth Details'), findsNothing);

      // Enter custom concern text
      final customConcernInput = find.byType(TextField).last;
      await tester.enterText(customConcernInput, 'Need guidance on career transitions and auspicious muhurat');
      await tester.pumpAndSettle();

      // Proceed to review
      await tester.tap(proceedBtn);
      await tester.pumpAndSettle();

      // Successfully reached Review Details step!
      expect(find.text('Review Birth Details'), findsOneWidget);
      expect(find.text('Kundli Type'), findsOneWidget);
      expect(find.text('Patrika (32 Page Kundli)'), findsOneWidget);
      expect(find.text('Concern Area'), findsOneWidget);
      expect(find.text('Others'), findsWidgets);
      expect(find.text('Need guidance on career transitions and auspicious muhurat'), findsOneWidget);
    });

    testWidgets('3. Phool Mala Store: Festive subscription offer fits on screen with price and Subscribe button', (tester) async {
      tester.view.physicalSize = const Size(390, 844); // Standard mobile phone viewport
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PhoolMalaScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar title
      expect(find.text('Phool Mala Store'), findsOneWidget);

      // Tabs
      expect(find.text('Monthly Subscription'), findsOneWidget);
      expect(find.text('Daily Single Orders'), findsOneWidget);

      // Festive Subscription card elements
      expect(find.text('Festive Offer Subscription'), findsOneWidget);
      expect(find.text('POPULAR'), findsOneWidget);

      // Feature items
      expect(find.text('Exotic Mogra & Thick Marigold Garlands on Special Days'), findsOneWidget);

      // Price and Action visible without needing secondary navigation
      expect(find.text('₹399'), findsOneWidget);
      expect(find.text('/mo'), findsWidgets);
      expect(find.text('Subscribe Now'), findsWidgets);
    });

    test('4. Profile Address Persistence: UserData persists and recovers address cleanly', () async {
      UserData.address = 'Flat 501, Gokul Dham, MG Road, Mumbai';
      expect(UserData.address, equals('Flat 501, Gokul Dham, MG Road, Mumbai'));

      UserData.clear();
      expect(UserData.address, equals(''));
    });
  });
}
