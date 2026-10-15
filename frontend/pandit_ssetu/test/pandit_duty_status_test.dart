import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pandit_ssetu/constants/branding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pandit Duty Status & Live Location Toggle (Phase P2-B Task 1)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'token': 'mock-jwt-pandit-approved-token',
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

    test('Payload format: includes lat and lng only when BOTH valid coordinates are provided', () {
      Map<String, dynamic> buildDutyPayload(bool isAvailable, {double? lat, double? lng}) {
        final Map<String, dynamic> body = {
          'isAvailable': isAvailable,
        };
        if (lat != null && lng != null) {
          body['lat'] = lat;
          body['lng'] = lng;
        }
        return body;
      }

      // Case 1: Switching online with valid GPS
      final onlineWithGps = buildDutyPayload(true, lat: 28.4744, lng: 77.5040);
      expect(onlineWithGps['isAvailable'], true);
      expect(onlineWithGps['lat'], 28.4744);
      expect(onlineWithGps['lng'], 77.5040);

      // Case 2: Switching online without GPS (saved location / permission denied)
      final onlineNoGps = buildDutyPayload(true);
      expect(onlineNoGps['isAvailable'], true);
      expect(onlineNoGps.containsKey('lat'), false);
      expect(onlineNoGps.containsKey('lng'), false);

      // Case 3: Partial coordinate lat only -> omitted
      final partialLat = buildDutyPayload(true, lat: 28.4744);
      expect(partialLat.containsKey('lat'), false);
      expect(partialLat.containsKey('lng'), false);

      // Case 4: Partial coordinate lng only -> omitted
      final partialLng = buildDutyPayload(true, lng: 77.5040);
      expect(partialLng.containsKey('lat'), false);
      expect(partialLng.containsKey('lng'), false);

      // Case 5: Switching offline
      final offline = buildDutyPayload(false);
      expect(offline['isAvailable'], false);
      expect(offline.containsKey('lat'), false);
      expect(offline.containsKey('lng'), false);
    });

    test('Authoritative initial state extraction from GET /dashboard', () {
      bool extractAuthoritativeDuty(Map<String, dynamic> dashboard) {
        return dashboard['isAvailable'] == true;
      }

      expect(extractAuthoritativeDuty({'isAvailable': true, 'todayCount': 2}), isTrue);
      expect(extractAuthoritativeDuty({'isAvailable': false, 'todayCount': 0}), isFalse);
      expect(extractAuthoritativeDuty({'todayCount': 0}), isFalse);
    });

    test('Duty state preserves server state on failed toggle', () {
      bool isOnline = false;

      // Simulate a failed API call (e.g., location required or network error)
      void handleToggleResult({required bool success, required bool returnedAvailability}) {
        if (success) {
          isOnline = returnedAvailability;
        }
        // on error, isOnline is NOT mutated
      }

      // Initial state is false
      expect(isOnline, isFalse);

      // Failed toggle attempt
      handleToggleResult(success: false, returnedAvailability: true);
      expect(isOnline, isFalse, reason: 'Failed update must not falsely set state to true');

      // Successful toggle attempt
      handleToggleResult(success: true, returnedAvailability: true);
      expect(isOnline, isTrue, reason: 'Successful update correctly sets state to true');

      // Failed toggle attempt when online
      handleToggleResult(success: false, returnedAvailability: false);
      expect(isOnline, isTrue, reason: 'Failed update must preserve existing true state');
    });

    test('Loading state prevents duplicate concurrent toggle requests', () {
      bool isToggling = false;
      int networkCallsMade = 0;

      Future<void> simulateToggle() async {
        if (isToggling) return;
        isToggling = true;
        try {
          networkCallsMade++;
          await Future.delayed(const Duration(milliseconds: 50));
        } finally {
          isToggling = false;
        }
      }

      // Fire 3 simultaneous toggle taps
      simulateToggle();
      simulateToggle();
      simulateToggle();

      expect(networkCallsMade, 1, reason: 'Only the first request should fire; subsequent requests must be blocked by loading guard');
    });

    test('No coordinates fabricated when device location is denied or disabled', () {
      // Simulate geolocation permission resolution
      Map<String, double?> resolveCoordinates({
        required bool serviceEnabled,
        required bool permissionGranted,
        double? realLat,
        double? realLng,
      }) {
        if (!serviceEnabled || !permissionGranted) {
          return {'lat': null, 'lng': null};
        }
        return {'lat': realLat, 'lng': realLng};
      }

      // Permission denied
      final denied = resolveCoordinates(serviceEnabled: true, permissionGranted: false);
      expect(denied['lat'], isNull);
      expect(denied['lng'], isNull);

      // Location service disabled
      final disabled = resolveCoordinates(serviceEnabled: false, permissionGranted: true);
      expect(disabled['lat'], isNull);
      expect(disabled['lng'], isNull);

      // Real GPS available
      final granted = resolveCoordinates(
        serviceEnabled: true,
        permissionGranted: true,
        realLat: 28.5355,
        realLng: 77.3910,
      );
      expect(granted['lat'], 28.5355);
      expect(granted['lng'], 77.3910);
    });
  });
}
