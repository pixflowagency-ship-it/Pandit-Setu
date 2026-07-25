import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandit_ssetu/screens/yajman_otp_screen.dart';

void main() {
  setUpAll(() {
    // Avoid loading fonts in tests
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('YajmanOtpScreen renders title, input fields, and timer', (WidgetTester tester) async {
    // Build the YajmanOtpScreen widget inside a MaterialApp.
    await tester.pumpWidget(
      const MaterialApp(
        home: YajmanOtpScreen(),
      ),
    );

    // Verify key titles are present.
    expect(find.text('Verify Your Number'), findsOneWidget);
    expect(find.text('ENTER OTP CODE'), findsOneWidget);

    // Verify 6 input fields are present.
    expect(find.byType(TextField), findsNWidgets(6));

    // Verify timer text is present initially.
    expect(find.textContaining('Resend code in'), findsOneWidget);

    // Verify Verify & Proceed button is present.
    expect(find.text('Verify & Proceed'), findsOneWidget);
  });
}
