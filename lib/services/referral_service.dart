import 'dart:math';

import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';
import 'share_service.dart';

class ReferralService {
  static const String _referralCodeKey = 'referral_code';
  static const String _inviteShareCountKey = 'invite_share_count';

  static Future<int> shareInvite({required String source}) async {
    final code = await _getOrCreateReferralCode();
    final encodedReferrer = Uri.encodeComponent(
      'utm_source=emi_reminder&utm_medium=referral&utm_campaign=$source&ref_code=$code',
    );
    final referralUrl =
        '${ShareService.playStoreUrl}&referrer=$encodedReferrer';

    final message =
        '''
I use EMI Reminder to track EMIs, P2P loans, and reminders in one place.

Install it here:
$referralUrl

Referral code: $code
''';

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
}
