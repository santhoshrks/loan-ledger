import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/loan.dart';

class RegionPreferencesService {
  static const String _preferredCurrencyKey = 'preferred_currency_code';
  static const String _preferredCountryKey = 'preferred_country_code';

  static Future<String?> getPreferredCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_preferredCurrencyKey);
  }

  static Future<void> setPreferredCurrency(String? currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    if (currencyCode == null || currencyCode.trim().isEmpty) {
      await prefs.remove(_preferredCurrencyKey);
      return;
    }

    await prefs.setString(_preferredCurrencyKey, currencyCode.toUpperCase());
  }

  static Future<String?> getPreferredCountry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_preferredCountryKey);
  }

  static Future<void> setPreferredCountry(String? countryCode) async {
    final prefs = await SharedPreferences.getInstance();
    if (countryCode == null || countryCode.trim().isEmpty) {
      await prefs.remove(_preferredCountryKey);
      return;
    }

    await prefs.setString(_preferredCountryKey, countryCode.toUpperCase());
  }

  static Future<String> resolveCurrencyCode() async {
    final preferred = await getPreferredCurrency();
    if (preferred != null && preferred.isNotEmpty) {
      return preferred;
    }

    final locale = _deviceLocale();
    return CurrencyHelper.getDefaultCurrencyForLocale(locale);
  }

  static Future<String> resolveCountryCode() async {
    final preferredCountry = await getPreferredCountry();
    if (preferredCountry != null && preferredCountry.isNotEmpty) {
      return preferredCountry;
    }

    return inferCountryCode(_deviceLocale());
  }

  static String inferCountryCode(Locale locale) {
    final direct = locale.countryCode;
    if (direct != null && direct.isNotEmpty) {
      return direct.toUpperCase();
    }

    switch (locale.languageCode.toLowerCase()) {
      case 'hi':
      case 'ta':
      case 'te':
      case 'kn':
      case 'ml':
      case 'mr':
      case 'gu':
        return 'IN';
      case 'ur':
        return 'PK';
      case 'fil':
      case 'tl':
        return 'PH';
      case 'bn':
        return 'BD';
      case 'ms':
        return 'MY';
      case 'my':
        return 'MM';
      case 'ar':
        return 'AE';
      default:
        return 'IN';
    }
  }

  static Locale _deviceLocale() {
    final locale = PlatformDispatcher.instance.locale;
    return locale;
  }
}
