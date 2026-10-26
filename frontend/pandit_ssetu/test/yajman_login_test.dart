import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pandit_ssetu/screens/yajman_login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget() {
    return const MaterialApp(
      home: YajmanLoginScreen(),
    );
  }

  group('YajmanLoginScreen Widget Tests', () {
    testWidgets('1. Renders SARV MANGAL branding, phone field, and Send OTP button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('SARV MANGAL'), findsOneWidget);
      expect(find.text('Yajman Devotee Login'), findsOneWidget);
      expect(find.text('+91'), findsOneWidget);
      expect(find.text('Send OTP'), findsOneWidget);
      expect(find.text('Register as Yajman'), findsOneWidget);
    });

    testWidgets('2. Rejects invalid or short phone numbers with SnackBar error', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Send OTP with empty field
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid 10-digit mobile number'), findsOneWidget);

      // Enter 5 digits
      final textField = find.byType(TextField);
      await tester.enterText(textField, '12345');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid 10-digit mobile number'), findsOneWidget);
    });
  });
}
