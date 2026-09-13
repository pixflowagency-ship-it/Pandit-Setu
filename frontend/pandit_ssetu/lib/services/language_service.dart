import 'package:flutter/material.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  bool _isHindi = false;
  bool get isHindi => _isHindi;

  void toggleLanguage() {
    _isHindi = !_isHindi;
    notifyListeners();
  }

  void setHindi(bool val) {
    _isHindi = val;
    notifyListeners();
  }

  // Common UI Translation Dictionary
  String tr(String enKey, String hiKey) {
    return _isHindi ? hiKey : enKey;
  }
}

final languageService = LanguageService();
