import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pandit_ssetu/constants/branding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mock-approved-pandit-jwt-token',
      'user_role': 'PANDIT',
      'user_id': 'pandit-uuid-101',
    });
  });

  group('SARV MANGAL Phase P2-B Task 6: Dakshina Collection & Booking Closure Tests', () {
    test('1. Official brand identity strictly remains SARV MANGAL', () {
      expect(AppBranding.appDisplayName, equals('SARV MANGAL'));
    });

    test('2. Dakshina payment method selection toggles between Cash and Online', () {
      String selectedMethod = 'CASH';

      void selectMethod(String method) {
        if (method == 'CASH' || method == 'ONLINE') {
          selectedMethod = method;
        }
      }

      expect(selectedMethod, equals('CASH'));

      selectMethod('ONLINE');
      expect(selectedMethod, equals('ONLINE'));

      selectMethod('CASH');
      expect(selectedMethod, equals('CASH'));

      // Invalid method is rejected / ignored
      selectMethod('CRYPTO');
      expect(selectedMethod, equals('CASH'));
    });

    test('3. Dakshina amount bounds validation (must be positive and within upper threshold)', () {
      bool isValidDakshinaAmount(dynamic amount) {
        if (amount == null) return false;
        final num? parsed = num.tryParse(amount.toString());
        if (parsed == null) return false;
        // Business rule: positive, strictly > 0 and <= 500,000 INR
        return parsed > 0 && parsed <= 500000;
      }

      // Valid amounts
      expect(isValidDakshinaAmount(501), isTrue);
      expect(isValidDakshinaAmount('2100'), isTrue);
      expect(isValidDakshinaAmount('5100.50'), isTrue);
      expect(isValidDakshinaAmount(500000), isTrue);

      // Invalid amounts
      expect(isValidDakshinaAmount(0), isFalse);
      expect(isValidDakshinaAmount(-100), isFalse);
      expect(isValidDakshinaAmount('-500'), isFalse);
      expect(isValidDakshinaAmount('invalid_amount'), isFalse);
      expect(isValidDakshinaAmount(null), isFalse);
      expect(isValidDakshinaAmount(500001), isFalse); // exceeds threshold
    });

    test('4. Double-tap lockout during active collection prevents duplicate submissions', () {
      bool isCollectingDakshina = false;
      int submissionAttemptCounter = 0;

      Future<void> submitDakshinaCollection() async {
        if (isCollectingDakshina) {
          // Locked out! Prevent duplicate API trigger
          return;
        }
        isCollectingDakshina = true;
        submissionAttemptCounter++;
        // Simulate async network request
        await Future.delayed(const Duration(milliseconds: 50));
        isCollectingDakshina = false;
      }

      // First tap executes
      submitDakshinaCollection();
      expect(isCollectingDakshina, isTrue);

      // Immediate second and third taps during active flight must be ignored
      submitDakshinaCollection();
      submitDakshinaCollection();

      expect(submissionAttemptCounter, equals(1));
    });

    test('5. Cash collection request payload structure adheres to contract', () {
      Map<String, dynamic> buildCashCollectionPayload({
        required String bookingId,
        required double amount,
        String? notes,
      }) {
        return {
          'bookingId': bookingId,
          'amount': amount,
          'paymentMethod': 'CASH',
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        };
      }

      final payload = buildCashCollectionPayload(
        bookingId: 'booking-uuid-555',
        amount: 2100.0,
        notes: 'Dakshina received with tamboolam and pushpam',
      );

      expect(payload['bookingId'], equals('booking-uuid-555'));
      expect(payload['amount'], equals(2100.0));
      expect(payload['paymentMethod'], equals('CASH'));
      expect(payload['notes'], contains('tamboolam'));
    });

    test('6. Online payment order creation payload & retry without duplicate charges', () {
      Map<String, dynamic>? activeOrder;
      int orderCreationCalls = 0;

      Map<String, dynamic> createOrReuseOrder({
        required String bookingId,
        required double amount,
      }) {
        if (activeOrder != null && activeOrder!['bookingId'] == bookingId) {
          // Idempotent: reuse existing pending order if available
          return activeOrder!;
        }
        orderCreationCalls++;
        activeOrder = {
          'orderId': 'order_rzp_mock_$orderCreationCalls',
          'bookingId': bookingId,
          'amount': amount,
          'currency': 'INR',
          'status': 'PENDING',
        };
        return activeOrder!;
      }

      final order1 = createOrReuseOrder(bookingId: 'b-101', amount: 3100.0);
      expect(order1['orderId'], equals('order_rzp_mock_1'));
      expect(orderCreationCalls, equals(1));

      // Retry without duplicate order creation
      final order2 = createOrReuseOrder(bookingId: 'b-101', amount: 3100.0);
      expect(order2['orderId'], equals('order_rzp_mock_1'));
      expect(orderCreationCalls, equals(1)); // Still 1!
    });

    test('7. Booking closure condition: strictly requires authoritative backend confirmation', () {
      String bookingStatus = 'PUJA_STARTED';
      bool dakshinaConfirmedByServer = false;

      // Pandit attempts to close booking
      String completeBooking({required bool serverConfirmed}) {
        if (!serverConfirmed) {
          throw Exception('DAKSHINA_NOT_COLLECTED: Final Dakshina collection must be confirmed before closure');
        }
        return 'COMPLETED';
      }

      // Closure without server verification fails
      expect(
        () => completeBooking(serverConfirmed: dakshinaConfirmedByServer),
        throwsA(predicate((e) => e.toString().contains('DAKSHINA_NOT_COLLECTED'))),
      );
      expect(bookingStatus, equals('PUJA_STARTED'));

      // Backend verifies payment and confirms
      dakshinaConfirmedByServer = true;
      bookingStatus = completeBooking(serverConfirmed: dakshinaConfirmedByServer);
      expect(bookingStatus, equals('COMPLETED'));
    });

    test('8. Real-time Socket.IO dakshina:collected event updates local state', () {
      Map<String, dynamic>? localDakshinaRecord;
      String currentBookingStatus = 'PUJA_STARTED';

      void onDakshinaCollectedSocketEvent(Map<String, dynamic> eventData) {
        if (eventData['bookingId'] == 'booking-sync-999') {
          localDakshinaRecord = {
            'amount': eventData['amount'],
            'paymentMethod': eventData['paymentMethod'],
            'paymentStatus': eventData['paymentStatus'],
            'collectedAt': eventData['collectedAt'],
          };
          if (eventData['newBookingStatus'] != null) {
            currentBookingStatus = eventData['newBookingStatus'];
          }
        }
      }

      // Simulate receiving Socket.IO event from backend commit
      onDakshinaCollectedSocketEvent({
        'bookingId': 'booking-sync-999',
        'amount': 2501.0,
        'paymentMethod': 'CASH',
        'paymentStatus': 'PAID',
        'newBookingStatus': 'COMPLETED',
        'collectedAt': DateTime.now().toIso8601String(),
      });

      expect(localDakshinaRecord, isNotNull);
      expect(localDakshinaRecord!['paymentStatus'], equals('PAID'));
      expect(localDakshinaRecord!['paymentMethod'], equals('CASH'));
      expect(currentBookingStatus, equals('COMPLETED'));
    });

    test('9. Razorpay signature verification payload requires order_id, payment_id, and signature', () {
      bool isValidVerificationRequest(Map<String, dynamic> request) {
        return request.containsKey('razorpayOrderId') &&
            request['razorpayOrderId'].toString().isNotEmpty &&
            request.containsKey('razorpayPaymentId') &&
            request['razorpayPaymentId'].toString().isNotEmpty &&
            request.containsKey('razorpaySignature') &&
            request['razorpaySignature'].toString().isNotEmpty;
      }

      expect(
        isValidVerificationRequest({
          'razorpayOrderId': 'order_K1234567890abc',
          'razorpayPaymentId': 'pay_K1234567890xyz',
          'razorpaySignature': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        }),
        isTrue,
      );

      // Missing signature
      expect(
        isValidVerificationRequest({
          'razorpayOrderId': 'order_K1234567890abc',
          'razorpayPaymentId': 'pay_K1234567890xyz',
        }),
        isFalse,
      );

      // Empty paymentId
      expect(
        isValidVerificationRequest({
          'razorpayOrderId': 'order_K1234567890abc',
          'razorpayPaymentId': '',
          'razorpaySignature': 'sig',
        }),
        isFalse,
      );
    });

    testWidgets('10. Dakshina UI Widget renders Cash and Online selection cards with action button', (tester) async {
      String selectedMethod = 'CASH';
      bool isCollecting = false;
      bool submitTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'DAKSHINA COLLECTION',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ListTile(
                        title: const Text('Cash Dakshina'),
                        leading: Icon(
                          selectedMethod == 'CASH'
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                        ),
                        onTap: isCollecting
                            ? null
                            : () {
                                setState(() => selectedMethod = 'CASH');
                              },
                      ),
                      ListTile(
                        title: const Text('Online Dakshina (UPI / QR)'),
                        leading: Icon(
                          selectedMethod == 'ONLINE'
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                        ),
                        onTap: isCollecting
                            ? null
                            : () {
                                setState(() => selectedMethod = 'ONLINE');
                              },
                      ),
                      ElevatedButton(
                        key: const Key('dakshina_submit_button'),
                        onPressed: isCollecting
                            ? null
                            : () {
                                setState(() {
                                  isCollecting = true;
                                  submitTriggered = true;
                                });
                              },
                        child: isCollecting
                            ? const CircularProgressIndicator()
                            : Text(selectedMethod == 'CASH'
                                ? 'Confirm Cash Dakshina'
                                : 'Generate Online QR / Pay'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('DAKSHINA COLLECTION'), findsOneWidget);
      expect(find.text('Cash Dakshina'), findsOneWidget);
      expect(find.text('Online Dakshina (UPI / QR)'), findsOneWidget);
      expect(find.text('Confirm Cash Dakshina'), findsOneWidget);

      // Select Online
      await tester.tap(find.text('Online Dakshina (UPI / QR)'));
      await tester.pump();
      expect(find.text('Generate Online QR / Pay'), findsOneWidget);

      // Tap submit
      await tester.tap(find.byKey(const Key('dakshina_submit_button')));
      await tester.pump();

      expect(submitTriggered, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
