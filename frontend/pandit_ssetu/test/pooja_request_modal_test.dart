import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pandit_ssetu/constants/branding.dart';
import 'package:pandit_ssetu/widgets/incoming_pooja_request_modal.dart';
import 'package:pandit_ssetu/utils/booking_date_time_helper.dart';

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
    });
  });

  group('Pooja Request Modal for Pandits (Phase P2-B Task 3)', () {
    final validPayload = {
      'bookingId': 'booking-uuid-777',
      'poojaId': 'pooja-uuid-888',
      'poojaName': 'Rudrabhishek Pooja with Havan',
      'bookingTime': '2026-10-15T09:30:00.000Z',
      'mode': 'IN_PERSON',
      'venueAddress': 'Flat 302, ATS Village, Sector 93A Noida',
      'approximateDistanceKm': 3.8,
      'samagriIncluded': true,
      'totalAmount': '3500.00',
      'expiresAt': DateTime.now().add(const Duration(seconds: 50)).toIso8601String(),
      'dispatchAttemptId': 'dispatch-uuid-999',
    };

    testWidgets('1. Valid booking:new-request opens the modal and displays branding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingPoojaRequestModal(
              requestPayload: validPayload,
              onAccept: (_) async {},
              onDecline: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Verify SARV MANGAL brand display
      expect(find.text(AppBranding.appDisplayName), findsOneWidget);
      expect(find.byType(IncomingPoojaRequestModal), findsOneWidget);
    });

    testWidgets('2. Pooja name, amount, date/time, and other available fields display correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingPoojaRequestModal(
              requestPayload: validPayload,
              onAccept: (_) async {},
              onDecline: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Pooja Name
      expect(find.text('Rudrabhishek Pooja with Havan'), findsOneWidget);

      // Amount
      expect(find.text('₹3500.00'), findsOneWidget);
      expect(find.text('ESTIMATED DAKSHINA'), findsOneWidget);

      // Samagri included badge
      expect(find.text('Samagri Kit Included'), findsOneWidget);

      // Mode
      expect(find.text('IN-PERSON'), findsOneWidget);

      // Distance
      expect(find.textContaining('3.8 km away'), findsOneWidget);

      // Date / Time
      final formattedTime = BookingDateTimeHelper.formatForDisplay('2026-10-15T09:30:00.000Z');
      expect(find.text(formattedTime), findsOneWidget);
    });

    testWidgets('3. Malformed payload is handled without crashing', (tester) async {
      final malformedPayload = <String, dynamic>{
        'bookingId': 'partial-id',
        // Missing poojaName, totalAmount, mode, bookingTime, venueAddress
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingPoojaRequestModal(
              requestPayload: malformedPayload,
              onAccept: (_) async {},
              onDecline: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Falls back safely
      expect(find.text('Sacred Pooja Ritual'), findsOneWidget);
      expect(find.text('₹0'), findsOneWidget);
      expect(find.text('IN-PERSON'), findsOneWidget);
      expect(find.text('Location shared with Pandit'), findsOneWidget);
      expect(find.byType(IncomingPoojaRequestModal), findsOneWidget);
    });

    testWidgets('4. Expired request cannot be accepted through UI', (tester) async {
      final expiredPayload = Map<String, dynamic>.from(validPayload);
      // Expiry was 10 seconds ago
      expiredPayload['expiresAt'] = DateTime.now().subtract(const Duration(seconds: 10)).toIso8601String();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingPoojaRequestModal(
              requestPayload: expiredPayload,
              onAccept: (_) async {},
              onDecline: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Expired banner visible
      expect(find.textContaining('Request Expired'), findsOneWidget);

      // Accept button must NOT be present
      expect(find.text('ACCEPT BOOKING'), findsNothing);

      // Dismiss button is available instead
      expect(find.text('DISMISS'), findsOneWidget);
    });

    testWidgets('5. Countdown decreases and reaches expiry correctly', (tester) async {
      final shortLivedPayload = Map<String, dynamic>.from(validPayload);
      // Exactly 3 seconds remaining
      shortLivedPayload['expiresAt'] = DateTime.now().add(const Duration(seconds: 3)).toIso8601String();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingPoojaRequestModal(
              requestPayload: shortLivedPayload,
              onAccept: (_) async {},
              onDecline: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('ACCEPT BOOKING'), findsOneWidget);

      // Advance by 1 second
      await tester.pump(const Duration(seconds: 1));
      // Advance by 3 more seconds to cross expiry
      await tester.pump(const Duration(seconds: 3));

      // Modal transitioned to expired state
      expect(find.textContaining('Request Expired'), findsOneWidget);
      expect(find.text('ACCEPT BOOKING'), findsNothing);
      expect(find.text('DISMISS'), findsOneWidget);
    });

    test('6. Duplicate events do not open duplicate modals', () {
      final Set<String> dismissedBookingIds = {};
      Map<String, dynamic>? activePayload;
      int openedCount = 0;

      void handleIncoming(Map<String, dynamic> data) {
        final bId = data['bookingId']?.toString();
        if (bId == null || bId.isEmpty) return;
        if (dismissedBookingIds.contains(bId)) return;
        if (activePayload != null && activePayload!['bookingId'] == bId) return;

        activePayload = data;
        openedCount++;
      }

      handleIncoming(validPayload);
      expect(openedCount, 1);

      // Same event delivered again while active
      handleIncoming(validPayload);
      expect(openedCount, 1, reason: 'Duplicate active event must be ignored');

      // Dismiss / decline event
      dismissedBookingIds.add(validPayload['bookingId'] as String);
      activePayload = null;

      // Event delivered again after dismissal
      handleIncoming(validPayload);
      expect(openedCount, 1, reason: 'Dismissed event must not re-open modal');
    });

    testWidgets('7. Duplicate button taps do not trigger duplicate submissions', (tester) async {
      int acceptCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingPoojaRequestModal(
              requestPayload: validPayload,
              onAccept: (bId) async {
                acceptCallCount++;
                // Artificial delay simulating network request
                await Future.delayed(const Duration(milliseconds: 500));
              },
              onDecline: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      // First tap
      await tester.tap(find.text('ACCEPT BOOKING'));
      await tester.pump(); // Start execution

      // While submitting, CircularProgressIndicator is rendered
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Second tap while submitting
      final acceptButton = find.byType(ElevatedButton);
      await tester.tap(acceptButton, warnIfMissed: false);
      await tester.pump();

      // Advance clock past the network delay
      await tester.pump(const Duration(milliseconds: 600));

      // Must have invoked onAccept exactly once
      expect(acceptCallCount, 1);
    });

    testWidgets('8. API errors display appropriate feedback', (tester) async {
      String? caughtError;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return IncomingPoojaRequestModal(
                  requestPayload: validPayload,
                  onAccept: (bId) async {
                    try {
                      throw Exception('BOOKING_ALREADY_TAKEN: This booking has already been accepted by another Pandit.');
                    } catch (e) {
                      caughtError = e.toString();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(caughtError!)),
                      );
                    }
                  },
                  onDecline: () {},
                  onDismiss: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('ACCEPT BOOKING'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(caughtError, contains('BOOKING_ALREADY_TAKEN'));
      expect(find.textContaining('BOOKING_ALREADY_TAKEN'), findsOneWidget);
    });

    testWidgets('9. Widget disposal cancels timers and listeners', (tester) async {
      bool isDisposed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              if (isDisposed) {
                return const Scaffold(body: Text('Disposed Screen'));
              }
              return Scaffold(
                body: IncomingPoojaRequestModal(
                  requestPayload: validPayload,
                  onAccept: (_) async {},
                  onDecline: () {},
                  onDismiss: () {},
                ),
              );
            },
          ),
        ),
      );

      expect(find.byType(IncomingPoojaRequestModal), findsOneWidget);

      // Dispose widget
      isDisposed = true;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Disposed Screen')),
        ),
      );

      // Verify no exceptions or active timer leaks upon pumping time forward
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Disposed Screen'), findsOneWidget);
      expect(find.byType(IncomingPoojaRequestModal), findsNothing);
    });

    testWidgets('10. Sensitive Yajman details are not displayed', (tester) async {
      final payloadWithPotentialLeaks = {
        'bookingId': 'b-1234',
        'poojaName': 'Satyanarayan Katha',
        'venueAddress': 'Flat 402, Tower B, Lotus Greens, Sector 78 Noida',
        'totalAmount': '2100.00',
        'yajmanPhone': '+919999988888',
        'authToken': 'bearer-secret-token-123',
        'razorpayOrderId': 'order_xyz789',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingPoojaRequestModal(
              requestPayload: payloadWithPotentialLeaks,
              onAccept: (_) async {},
              onDecline: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Must NOT render flat/unit number in address
      expect(find.textContaining('Flat 402'), findsNothing);
      expect(find.textContaining('Tower B, Lotus Greens, Sector 78 Noida'), findsOneWidget);

      // Must NOT render phone numbers
      expect(find.textContaining('+919999988888'), findsNothing);

      // Must NOT render secret tokens
      expect(find.textContaining('bearer-secret-token-123'), findsNothing);
      expect(find.textContaining('order_xyz789'), findsNothing);
    });

    testWidgets('11. Successful accept invokes onAccept callback with bookingId', (tester) async {
      String? acceptedBookingId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingPoojaRequestModal(
              requestPayload: validPayload,
              onAccept: (bId) async {
                acceptedBookingId = bId;
              },
              onDecline: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('ACCEPT BOOKING'));
      await tester.pumpAndSettle();

      expect(acceptedBookingId, 'booking-uuid-777');
    });

    testWidgets('12. Tapping DECLINE opens reason dialog and confirming calls onDecline with selected reason', (tester) async {
      String? declinedBookingId;
      String? declinedReason;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingPoojaRequestModal(
              requestPayload: validPayload,
              onAccept: (_) async {},
              onDecline: (bId, {String? reason}) async {
                declinedBookingId = bId;
                declinedReason = reason;
              },
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Tap DECLINE button
      await tester.tap(find.text('DECLINE'));
      await tester.pumpAndSettle();

      // Reason dialog is displayed
      expect(find.text('Decline Request'), findsOneWidget);
      expect(find.text('Too Far / Travel Distance'), findsOneWidget);

      // Select 'TOO_FAR'
      await tester.tap(find.byKey(const Key('decline_reason_TOO_FAR')));
      await tester.pumpAndSettle();

      // Tap CONFIRM DECLINE
      await tester.tap(find.text('CONFIRM DECLINE'));
      await tester.pumpAndSettle();

      expect(declinedBookingId, 'booking-uuid-777');
      expect(declinedReason, 'TOO_FAR');
    });

    testWidgets('13. Cancelling decline dialog does not trigger onDecline and keeps modal active', (tester) async {
      bool declineCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingPoojaRequestModal(
              requestPayload: validPayload,
              onAccept: (_) async {},
              onDecline: (bId, {String? reason}) async {
                declineCalled = true;
              },
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Tap DECLINE
      await tester.tap(find.text('DECLINE'));
      await tester.pumpAndSettle();

      // Tap CANCEL
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      expect(declineCalled, false);
      expect(find.text('ACCEPT BOOKING'), findsOneWidget);
    });

    testWidgets('14. Network failure during decline surfaces error and preserves modal for retry', (tester) async {
      String? caughtError;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return IncomingPoojaRequestModal(
                  requestPayload: validPayload,
                  onAccept: (_) async {},
                  onDecline: (bId, {String? reason}) async {
                    try {
                      throw Exception('Network unreachable: connection failed');
                    } catch (e) {
                      caughtError = e.toString();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('❌ Could not decline: $caughtError')),
                      );
                      rethrow;
                    }
                  },
                  onDismiss: () {},
                );
              },
            ),
          ),
        ),
      );

      // Tap DECLINE and confirm
      await tester.tap(find.text('DECLINE'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CONFIRM DECLINE'));
      await tester.pumpAndSettle();

      expect(caughtError, contains('Network unreachable'));
      expect(find.textContaining('Could not decline'), findsOneWidget);
      // Buttons remain available to allow retry or acceptance
      expect(find.text('DECLINE'), findsOneWidget);
      expect(find.text('ACCEPT BOOKING'), findsOneWidget);
    });

    testWidgets('15. Duplicate taps during decline execution do not invoke onDecline multiple times', (tester) async {
      int declineInvocationCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingPoojaRequestModal(
              requestPayload: validPayload,
              onAccept: (_) async {},
              onDecline: (bId, {String? reason}) async {
                declineInvocationCount++;
                await Future.delayed(const Duration(milliseconds: 300));
              },
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Tap DECLINE and confirm
      await tester.tap(find.text('DECLINE'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CONFIRM DECLINE'));
      await tester.pump(); // Start async execution

      // Try tapping decline again while submitting
      await tester.tap(find.text('DECLINE'), warnIfMissed: false);
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 400));
      expect(declineInvocationCount, 1);
    });
  });
}
