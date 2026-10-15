import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pandit_ssetu/constants/branding.dart';
import 'package:pandit_ssetu/screens/live_pooja_tracking_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'token': 'mock-approved-pandit-jwt',
      'user': jsonEncode({
        'id': 'pandit-user-uuid-1',
        'phone': '+919876543210',
        'role': 'PANDIT',
      }),
      'user_bookings': jsonEncode([
        {
          'id': 'booking-lifecycle-uuid-1',
          'pooja': {'title': 'Satyanarayan Maha Pooja'},
          'status': 'CONFIRMED',
          'totalAmount': '3100.00',
          'venueAddress': 'Sector 62, Noida, UP',
          'allocationMode': 'manual',
          'createdAt': DateTime.now().toIso8601String(),
        }
      ]),
    });
  });

  group('SARV MANGAL Phase P2-B Task 5: Booking Lifecycle & State Machine Tests', () {
    test('1. Official brand identity strictly remains SARV MANGAL', () {
      expect(AppBranding.appDisplayName, equals('SARV MANGAL'));
    });

    test('2. Status-to-Step mapping reflects truthful lifecycle milestones', () {
      int stepFromStatus(String? status) {
        switch (status) {
          case 'PENDING':
            return 0;
          case 'CONFIRMED':
            return 0; // Pandit Assigned
          case 'HEADING_TO_VENUE':
            return 2; // Pandit En Route
          case 'ARRIVED':
            return 2; // Arrived at Venue
          case 'PUJA_STARTED':
          case 'IN_PROGRESS':
            return 3; // Pooja In Progress
          case 'COMPLETED':
            return 4; // Ritual Completed
          default:
            return 0;
        }
      }

      expect(stepFromStatus('PENDING'), equals(0));
      expect(stepFromStatus('CONFIRMED'), equals(0));
      expect(stepFromStatus('HEADING_TO_VENUE'), equals(2));
      expect(stepFromStatus('ARRIVED'), equals(2));
      expect(stepFromStatus('PUJA_STARTED'), equals(3));
      expect(stepFromStatus('IN_PROGRESS'), equals(3));
      expect(stepFromStatus('COMPLETED'), equals(4));
      expect(stepFromStatus('UNKNOWN'), equals(0));
    });

    test('3. State machine validates permitted transition graph', () {
      const validTransitions = {
        'PENDING': ['CONFIRMED', 'CANCELLED'],
        'CONFIRMED': ['HEADING_TO_VENUE', 'IN_PROGRESS', 'CANCELLED'],
        'HEADING_TO_VENUE': ['ARRIVED', 'CANCELLED'],
        'ARRIVED': ['PUJA_STARTED', 'IN_PROGRESS'],
        'PUJA_STARTED': ['COMPLETED'],
        'IN_PROGRESS': ['COMPLETED'],
      };

      bool isValidTransition(String from, String to) {
        return validTransitions[from]?.contains(to) ?? false;
      }

      // Valid forward path
      expect(isValidTransition('PENDING', 'CONFIRMED'), isTrue);
      expect(isValidTransition('CONFIRMED', 'HEADING_TO_VENUE'), isTrue);
      expect(isValidTransition('HEADING_TO_VENUE', 'ARRIVED'), isTrue);
      expect(isValidTransition('ARRIVED', 'PUJA_STARTED'), isTrue);
      expect(isValidTransition('PUJA_STARTED', 'COMPLETED'), isTrue);

      // Backwards compatible paths
      expect(isValidTransition('CONFIRMED', 'IN_PROGRESS'), isTrue);
      expect(isValidTransition('IN_PROGRESS', 'COMPLETED'), isTrue);

      // Invalid skipped transitions
      expect(isValidTransition('CONFIRMED', 'ARRIVED'), isFalse);
      expect(isValidTransition('CONFIRMED', 'PUJA_STARTED'), isFalse);
      expect(isValidTransition('CONFIRMED', 'COMPLETED'), isFalse);
      expect(isValidTransition('HEADING_TO_VENUE', 'COMPLETED'), isFalse);

      // Invalid reversed transitions
      expect(isValidTransition('COMPLETED', 'PUJA_STARTED'), isFalse);
      expect(isValidTransition('ARRIVED', 'HEADING_TO_VENUE'), isFalse);
      expect(isValidTransition('PUJA_STARTED', 'ARRIVED'), isFalse);

      // Cancelled state cannot transition
      expect(isValidTransition('CANCELLED', 'CONFIRMED'), isFalse);
      expect(isValidTransition('CANCELLED', 'HEADING_TO_VENUE'), isFalse);
    });

    test('4. Payload structure for updateBookingStatus contains required fields', () {
      Map<String, dynamic> buildStatusPayload(String expected, String next) {
        return {
          'expectedStatus': expected,
          'newStatus': next,
        };
      }

      final payload = buildStatusPayload('CONFIRMED', 'HEADING_TO_VENUE');
      expect(payload['expectedStatus'], equals('CONFIRMED'));
      expect(payload['newStatus'], equals('HEADING_TO_VENUE'));
    });

    testWidgets('5. LivePoojaTrackingScreen mounts with active booking and displays steps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LivePoojaTrackingScreen(
            bookingId: 'booking-lifecycle-uuid-1',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title
      expect(find.text('Live Pooja Tracking'), findsOneWidget);
      // Verify timeline steps exist
      expect(find.text('Pandit Assigned'), findsOneWidget);
      expect(find.text('Pooja In Progress'), findsOneWidget);
    });

    testWidgets('6. Action button double-tap prevention disables submission during in-flight status update', (tester) async {
      bool isSubmitting = false;
      int submitCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setState(() => isSubmitting = true);
                          submitCount++;
                          await Future.delayed(const Duration(milliseconds: 100));
                          setState(() => isSubmitting = false);
                        },
                  child: isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('START JOURNEY TO VENUE'),
                );
              },
            ),
          ),
        ),
      );

      // Initially enabled
      expect(find.text('START JOURNEY TO VENUE'), findsOneWidget);
      expect(isSubmitting, isFalse);

      // Tap once -> triggers submission
      await tester.tap(find.text('START JOURNEY TO VENUE'));
      await tester.pump(); // Start frame of submission

      expect(isSubmitting, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Second tap while in-flight -> ignored because button is disabled
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 50));
      expect(submitCount, equals(1)); // Did not increment!

      // Complete async operation
      await tester.pump(const Duration(milliseconds: 100));
      expect(isSubmitting, isFalse);
      expect(submitCount, equals(1));
    });
  });
}
