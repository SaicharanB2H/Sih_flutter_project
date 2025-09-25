import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';

  // Default to English
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  // Map of supported languages with their native names
  static const Map<String, Map<String, String>> supportedLanguages = {
    'en': {'name': 'English', 'nativeName': 'English'},
    'hi': {'name': 'Hindi', 'nativeName': 'हिंदी'},
    'ta': {'name': 'Tamil', 'nativeName': 'தமிழ்'},
    'te': {'name': 'Telugu', 'nativeName': 'తెలుగు'},
    'kn': {'name': 'Kannada', 'nativeName': 'ಕನ್ನಡ'},
    'ml': {'name': 'Malayalam', 'nativeName': 'മലയാളം'},
    'gu': {'name': 'Gujarati', 'nativeName': 'ગુજરાતી'},
    'mr': {'name': 'Marathi', 'nativeName': 'मराठी'},
    'pa': {'name': 'Punjabi', 'nativeName': 'ਪੰਜਾਬੀ'},
    'bn': {'name': 'Bengali', 'nativeName': 'বাংলা'},
    'or': {'name': 'Odia', 'nativeName': 'ଓଡ଼ିଆ'},
    'as': {'name': 'Assamese', 'nativeName': 'অসমীয়া'},
  };

  LanguageProvider() {
    _loadSavedLanguage();
  }

  /// Load saved language preference from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      if (savedLanguage != null &&
          supportedLanguages.containsKey(savedLanguage)) {
        _locale = Locale(savedLanguage);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved language: $e');
    }
  }

  /// Change app language and save preference
  Future<void> changeLanguage(String languageCode) async {
    if (!supportedLanguages.containsKey(languageCode)) {
      debugPrint('Unsupported language code: $languageCode');
      return;
    }

    _locale = Locale(languageCode);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }

  /// Get native name of current language
  String get currentLanguageNativeName {
    return supportedLanguages[_locale.languageCode]?['nativeName'] ?? 'English';
  }

  /// Get English name of current language
  String get currentLanguageName {
    return supportedLanguages[_locale.languageCode]?['name'] ?? 'English';
  }

  /// Get list of all supported languages
  List<MapEntry<String, Map<String, String>>> get supportedLanguagesList {
    return supportedLanguages.entries.toList();
  }

  /// Get language code from state/region for auto-detection
  static String getLanguageFromRegion(String? state, String countryCode) {
    if (countryCode != 'IN' || state == null) return 'en';

    // Map Indian states to languages
    const Map<String, String> stateToLanguage = {
      // South
      'Tamil Nadu': 'ta',
      'Karnataka': 'kn',
      'Kerala': 'ml',
      'Andhra Pradesh': 'te',
      'Telangana': 'te',
      'Puducherry': 'ta',
      'Lakshadweep': 'ml',
      // West
      'Maharashtra': 'mr',
      'Goa': 'en',
      'Gujarat': 'gu',
      'Dadra and Nagar Haveli and Daman and Diu': 'gu',
      // East
      'Odisha': 'or',
      'West Bengal': 'bn',
      'Andaman and Nicobar Islands': 'en',
      // North/North-Central
      'Delhi': 'hi',
      'Haryana': 'hi',
      'Punjab': 'pa',
      'Himachal Pradesh': 'hi',
      'Jammu and Kashmir': 'hi',
      'Ladakh': 'hi',
      'Rajasthan': 'hi',
      'Uttar Pradesh': 'hi',
      'Uttarakhand': 'hi',
      'Madhya Pradesh': 'hi',
      'Chhattisgarh': 'hi',
      'Bihar': 'hi',
      'Jharkhand': 'hi',
      // North‑East
      'Assam': 'as',
      'Sikkim': 'en',
      'Meghalaya': 'en',
      'Mizoram': 'en',
      'Nagaland': 'en',
      'Manipur': 'en',
      'Arunachal Pradesh': 'en',
      'Tripura': 'bn',
    };

    final normalizedState = state.trim();

    // Exact match
    if (stateToLanguage.containsKey(normalizedState)) {
      return stateToLanguage[normalizedState]!;
    }

    // Heuristic substring checks
    final lower = normalizedState.toLowerCase();
    if (lower.contains('delhi')) return 'hi';
    if (lower.contains('tamil')) return 'ta';
    if (lower.contains('karnataka')) return 'kn';
    if (lower.contains('kerala')) return 'ml';
    if (lower.contains('andhra')) return 'te';
    if (lower.contains('telangana')) return 'te';
    if (lower.contains('maharashtra')) return 'mr';
    if (lower.contains('gujarat')) return 'gu';
    if (lower.contains('odisha') || lower.contains('orissa')) return 'or';
    if (lower.contains('bengal')) return 'bn';
    if (lower.contains('assam')) return 'as';
    if (lower.contains('punjab')) return 'pa';

    // Default to Hindi for India
    return 'hi';
  }

  /// Auto-detect language based on location (can be called with location data)
  Future<void> autoDetectLanguage(String? state, String countryCode) async {
    final detectedLanguage = getLanguageFromRegion(state, countryCode);
    await changeLanguage(detectedLanguage);
  }
}
