import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_ui_config.dart';
import 'api_service.dart';

class AppConfigService extends ChangeNotifier {
  static final AppConfigService _instance = AppConfigService._internal();
  factory AppConfigService() => _instance;
  AppConfigService._internal();

  static const String _storageKey = 'sarv_cached_app_ui_config';

  AppUiConfig _config = const AppUiConfig();
  bool _isLoading = false;
  DateTime? _lastFetchedAt;

  AppUiConfig get config => _config;
  AppUiThemeConfig get theme => _config.theme;
  bool get isLoading => _isLoading;
  DateTime? get lastFetchedAt => _lastFetchedAt;

  /// Returns sections sorted by `order`, filtered by `enabled`
  List<AppSectionConfig> get enabledSections {
    final list = _config.sections.where((s) => s.enabled).toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  /// Initialize: load cached configuration immediately, then fetch fresh
  Future<void> initialize() async {
    await loadFromCache();
    await fetchRemoteConfig();
  }

  /// Load cached configuration from SharedPreferences for instant zero-latency UI
  Future<void> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(_storageKey);
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final decoded = jsonDecode(cachedStr) as Map<String, dynamic>;
        _config = AppUiConfig.fromJson(decoded);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AppConfigService: Failed to load from cache: $e');
    }
  }

  /// Fetch active configuration from remote backend endpoint (/api/v1/app-config)
  Future<bool> fetchRemoteConfig({http.Client? client}) async {
    _isLoading = true;
    final httpClient = client ?? http.Client();

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/app-config');
      final response = await httpClient.get(uri).timeout(
        const Duration(seconds: 6),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          final configJson = data['config'] as Map<String, dynamic>?;

          if (configJson != null) {
            _config = AppUiConfig.fromJson(configJson);
            _lastFetchedAt = DateTime.now();

            // Persist to cache
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_storageKey, jsonEncode(configJson));
            } catch (_) {}

            notifyListeners();
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('AppConfigService: Remote config fetch failed (using fallback/cache): $e');
    } finally {
      _isLoading = false;
      if (client == null) {
        httpClient.close();
      }
    }
    return false;
  }

  /// Reset to safe default configuration
  void resetToDefaults() {
    _config = const AppUiConfig();
    notifyListeners();
  }
}

final appConfigService = AppConfigService();
