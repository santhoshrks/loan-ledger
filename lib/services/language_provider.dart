import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';

  late SharedPreferences _prefs;
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final savedLanguage = _prefs.getString(_languageKey) ?? 'en';
    _currentLocale = Locale(savedLanguage);
  }

  Future<void> setLanguage(String languageCode) async {
    _currentLocale = Locale(languageCode);
    await _prefs.setString(_languageKey, languageCode);
    notifyListeners();
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'ta': return 'தமிழ் (Tamil)';
      case 'te': return 'తెలుగు (Telugu)';
      case 'hi': return 'हिन्दी (Hindi)';
      case 'kn': return 'ಕನ್ನಡ (Kannada)';
      case 'ml': return 'മലയാളം (Malayalam)';
      case 'mr': return 'मराठी (Marathi)';
      case 'bn': return 'বাংলা (Bengali)';
      case 'gu': return 'ગુજરાતી (Gujarati)';
      case 'id': return 'Bahasa Indonesia';
      case 'fil': return 'Filipino (Tagalog)';
      default: return 'English';
    }
  }
}

