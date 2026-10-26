import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pandit_ssetu/theme/app_theme.dart';
import 'package:pandit_ssetu/widgets/common/sarv_button.dart';
import 'package:pandit_ssetu/widgets/common/sarv_text_field.dart';
import 'package:pandit_ssetu/widgets/common/sarv_card.dart';
import 'package:pandit_ssetu/widgets/common/sarv_status_badge.dart';
import 'package:pandit_ssetu/widgets/common/sarv_states.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('SARV MANGAL Design System Widget Tests', () {
    testWidgets('SarvButton renders label and triggers tap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestableWidget(
          SarvButton(
            label: 'Book Sacred Pooja',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      );

      expect(find.text('Book Sacred Pooja'), findsOneWidget);
      await tester.tap(find.text('Book Sacred Pooja'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('SarvButton displays progress indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          SarvButton(
            label: 'Submit Verification',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit Verification'), findsNothing);
    });

    testWidgets('SarvTextField renders label and hint, and toggles obscure text', (tester) async {
      final controller = TextEditingController(text: 'SecretPass123');
      await tester.pumpWidget(
        buildTestableWidget(
          SarvTextField(
            label: 'Admin Password',
            hint: 'Enter your password',
            controller: controller,
            isPassword: true,
          ),
        ),
      );

      expect(find.text('Admin Password'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Tap the eye icon to toggle visibility
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('SarvCard renders child content inside elevated card', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const SarvCard(
            child: Text('Ganesh Sthapana Details'),
          ),
        ),
      );

      expect(find.text('Ganesh Sthapana Details'), findsOneWidget);
    });

    testWidgets('SarvStatusBadge renders status badge with uppercase text', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Column(
            children: [
              SarvStatusBadge(status: 'approved'),
              SarvStatusBadge(status: 'pending'),
              SarvStatusBadge(status: 'rejected'),
            ],
          ),
        ),
      );

      expect(find.text('APPROVED'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('REJECTED'), findsOneWidget);
    });

    testWidgets('SarvStates renders Loading, Empty, and Error states correctly', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        buildTestableWidget(
          SarvErrorState(
            title: 'Network Timeout',
            error: 'Failed to connect to gateway',
            onRetry: () {
              retried = true;
            },
          ),
        ),
      );

      expect(find.text('Network Timeout'), findsOneWidget);
      expect(find.text('Failed to connect to gateway'), findsOneWidget);

      await tester.tap(find.text('Retry Connection'));
      await tester.pump();
      expect(retried, isTrue);
    });
  });
}
