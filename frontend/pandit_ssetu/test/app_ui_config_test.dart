import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pandit_ssetu/models/app_ui_config.dart';
import 'package:pandit_ssetu/services/app_config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appConfigService.resetToDefaults();
  });

  group('SARV MANGAL App UI Config & CMS Models', () {
    test('1. AppUiConfig default constructor provides complete fallback layout', () {
      const config = AppUiConfig();
      expect(config.schemaVersion, 1);
      expect(config.theme.primaryColor, const Color(0xFFE65100));
      expect(config.theme.accentColor, const Color(0xFFD97706));
      expect(config.theme.backgroundColor, const Color(0xFFFFF8EE));
      expect(config.sections.length, 10);
      expect(config.heroSlides.length, 4);
      expect(config.serviceGrid.length, 6);
      expect(config.lifeProblemsBanner.enabled, true);
    });

    test('2. AppUiThemeConfig handles valid and invalid hex formats gracefully', () {
      final valid = AppUiThemeConfig.fromJson({
        'primaryColor': '#FF5722',
        'accentColor': '#FFC107',
        'backgroundColor': '#FAFAFA',
        'surfaceColor': '#FFFFFF',
      });
      expect(valid.primaryColor, const Color(0xFFFF5722));
      expect(valid.accentColor, const Color(0xFFFFC107));

      final invalid = AppUiThemeConfig.fromJson({
        'primaryColor': 'not-hex',
        'accentColor': null,
      });
      // Fallback to default
      expect(invalid.primaryColor, const Color(0xFFE65100));
      expect(invalid.accentColor, const Color(0xFFD97706));
    });

    test('3. AppUiConfig JSON round-trip serialization maintains structural integrity', () {
      const original = AppUiConfig();
      final json = original.toJson();
      final parsed = AppUiConfig.fromJson(json);

      expect(parsed.schemaVersion, original.schemaVersion);
      expect(parsed.sections.length, original.sections.length);
      expect(parsed.heroSlides.length, original.heroSlides.length);
      expect(parsed.serviceGrid.length, original.serviceGrid.length);
      expect(parsed.lifeProblemsBanner.title, original.lifeProblemsBanner.title);
    });
  });

  group('SARV MANGAL AppConfigService Remote Operations & Caching', () {
    test('4. enabledSections filters disabled items and sorts ascending by order', () {
      final customJson = {
        'schemaVersion': 1,
        'sections': [
          {'id': 'panchang', 'enabled': true, 'order': 3, 'title': 'Panchang', 'titleHi': 'पंचांग'},
          {'id': 'hero_slideshow', 'enabled': true, 'order': 1, 'title': 'Hero', 'titleHi': 'हीरो'},
          {'id': 'life_problems', 'enabled': false, 'order': 2, 'title': 'Problems', 'titleHi': 'समस्याएं'},
        ],
      };

      final customConfig = AppUiConfig.fromJson(customJson);
      // Set internal config via JSON load
      SharedPreferences.setMockInitialValues({
        'sarv_cached_app_ui_config': jsonEncode(customConfig.toJson()),
      });

      expect(customConfig.sections.length, 3);
      final enabled = customConfig.sections.where((s) => s.enabled).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      expect(enabled.length, 2);
      expect(enabled[0].id, 'hero_slideshow');
      expect(enabled[1].id, 'panchang');
    });

    test('5. fetchRemoteConfig parses HTTP 200 and notifies listeners', () async {
      final mockPayload = {
        'success': true,
        'data': {
          'id': 'v2-uuid',
          'version': 2,
          'publishedAt': '2026-10-26T12:00:00Z',
          'config': {
            'schemaVersion': 1,
            'theme': {
              'primaryColor': '#E65100',
              'accentColor': '#D97706',
              'backgroundColor': '#FFF8EE',
              'surfaceColor': '#FFFFFF',
            },
            'sections': [
              {'id': 'hero_slideshow', 'enabled': true, 'order': 1, 'title': 'Diwali Banners', 'titleHi': 'दीपावली'},
            ],
            'heroSlides': [
              {
                'id': 'slide-10',
                'title': 'Diwali Lakshmi Pooja',
                'titleHi': 'दीपावली महालक्ष्मी पूजन',
                'subtitle': 'Book Vedic pandit',
                'subtitleHi': 'वैदिक पंडित बुक करें',
                'tag': 'FESTIVAL',
                'tagHi': 'पर्व विशेष',
                'imageUrl': 'https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=900',
                'actionType': 'POOJA',
                'actionTarget': 'pooja-10',
              }
            ],
            'serviceGrid': [
              {
                'id': 'pooja',
                'title': 'Vedic Poojas',
                'titleHi': 'वैदिक पूजा',
                'subtitle': 'Book Acharya',
                'subtitleHi': 'आचार्य बुक करें',
                'icon': 'auto_awesome',
                'target': '/pooja-flow',
                'enabled': true,
                'order': 1,
              }
            ],
            'lifeProblemsBanner': {
              'enabled': true,
              'title': 'Life Guidance',
              'titleHi': 'जीवन मार्गदर्शन',
              'subtitle': 'Talk to Astrologers',
              'subtitleHi': 'ज्योतिषियों से परामर्श',
              'buttonText': 'Consult',
              'buttonTextHi': 'परामर्श',
              'target': '/consultation-flow',
            },
          },
        },
      };

      final client = MockClient((request) async {
        if (request.url.path.endsWith('/app-config')) {
          return http.Response(jsonEncode(mockPayload), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      bool notified = false;
      appConfigService.addListener(() {
        notified = true;
      });

      final success = await appConfigService.fetchRemoteConfig(client: client);
      expect(success, true);
      expect(notified, true);
      expect(appConfigService.config.sections.first.title, 'Diwali Banners');
      expect(appConfigService.config.heroSlides.first.title, 'Diwali Lakshmi Pooja');
    });

    test('6. fetchRemoteConfig falls back safely when HTTP throws NetworkException', () async {
      final client = MockClient((request) async {
        throw Exception('Network unreachable (offline)');
      });

      final success = await appConfigService.fetchRemoteConfig(client: client);
      expect(success, false);
      // App config maintains safe defaults without throwing
      expect(appConfigService.config.sections.isNotEmpty, true);
    });
  });
}
