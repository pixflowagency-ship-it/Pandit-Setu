import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pandit_ssetu/widgets/consultation_flow_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget() {
    return const MaterialApp(
      home: Scaffold(
        body: ConsultationFlowModal(),
      ),
    );
  }

  group('ConsultationFlowModal Widget Tests', () {
    testWidgets('1. Mounts consultation flow modal and displays main choices without A/B prefixes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Vedic Consultation'), findsWidgets);
      expect(find.textContaining('Online Consultation'), findsOneWidget);
      expect(find.textContaining('Offline Consultation'), findsOneWidget);

      // Verify strict absence of A. and B. prefixes
      expect(find.textContaining('A. ONLINE'), findsNothing);
      expect(find.textContaining('B. OFFLINE'), findsNothing);
    });

    testWidgets('2. Online schedule view mounts without DropdownButton assertion error', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on Online Consultation
      final onlineOption = find.textContaining('Online Consultation');
      expect(onlineOption, findsOneWidget);
      await tester.tap(onlineOption);
      await tester.pumpAndSettle();

      // Tap on Schedule Later
      final scheduleOption = find.textContaining('Schedule Later');
      expect(scheduleOption, findsOneWidget);
      await tester.tap(scheduleOption);
      await tester.pumpAndSettle();

      // Verify that the time slot dropdown renders without assertion errors and contains 11:30 AM
      expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
      expect(find.text('11:30 AM'), findsOneWidget);

      // Verify header subtitle uses exact SARV MANGAL branding
      expect(find.textContaining('SARV MANGAL'), findsWidgets);
    });

    testWidgets('3. Offline consultation view mounts and shows safe time slot selection without crash', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on Offline Consultation
      final offlineOption = find.textContaining('Offline Consultation');
      expect(offlineOption, findsOneWidget);
      await tester.tap(offlineOption);
      await tester.pumpAndSettle();

      expect(find.textContaining('Offline Consultation'), findsWidgets);
      expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
      expect(find.text('11:00 AM'), findsOneWidget);
    });

    testWidgets('4. Online consultation duration and communication mode can be toggled', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Online Consultation'));
      await tester.pumpAndSettle();

      // Toggle duration to 30 Mins
      final thirtyMins = find.text('30 Mins');
      expect(thirtyMins, findsOneWidget);
      await tester.tap(thirtyMins);
      await tester.pumpAndSettle();

      // Switch medium to Google Meet
      final meetOption = find.textContaining('Google Meet');
      expect(meetOption, findsWidgets);
      await tester.tap(meetOption.first);
      await tester.pumpAndSettle();
    });

    testWidgets('5. Topic dropdown contains Others, and selecting Others reveals custom topic input field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to Online Consultation
      await tester.tap(find.textContaining('Online Consultation'));
      await tester.pumpAndSettle();

      // Initial state: custom topic text field should not be visible
      expect(find.text('Custom Topic Details'), findsNothing);

      // Scroll to topic dropdown if needed and tap it
      await tester.drag(find.byType(ListView), const Offset(0, -250));
      await tester.pumpAndSettle();

      final topicDropdown = find.byType(DropdownButtonFormField<String>).first;
      await tester.tap(topicDropdown);
      await tester.pumpAndSettle();

      // Verify 'Others' is present in the dropdown items list
      final othersItem = find.text('Others').last;
      expect(othersItem, findsOneWidget);

      // Select 'Others'
      await tester.tap(othersItem);
      await tester.pumpAndSettle();

      // Drag slightly if needed to reveal custom topic field
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();

      expect(find.text('Custom Topic Details'), findsOneWidget);

      // Enter a custom topic
      await tester.enterText(find.byType(TextFormField).last, 'Ancestral Peace & Griha Shanti');
      await tester.pumpAndSettle();

      expect(find.text('Ancestral Peace & Griha Shanti'), findsOneWidget);
    });

    testWidgets('6. Responsive layout test at narrow 320px width has no RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Main choices mount cleanly
      expect(find.textContaining('Online Consultation'), findsOneWidget);

      // Scroll to find offline consultation
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(find.textContaining('Offline Consultation'), findsOneWidget);

      // Reset scroll to top and navigate to Online view
      await tester.drag(find.byType(ListView), const Offset(0, 200));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Online Consultation'));
      await tester.pumpAndSettle();

      // Header and options render without overflow
      expect(find.textContaining('Online Consultation'), findsWidgets);
    });
  });
}
