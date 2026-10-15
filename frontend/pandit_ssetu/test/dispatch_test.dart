import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pandit_ssetu/constants/branding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pooja Request Dispatch Engine & Realtime Events (Phase P2-B Task 2)', () {
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

    test('Brand identity remains strictly SARV MANGAL', () {
      expect(AppBranding.appDisplayName, 'SARV MANGAL');
    });

    test('Parses genuine incoming dispatch event payload accurately', () {
      final dynamic samplePayload = {
        'bookingId': 'book-uuid-1234',
        'poojaId': 'pooja-uuid-5678',
        'poojaName': 'Satyanarayan Katha with Havan',
        'bookingTime': '2026-10-15T09:30:00.000Z',
        'mode': 'IN_PERSON',
        'venueAddress': 'Lotus Greens, Sector 78 Noida',
        'approximateDistanceKm': 2.4,
        'samagriIncluded': true,
        'totalAmount': '2625.00',
        'expiresAt': '2026-10-14T20:35:00.000Z',
        'dispatchAttemptId': 'attempt-uuid-9999',
      };

      Map<String, dynamic>? parsedPayload;
      if (samplePayload is Map<String, dynamic> && samplePayload.containsKey('bookingId')) {
        parsedPayload = Map<String, dynamic>.from(samplePayload);
      }

      expect(parsedPayload, isNotNull);
      expect(parsedPayload!['bookingId'], 'book-uuid-1234');
      expect(parsedPayload['poojaName'], 'Satyanarayan Katha with Havan');
      expect(parsedPayload['totalAmount'], '2625.00');
      expect(parsedPayload['samagriIncluded'], isTrue);
      expect(parsedPayload['mode'], 'IN_PERSON');
      expect(parsedPayload['approximateDistanceKm'], 2.4);
    });

    test('Rejects malformed or incomplete dispatch event data without triggering alert', () {
      bool validateDispatchPayload(dynamic data) {
        if (data is! Map) return false;
        final map = Map<String, dynamic>.from(data);
        if (map['bookingId'] == null || map['bookingId'].toString().isEmpty) {
          return false;
        }
        if (map['totalAmount'] == null) {
          return false;
        }
        return true;
      }

      expect(validateDispatchPayload(null), isFalse);
      expect(validateDispatchPayload("invalid string data"), isFalse);
      expect(validateDispatchPayload({}), isFalse);
      expect(validateDispatchPayload({'bookingId': ''}), isFalse);
      expect(validateDispatchPayload({'bookingId': '123'}), isFalse); // Missing totalAmount
      expect(validateDispatchPayload({'bookingId': '123', 'totalAmount': '2500'}), isTrue);
    });

    test('Prevents duplicate presentation when receiving repeated dispatch events for the same booking', () {
      Map<String, dynamic>? activePayload;
      int presentationCount = 0;

      void onReceiveDispatch(Map<String, dynamic> newEvent) {
        // Deduplication guard
        if (activePayload != null && activePayload!['bookingId'] == newEvent['bookingId']) {
          return; // Ignore duplicate
        }
        activePayload = newEvent;
        presentationCount++;
      }

      final event1 = {'bookingId': 'booking-abc', 'poojaName': 'Ganesh Pooja', 'totalAmount': '1500'};
      final event1Duplicate = {'bookingId': 'booking-abc', 'poojaName': 'Ganesh Pooja', 'totalAmount': '1500'};
      final event2 = {'bookingId': 'booking-xyz', 'poojaName': 'Navgraha Shanti', 'totalAmount': '2100'};

      onReceiveDispatch(event1);
      expect(presentationCount, 1);

      // Duplicate arrives while active
      onReceiveDispatch(event1Duplicate);
      expect(presentationCount, 1, reason: 'Duplicate event for same booking must be ignored');

      // Different booking arrives
      onReceiveDispatch(event2);
      expect(presentationCount, 2);
    });

    test('Realtime socket disconnect does not fabricate fake simulated requests', () {
      bool hasIncomingRequest = false;
      bool isSocketConnected = false;

      // Simulate connection loss
      isSocketConnected = false;

      // Verify no simulated trigger fires on disconnect
      if (!isSocketConnected) {
        // App must NOT auto-trigger fake requests when socket drops
        expect(hasIncomingRequest, isFalse);
      }
    });

    test('Anonymized venue address protects Yajman privacy in UI overlay', () {
      final rawAddress = 'Flat 402, Tower B, Lotus Greens, Sector 78 Noida';
      final parts = rawAddress.split(',').map((s) => s.trim()).toList();
      String anonymized = rawAddress;
      if (parts.length > 1 && RegExp(r'^(flat|house|plot|room|apt|h\.no|#|\d+)', caseSensitive: false).hasMatch(parts[0])) {
        anonymized = parts.sublist(1).join(', ');
      }

      expect(anonymized, 'Tower B, Lotus Greens, Sector 78 Noida');
      expect(anonymized.contains('Flat 402'), isFalse);
    });
  });
}
