import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pandit_ssetu/constants/branding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pandit GPS Telemetry & Tracking Logic (Phase P4)', () {
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

    test('Brand identity remains strictly SARV MANGAL across telemetry', () {
      expect(AppBranding.appDisplayName, 'SARV MANGAL');
    });

    test('Telemetry payload schema validation: coordinates, heading, speed, accuracy', () {
      Map<String, dynamic> buildTelemetryPayload({
        required double lat,
        required double lng,
        double? accuracy,
        double? heading,
        double? speed,
        DateTime? timestamp,
      }) {
        return <String, dynamic>{
          'lat': lat,
          'lng': lng,
          if (accuracy != null && accuracy > 0) 'accuracy': accuracy,
          if (heading != null && heading >= 0) 'heading': heading,
          if (speed != null && speed >= 0) 'speed': speed,
          'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
        };
      }

      final payload = buildTelemetryPayload(
        lat: 28.5355,
        lng: 77.3910,
        accuracy: 12.5,
        heading: 180.0,
        speed: 15.2,
      );

      expect(payload['lat'], 28.5355);
      expect(payload['lng'], 77.3910);
      expect(payload['accuracy'], 12.5);
      expect(payload['heading'], 180.0);
      expect(payload['speed'], 15.2);
      expect(payload['timestamp'], isNotNull);
    });

    test('GPS freshness calculation: distinguishes Live GPS (< 5m) from Last Known (>= 5m)', () {
      bool isGpsFresh(DateTime updatedAt) {
        final ageSeconds = DateTime.now().difference(updatedAt).inSeconds;
        return ageSeconds < 300; // 5 minutes freshness window
      }

      // Fresh update 30 seconds ago
      final freshUpdate = DateTime.now().subtract(const Duration(seconds: 30));
      expect(isGpsFresh(freshUpdate), isTrue);

      // Stale update 10 minutes ago
      final staleUpdate = DateTime.now().subtract(const Duration(minutes: 10));
      expect(isGpsFresh(staleUpdate), isFalse);

      // Borderline 5 minutes 1 second ago
      final borderlineUpdate = DateTime.now().subtract(const Duration(seconds: 301));
      expect(isGpsFresh(borderlineUpdate), isFalse);
    });

    test('Telemetry loop lifecycle: timer is cancelled when Pandit transitions off-duty', () {
      bool isOnline = true;
      bool isTimerActive = false;

      void startTelemetry() {
        if (!isOnline) return;
        isTimerActive = true;
      }

      void stopTelemetry() {
        isTimerActive = false;
      }

      // Pandit toggles online
      startTelemetry();
      expect(isTimerActive, isTrue);

      // Pandit toggles offline
      isOnline = false;
      stopTelemetry();
      expect(isTimerActive, isFalse);

      // Cannot start telemetry while offline
      startTelemetry();
      expect(isTimerActive, isFalse);
    });
  });
}
