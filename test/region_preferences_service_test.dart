import 'dart:ui';

import 'package:emi_reminder/models/loan.dart';
import 'package:emi_reminder/services/region_preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegionPreferencesService', () {
    test('infers country from explicit locale country code', () {
      expect(
        RegionPreferencesService.inferCountryCode(
          const Locale.fromSubtags(languageCode: 'en', countryCode: 'US'),
        ),
        'US',
      );
    });

    test('infers country from language when country code is missing', () {
      expect(
        RegionPreferencesService.inferCountryCode(const Locale('ur')),
        'PK',
      );
      expect(
        RegionPreferencesService.inferCountryCode(const Locale('fil')),
        'PH',
      );
      expect(
        RegionPreferencesService.inferCountryCode(const Locale('bn')),
        'BD',
      );
    });
  });

  group('CurrencyHelper locale mapping', () {
    test('maps gulf and myanmar locales to local currencies', () {
      expect(
        CurrencyHelper.getDefaultCurrencyForLocale(
          const Locale.fromSubtags(languageCode: 'ar', countryCode: 'AE'),
        ),
        'AED',
      );
      expect(
        CurrencyHelper.getDefaultCurrencyForLocale(
          const Locale.fromSubtags(languageCode: 'ar', countryCode: 'QA'),
        ),
        'QAR',
      );
      expect(
        CurrencyHelper.getDefaultCurrencyForLocale(
          const Locale.fromSubtags(languageCode: 'my', countryCode: 'MM'),
        ),
        'MMK',
      );
    });
  });
}
