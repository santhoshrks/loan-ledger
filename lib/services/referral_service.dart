import 'dart:math';

import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';
import 'share_service.dart';

class ReferralService {
  static const String _referralCodeKey = 'referral_code';
  static const String _inviteShareCountKey = 'invite_share_count';

  static Future<int> shareInvite({
    required String source,
    String languageCode = 'en',
  }) async {
    final code = await _getOrCreateReferralCode();
    final encodedReferrer = Uri.encodeComponent(
      'utm_source=emi_reminder&utm_medium=referral&utm_campaign=$source&ref_code=$code',
    );
    final referralUrl =
        '${ShareService.playStoreUrl}&referrer=$encodedReferrer';

    final message = _buildInviteMessage(
      languageCode: languageCode,
      referralUrl: referralUrl,
      referralCode: code,
    );

    await Share.share(
      message.trim(),
      subject: 'Track EMIs easily with EMI Reminder',
    );

    await AnalyticsService.trackInviteShared(source: source);

    return _incrementInviteShareCount();
  }

  static Future<int> getInviteShareCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_inviteShareCountKey) ?? 0;
  }

  static Future<String> _getOrCreateReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    final existingCode = prefs.getString(_referralCodeKey);
    if (existingCode != null && existingCode.isNotEmpty) {
      return existingCode;
    }

    final now = DateTime.now().millisecondsSinceEpoch
        .toRadixString(36)
        .toUpperCase();
    final rand = Random()
        .nextInt(1679616)
        .toRadixString(36)
        .toUpperCase()
        .padLeft(4, '0');
    final code = 'EMI${now.substring(now.length - 4)}$rand';

    await prefs.setString(_referralCodeKey, code);
    return code;
  }

  static Future<int> _incrementInviteShareCount() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(_inviteShareCountKey) ?? 0) + 1;
    await prefs.setInt(_inviteShareCountKey, next);
    return next;
  }

  static String _buildInviteMessage({
    required String languageCode,
    required String referralUrl,
    required String referralCode,
  }) {
    final lang = languageCode.toLowerCase();

    switch (lang) {
      case 'hi':
        return '''
Main EMI Reminder app se EMI aur loan reminders track karta/karti hoon.

Yahan install karein:
$referralUrl

Referral code: $referralCode
''';
      case 'ur':
        return '''
Main EMI Reminder app se EMI aur loan reminders track karta hoon.

Yahan install karein:
$referralUrl

Referral code: $referralCode
''';
      case 'bn':
        return '''
Ami EMI Reminder app diye EMI ar loan reminder track kori.

Install link:
$referralUrl

Referral code: $referralCode
''';
      case 'fil':
        return '''
Ginagamit ko ang EMI Reminder para i-track ang EMI at loan reminders sa isang app.

Install dito:
$referralUrl

Referral code: $referralCode
''';
      case 'id':
        return '''
Saya pakai EMI Reminder untuk melacak EMI dan pengingat pinjaman dalam satu aplikasi.

Install di sini:
$referralUrl

Referral code: $referralCode
''';
      case 'es':
        return '''
Yo uso EMI Reminder para controlar cuotas y recordatorios de prestamos en una sola app.

Instalala aqui:
$referralUrl

Codigo de referido: $referralCode
''';
      default:
        return '''
I use EMI Reminder to track EMIs, P2P loans, and reminders in one place.

Install it here:
$referralUrl

Referral code: $referralCode
''';
    }
  }
}
