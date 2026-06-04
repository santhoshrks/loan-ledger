import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/loan.dart';
import '../constants/app_constants.dart';

class NotificationService {
  static const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    NotificationConstants.channelId,
    NotificationConstants.channelName,
    channelDescription: NotificationConstants.channelDescription,
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    enableLights: true,
    ledColor: Color.fromARGB(255, 99, 102, 241),
    ledOnMs: 1000,
    ledOffMs: 500,
    icon: '@mipmap/ic_launcher',
    largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    styleInformation: BigTextStyleInformation(''),
    ticker: 'EMI Reminder',
    visibility: NotificationVisibility.public,
    category: AndroidNotificationCategory.reminder,
    fullScreenIntent: true,
    autoCancel: true,
  );

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;
  bool _hasPermission = false;
  String _currentTimezone = 'UTC';

  /// Check if notifications are initialized
  bool get isInitialized => _isInitialized;
  bool get hasPermission => _hasPermission;
  String get currentTimezone => _currentTimezone;

  /// Initialize notification service
  Future<void> init() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Initialize timezone database
    tz.initializeTimeZones();

    // Detect and set local timezone automatically
    await _setLocalTimezone();

    // Android initialization settings
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings (for future use)
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: android,
      iOS: iOS,
    );

    try {
      await _flutterLocalNotificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
      );

      // Get Android-specific implementation
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Create notification channel (required for Android 8.0+)
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          NotificationConstants.channelId,
          NotificationConstants.channelName,
          description: NotificationConstants.channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color.fromARGB(255, 99, 102, 241),
          showBadge: true,
        );
        await androidImplementation.createNotificationChannel(channel);
        debugPrint('✅ Notification channel created: ${NotificationConstants.channelId}');

        // Request notification permission (Android 13+)
        final notifPermission = await androidImplementation.requestNotificationsPermission();
        _hasPermission = notifPermission ?? false;
        debugPrint('✅ Notification permission granted: $_hasPermission');

        // Request exact alarm permission (Android 12+)
        final alarmPermission = await androidImplementation.requestExactAlarmsPermission();
        debugPrint('✅ Exact alarm permission granted: $alarmPermission');

        // Check if notifications are enabled
        final areEnabled = await androidImplementation.areNotificationsEnabled();
        debugPrint('✅ Notifications enabled: $areEnabled');
      }

      _isInitialized = true;
      debugPrint('✅ Notification service initialized successfully');
      debugPrint('🌍 Using timezone: $_currentTimezone');
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Detect and set the device's local timezone
  Future<void> _setLocalTimezone() async {
    try {
      // Get the device's timezone offset
      final now = DateTime.now();
      final offset = now.timeZoneOffset;

      // Try to find matching timezone from the database
      String timezoneName = _getTimezoneFromOffset(offset);

      try {
        tz.setLocalLocation(tz.getLocation(timezoneName));
        _currentTimezone = timezoneName;
        debugPrint('✅ Timezone set to: $timezoneName');
      } catch (e) {
        // Fallback to UTC if timezone not found
        tz.setLocalLocation(tz.UTC);
        _currentTimezone = 'UTC';
        debugPrint('⚠️ Timezone $timezoneName not found, using UTC');
      }
    } catch (e) {
      debugPrint('❌ Error detecting timezone: $e');
      tz.setLocalLocation(tz.UTC);
      _currentTimezone = 'UTC';
    }
  }

  /// Map timezone offset to timezone name
  String _getTimezoneFromOffset(Duration offset) {
    final hours = offset.inHours;
    final minutes = offset.inMinutes.remainder(60);

    // Common timezone mappings
    final timezoneMap = {
      // Asia
      '5:30': 'Asia/Kolkata',      // India
      '5:45': 'Asia/Kathmandu',    // Nepal
      '6:0': 'Asia/Dhaka',         // Bangladesh
      '6:30': 'Asia/Yangon',       // Myanmar
      '7:0': 'Asia/Bangkok',       // Thailand, Vietnam
      '8:0': 'Asia/Singapore',     // Singapore, Malaysia, Philippines
      '9:0': 'Asia/Tokyo',         // Japan, Korea
      '9:30': 'Australia/Darwin',  // Australia Central
      '10:0': 'Australia/Sydney',  // Australia Eastern
      '11:0': 'Pacific/Noumea',    // New Caledonia
      '12:0': 'Pacific/Auckland',  // New Zealand

      // Middle East
      '3:0': 'Asia/Riyadh',        // Saudi Arabia, East Africa
      '3:30': 'Asia/Tehran',       // Iran
      '4:0': 'Asia/Dubai',         // UAE
      '4:30': 'Asia/Kabul',        // Afghanistan

      // Europe
      '0:0': 'Europe/London',      // UK (GMT)
      '1:0': 'Europe/Paris',       // Central Europe, West Africa
      '2:0': 'Europe/Helsinki',    // Eastern Europe, Egypt

      // Americas
      '-5:0': 'America/New_York',  // US Eastern
      '-6:0': 'America/Chicago',   // US Central
      '-7:0': 'America/Denver',    // US Mountain
      '-8:0': 'America/Los_Angeles', // US Pacific
      '-3:0': 'America/Sao_Paulo', // Brazil
      '-4:0': 'America/Caracas',   // Venezuela, Atlantic
    };

    final key = '$hours:${minutes.abs()}';
    return timezoneMap[key] ?? 'UTC';
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
    // Handle navigation or other actions based on payload
  }

  /// Handle background notification tap
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Background notification tapped: ${response.payload}');
  }

  /// Schedule reminders for a loan (next due cycle only)
  /// Set testMode = true to show immediate test notification
  Future<void> scheduleLoadReminders(Loan loan, {bool testMode = false}) async {
    if (!_isInitialized) {
      debugPrint('⚠️ Notification service not initialized');
      return;
    }

    final currencySymbol = loan.currencySymbol;
    final lang = await _getCurrentLanguage();
    final translatedLoanName = _getTranslatedLoanName(loan.name, lang);

    if (testMode) {
      // TEST MODE: Show immediate notification to verify it works
      debugPrint('========================================');
      debugPrint('🧪 TEST MODE: Attempting to show notification');
      debugPrint('Loan: ${loan.name}, EMI: ${loan.emiAmount}');
      try {
        final testTitle = '🔔 ${_getLocalizedText('emiReminderTest', lang)}';
        final testBody = '$translatedLoanName - $currencySymbol${loan.emiAmount.toStringAsFixed(0)} ${_getLocalizedText('notificationWorking', lang)}';

        await _flutterLocalNotificationsPlugin.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          testTitle,
          testBody,
          const NotificationDetails(android: androidDetails),
          payload: loan.id,
        );
        debugPrint('✅ TEST MODE: Notification sent successfully!');
        debugPrint('========================================');
      } catch (e) {
        debugPrint('❌ TEST MODE ERROR: $e');
        debugPrint('========================================');
      }
      return;
    }

    // NORMAL MODE: Schedule based on due date
    final nextDue = loan.getNextDueDate();
    final now = DateTime.now();

    // Calculate base dates for notifications
    final day3Before = nextDue.subtract(const Duration(days: 3));
    final day1Before = nextDue.subtract(const Duration(days: 1));
    final dueDay = nextDue;

    // Use simple IDs based on loan ID
    final baseId = loan.id.hashCode.abs() % 100000;

    debugPrint('📅 Scheduling notifications for ${loan.name}:');
    debugPrint('   Next due date: $nextDue');
    debugPrint('   3 days before: $day3Before');
    debugPrint('   1 day before: $day1Before');
    debugPrint('   Current time: $now');

    // Notification times: 9 AM, 1 PM, 5 PM, 9 PM (every 4 hours)
    final notificationHours = [9, 13, 17, 21];

    int notificationIndex = 0;
    int scheduledCount = 0;

    // Day 1: 3 days before due date
    for (int hour in notificationHours) {
      final scheduledDate = DateTime(day3Before.year, day3Before.month, day3Before.day, hour, 0, 0);
      if (scheduledDate.isAfter(now)) {
        final success = await _scheduleNotification(
          id: baseId + notificationIndex,
          title: _smartTitle(3, lang),
          body: _smartBody(loan.name, currencySymbol, loan.emiAmount, 3, lang),
          scheduledDate: scheduledDate,
          payload: loan.id,
        );
        if (success) scheduledCount++;
      }
      notificationIndex++;
    }

    // Day 2: 1 day before due date
    for (int hour in notificationHours) {
      final scheduledDate = DateTime(day1Before.year, day1Before.month, day1Before.day, hour, 0, 0);
      if (scheduledDate.isAfter(now)) {
        final success = await _scheduleNotification(
          id: baseId + notificationIndex,
          title: _smartTitle(1, lang),
          body: _smartBody(loan.name, currencySymbol, loan.emiAmount, 1, lang),
          scheduledDate: scheduledDate,
          payload: loan.id,
        );
        if (success) scheduledCount++;
      }
      notificationIndex++;
    }

    // Day 3: On due date
    for (int hour in notificationHours) {
      final scheduledDate = DateTime(dueDay.year, dueDay.month, dueDay.day, hour, 0, 0);
      if (scheduledDate.isAfter(now)) {
        final success = await _scheduleNotification(
          id: baseId + notificationIndex,
          title: _smartTitle(0, lang),
          body: _smartBody(loan.name, currencySymbol, loan.emiAmount, 0, lang),
          scheduledDate: scheduledDate,
          payload: loan.id,
        );
        if (success) scheduledCount++;
      }
      notificationIndex++;
    }

    debugPrint('✅ Scheduled $scheduledCount out of $notificationIndex notifications for ${loan.name}');

    // Also schedule 7-day advance smart reminder
    await scheduleSevenDayReminder(loan);

    // Verify by checking pending notifications
    final pendingCount = await getPendingNotificationsCount();
    debugPrint('📊 Total pending notifications now: $pendingCount');
  }

  /// Get notification title based on days remaining and time
  Future<String> _getNotificationTitle(int daysRemaining, int hour) async {
    final lang = await _getCurrentLanguage();
    String timeEmoji;
    if (hour == 9) {
      timeEmoji = '🌅'; // Morning
    } else if (hour == 13) {
      timeEmoji = '☀️'; // Afternoon
    } else if (hour == 17) {
      timeEmoji = '🌆'; // Evening
    } else {
      timeEmoji = '🌙'; // Night
    }

    if (daysRemaining == 3) {
      return '$timeEmoji ${_getLocalizedText('emiDueIn3Days', lang)}';
    } else if (daysRemaining == 1) {
      return '$timeEmoji ${_getLocalizedText('emiDueTomorrow', lang)}';
    } else {
      return '🔴 $timeEmoji ${_getLocalizedText('emiDueToday', lang)}';
    }
  }

  /// Get current language from SharedPreferences
  Future<String> _getCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('selected_language') ?? 'en';
    } catch (e) {
      return 'en';
    }
  }

  /// Get localized text for notifications
  String _getLocalizedText(String key, String lang) {
    final translations = {
      'emiDueIn3Days': {
        'en': 'EMI Due in 3 Days',
        'ta': '3 நாட்களில் EMI செலுத்த வேண்டும்',
        'te': '3 రోజుల్లో EMI చెల్లించాలి',
        'hi': '3 दिनों में EMI देय है',
      },
      'emiDueTomorrow': {
        'en': 'EMI Due Tomorrow',
        'ta': 'நாளை EMI செலுத்த வேண்டும்',
        'te': 'రేపు EMI చెల్లించాలి',
        'hi': 'कल EMI देय है',
      },
      'emiDueToday': {
        'en': 'EMI Due Today!',
        'ta': 'இன்று EMI செலுத்த வேண்டும்!',
        'te': 'ఈరోజు EMI చెల్లించాలి!',
        'hi': 'आज EMI देय है!',
      },
      'dueOn': {
        'en': 'due on',
        'ta': 'செலுத்த வேண்டிய தேதி',
        'te': 'చెల్లించాల్సిన తేదీ',
        'hi': 'देय तिथि',
      },
      'dueTomorrow': {
        'en': 'is due tomorrow! Don\'t forget to pay.',
        'ta': 'நாளை செலுத்த வேண்டும்! மறக்காதீர்கள்.',
        'te': 'రేపు చెల్లించాలి! మర్చిపోకండి.',
        'hi': 'कल देय है! भुगतान करना न भूलें।',
      },
      'dueToday': {
        'en': 'is due today! Pay now to avoid late fees.',
        'ta': 'இன்று செலுத்த வேண்டும்! தாமதக் கட்டணத்தைத் தவிர்க்க இப்போதே செலுத்துங்கள்.',
        'te': 'ఈరోజు చెల్లించాలి! ఆలస్య రుసుము నివారించడానికి ఇప్పుడే చెల్లించండి.',
        'hi': 'आज देय है! विलंब शुल्क से बचने के लिए अभी भुगतान करें।',
      },
      'emiReminderTest': {
        'en': 'EMI Reminder Test',
        'ta': 'EMI நினைவூட்டல் சோதனை',
        'te': 'EMI రిమైండర్ టెస్ట్',
        'hi': 'EMI रिमाइंडर टेस्ट',
      },
      'notificationWorking': {
        'en': 'notification is working!',
        'ta': 'அறிவிப்பு வேலை செய்கிறது!',
        'te': 'నోటిఫికేషన్ పని చేస్తోంది!',
        'hi': 'नोटिफिकेशन काम कर रहा है!',
      },
      'testNotification': {
        'en': 'Test Notification',
        'ta': 'சோதனை அறிவிப்பு',
        'te': 'టెస్ట్ నోటిఫికేషన్',
        'hi': 'टेस्ट नोटिफिकेशन',
      },
      'testNotificationBody': {
        'en': 'EMI Reminder is working! You will receive timely reminders for your EMI payments.',
        'ta': 'EMI நினைவூட்டல் வேலை செய்கிறது! உங்கள் EMI கட்டணங்களுக்கு சரியான நேரத்தில் நினைவூட்டல்களைப் பெறுவீர்கள்.',
        'te': 'EMI రిమైండర్ పని చేస్తోంది! మీ EMI చెల్లింపులకు సకాలంలో రిమైండర్లు అందుకుంటారు.',
        'hi': 'EMI रिमाइंडर काम कर रहा है! आपको अपने EMI भुगतान के लिए समय पर रिमाइंडर मिलेंगे।',
      },
    };

    return translations[key]?[lang] ?? translations[key]?['en'] ?? key;
  }

  /// Get translated loan type name
  String _getTranslatedLoanName(String loanName, String lang) {
    final name = loanName.toLowerCase();

    final loanTypes = {
      'home loan': {'ta': 'வீட்டுக் கடன்', 'te': 'గృహ రుణం', 'hi': 'गृह ऋण'},
      'car loan': {'ta': 'வாகனக் கடன்', 'te': 'వాహన రుణం', 'hi': 'कार ऋण'},
      'personal loan': {'ta': 'தனிநபர் கடன்', 'te': 'వ్యక్తిగత రుణం', 'hi': 'व्यक्तिगत ऋण'},
      'education loan': {'ta': 'கல்விக் கடன்', 'te': 'విద్యా రుణం', 'hi': 'शिक्षा ऋण'},
      'business loan': {'ta': 'தொழில் கடன்', 'te': 'వ్యాపార రుణం', 'hi': 'व्यापार ऋण'},
      'gold loan': {'ta': 'நகைக்கடன்', 'te': 'బంగారు రుణం', 'hi': 'स्वर्ण ऋण'},
      'credit card': {'ta': 'கிரெடிட் கார்டு', 'te': 'క్రెడిట్ కార్డ్', 'hi': 'क्रेडिट कार्ड'},
    };

    for (var entry in loanTypes.entries) {
      if (name == entry.key) {
        return entry.value[lang] ?? loanName;
      }
    }
    return loanName;
  }

  /// Schedule a single notification
  Future<bool> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    try {
      final now = DateTime.now();

      // Prevent scheduling past dates
      if (scheduledDate.isBefore(now)) {
        debugPrint('⏭️ Skipping notification $id - scheduled date ($scheduledDate) is in the past');
        return false;
      }

      // Use zonedSchedule for all future notifications
      final tzScheduledDate = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      debugPrint('⏰ Scheduling notification $id at $tzScheduledDate (local: $scheduledDate)');

      // Try alarmClock mode first (better for Chinese phones like Realme, Xiaomi, OPPO)
      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduledDate,
          const NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        debugPrint('✅ Notification $id scheduled with alarmClock mode');
        return true;
      } catch (alarmClockError) {
        debugPrint('⚠️ alarmClock mode failed: $alarmClockError, trying exactAllowWhileIdle...');
      }

      // Fallback to exactAllowWhileIdle
      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduledDate,
          const NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        debugPrint('✅ Notification $id scheduled with exactAllowWhileIdle mode');
        return true;
      } catch (exactError) {
        debugPrint('⚠️ exactAllowWhileIdle failed: $exactError, trying inexact...');
      }

      // Final fallback to inexact
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint('✅ Notification $id scheduled with inexact mode');
      return true;
    } catch (e) {
      debugPrint('❌ All scheduling methods failed for notification $id: $e');
      return false;
    }
  }

  /// Cancel reminders for a loan
  Future<void> cancelLoanReminders(String loanId, {int tenureMonths = 12}) async {
    // Cancel all 12 notifications (4 per day × 3 days)
    final baseId = loanId.hashCode.abs() % 100000;
    try {
      for (int i = 0; i < 12; i++) {
        await _flutterLocalNotificationsPlugin.cancel(baseId + i);
      }
      debugPrint('✅ Cancelled all notifications for loan: $loanId');
    } catch (e) {
      debugPrint('❌ Error cancelling notifications: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('✅ All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling all notifications: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // P2P LOAN INTEREST REMINDERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Schedule monthly interest reminders for a flat-interest P2P loan.
  /// Uses IDs in the 500000+ range to avoid collisions with regular loan IDs.
  Future<void> scheduleP2PInterestReminder({
    required String loanId,
    required String personName,
    required double monthlyInterest,
    required int dueDay,         // 1-31: day of month interest is due
    required bool isLent,        // true = they owe you, false = you owe them
  }) async {
    if (!_isInitialized) return;

    // Cancel existing reminders for this loan first
    await cancelP2PReminders(loanId);

    final now = DateTime.now();
    final baseId = (loanId.hashCode.abs() % 100000) + 500000;

    // Compute the next occurrence of dueDay
    int year = now.year, month = now.month;
    int clampedDay(int y, int m) =>
        dueDay.clamp(1, DateTime(y, m + 1, 0).day);

    DateTime nextDue = DateTime(year, month, clampedDay(year, month));
    if (!nextDue.isAfter(now)) {
      month++;
      if (month > 12) { month = 1; year++; }
      nextDue = DateTime(year, month, clampedDay(year, month));
    }

    final amtStr = '₹${monthlyInterest.toStringAsFixed(0)}';
    final who = isLent ? personName : 'you';
    final action = isLent ? 'collect interest from' : 'pay interest to';
    final body = 'Monthly interest $amtStr is due — $action $personName';

    int idx = 0;

    Future<void> scheduleIfFuture(DateTime dt, String title) async {
      if (dt.isAfter(now)) {
        await _scheduleNotification(
          id: baseId + idx,
          title: title,
          body: body,
          scheduledDate: dt,
          payload: 'p2p:$loanId',
        );
      }
      idx++;
    }

    // 3 days before
    await scheduleIfFuture(
      DateTime(nextDue.year, nextDue.month, nextDue.day - 3, 9, 0),
      '💰 P2P Interest Due in 3 Days',
    );
    // 1 day before
    await scheduleIfFuture(
      DateTime(nextDue.year, nextDue.month, nextDue.day - 1, 9, 0),
      '💰 P2P Interest Due Tomorrow',
    );
    // On due day — morning
    await scheduleIfFuture(
      DateTime(nextDue.year, nextDue.month, nextDue.day, 9, 0),
      '🔔 P2P Interest Due Today!',
    );
    // On due day — evening reminder
    await scheduleIfFuture(
      DateTime(nextDue.year, nextDue.month, nextDue.day, 18, 0),
      '⏰ Reminder: P2P Interest Due Today!',
    );

    debugPrint('✅ P2P reminders scheduled for $personName — next due: $nextDue');
  }

  /// Cancel all scheduled reminders for a P2P loan
  Future<void> cancelP2PReminders(String loanId) async {
    if (!_isInitialized) return;
    final baseId = (loanId.hashCode.abs() % 100000) + 500000;
    for (int i = 0; i < 6; i++) {
      try {
        await _flutterLocalNotificationsPlugin.cancel(baseId + i);
      } catch (_) {}
    }
  }

  /// Test P2P notification
  Future<void> showP2PTestNotification(String personName, double amount) async {
    try {
      await _flutterLocalNotificationsPlugin.show(
        999998,
        '💰 P2P Interest Reminder Test',
        'Monthly interest ₹${amount.toStringAsFixed(0)} from $personName — reminder is working!',
        const NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      debugPrint('❌ P2P test notification error: $e');
    }
  }

  /// Test notification
  Future<void> showTestNotification() async {
    try {
      final lang = await _getCurrentLanguage();
      final title = '🔔 ${_getLocalizedText('testNotification', lang)}';
      final body = _getLocalizedText('testNotificationBody', lang);

      await _flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        const NotificationDetails(android: androidDetails),
      );
      debugPrint('✅ Test notification sent in language: $lang');
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
    }
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    try {
      final pending = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      return pending.length;
    } catch (e) {
      debugPrint('❌ Error getting pending notifications: $e');
      return 0;
    }
  }

  /// Get list of pending notifications for debugging
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ Error getting pending notifications: $e');
      return [];
    }
  }

  /// Check if all required permissions are granted
  Future<Map<String, bool>> checkAllPermissions() async {
    final permissions = <String, bool>{
      'notifications': false,
      'exactAlarms': false,
      'notificationsEnabled': false,
    };

    try {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        permissions['notificationsEnabled'] =
            await androidImplementation.areNotificationsEnabled() ?? false;
      }

      permissions['notifications'] = _hasPermission;
      permissions['exactAlarms'] = true; // Assume granted if no error during init
    } catch (e) {
      debugPrint('❌ Error checking permissions: $e');
    }

    return permissions;
  }

  /// Check if notification permission is granted
  Future<bool> checkPermissions() async {
    try {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        return await androidImplementation.areNotificationsEnabled() ?? false;
      }
      return _hasPermission;
    } catch (e) {
      debugPrint('❌ Error checking notification permission: $e');
      return false;
    }
  }

  /// Check if exact alarm permission is granted
  Future<bool> checkExactAlarmPermission() async {
    try {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        return await androidImplementation.canScheduleExactNotifications() ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('❌ Error checking exact alarm permission: $e');
      return true;
    }
  }

  /// Get debug info for troubleshooting
  Future<String> getDebugInfo() async {
    final buffer = StringBuffer();

    buffer.writeln('=== Notification Debug Info ===');
    buffer.writeln('Initialized: $_isInitialized');
    buffer.writeln('Has Permission: $_hasPermission');
    buffer.writeln('Timezone: $_currentTimezone');
    buffer.writeln('Current Time: ${DateTime.now()}');

    try {
      final pending = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      buffer.writeln('Pending Count: ${pending.length}');

      if (pending.isNotEmpty) {
        buffer.writeln('\nScheduled Notifications:');
        for (var notif in pending.take(10)) {
          buffer.writeln('  ID: ${notif.id}, Title: ${notif.title}');
        }
        if (pending.length > 10) {
          buffer.writeln('  ... and ${pending.length - 10} more');
        }
      }
    } catch (e) {
      buffer.writeln('Error getting pending: $e');
    }

    return buffer.toString();
  }

  /// Get day suffix (st, nd, rd, th)
  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  // ─────────────────────────────────────────────
  // SMART NOTIFICATIONS — Engaging copy per stage
  // ─────────────────────────────────────────────

  /// Returns a smart, engaging notification body based on days until due
  String _smartBody(String loanName, String symbol, double amount, int daysLeft, String lang) {
    final amt = '${symbol}${amount.toStringAsFixed(0)}';
    if (daysLeft == 7) {
      return _smartText(lang, {
        'en': '📅 $loanName EMI of $amt is due in 7 days. Plan ahead to avoid surprises!',
        'hi': '📅 $loanName की $amt EMI 7 दिनों में है। अभी से तैयारी करें!',
        'ta': '📅 $loanName EMI $amt — 7 நாட்களில் செலுத்த வேண்டும். முன்கூட்டியே திட்டமிடுங்கள்!',
        'te': '📅 $loanName EMI $amt — 7 రోజుల్లో చెల్లించాలి. ముందే ప్లాన్ చేయండి!',
      });
    } else if (daysLeft == 3) {
      return _smartText(lang, {
        'en': '⚠️ $loanName EMI of $amt due in 3 days. Set aside the amount now!',
        'hi': '⚠️ $loanName की $amt EMI 3 दिनों में है। अभी राशि तैयार रखें!',
        'ta': '⚠️ $loanName EMI $amt — 3 நாட்களில் செலுத்த வேண்டும்!',
        'te': '⚠️ $loanName EMI $amt — 3 రోజుల్లో చెల్లించాలి!',
      });
    } else if (daysLeft == 1) {
      return _smartText(lang, {
        'en': '🔔 Tomorrow is the day! $loanName EMI of $amt is due. Don\'t miss it!',
        'hi': '🔔 कल $loanName की $amt EMI देय है। भूलें नहीं!',
        'ta': '🔔 நாளை $loanName EMI $amt செலுத்த வேண்டும். மறக்காதீர்கள்!',
        'te': '🔔 రేపు $loanName EMI $amt చెల్లించాలి. మర్చిపోకండి!',
      });
    } else {
      return _smartText(lang, {
        'en': '🚨 Today is the last day! Pay $loanName EMI of $amt now to avoid late fees.',
        'hi': '🚨 आज आखिरी दिन! $loanName की $amt EMI अभी दें — देरी शुल्क से बचें।',
        'ta': '🚨 இன்றே கடைசி நாள்! $loanName EMI $amt இப்போதே செலுத்துங்கள்.',
        'te': '🚨 ఈరోజే చివరి రోజు! $loanName EMI $amt ఇప్పుడే చెల్లించండి.',
      });
    }
  }

  String _smartText(String lang, Map<String, String> map) =>
      map[lang] ?? map['en'] ?? '';

  /// Smart title per urgency level
  String _smartTitle(int daysLeft, String lang) {
    if (daysLeft == 7) {
      return _smartText(lang, {'en': '💡 EMI Reminder — 1 Week Left', 'hi': '💡 EMI याद — 1 सप्ताह बाकी', 'ta': '💡 EMI நினைவூட்டல் — 1 வாரம் உள்ளது', 'te': '💡 EMI రిమైండర్ — 1 వారం మిగిలింది'});
    } else if (daysLeft == 3) {
      return _smartText(lang, {'en': '⚠️ EMI Due in 3 Days', 'hi': '⚠️ 3 दिनों में EMI देय', 'ta': '⚠️ 3 நாட்களில் EMI', 'te': '⚠️ 3 రోజుల్లో EMI'});
    } else if (daysLeft == 1) {
      return _smartText(lang, {'en': '🔔 EMI Due Tomorrow!', 'hi': '🔔 कल EMI देय है!', 'ta': '🔔 நாளை EMI!', 'te': '🔔 రేపు EMI!'});
    } else {
      return _smartText(lang, {'en': '🚨 EMI Due TODAY!', 'hi': '🚨 आज EMI देय है!', 'ta': '🚨 இன்று EMI!', 'te': '🚨 ఈరోజు EMI!'});
    }
  }

  /// Schedule 7-day advance reminder (smart notification)
  Future<void> scheduleSevenDayReminder(Loan loan) async {
    if (!_isInitialized || !_hasPermission) return;
    final lang = await _getCurrentLanguage();
    final nextDue = loan.getNextDueDate();
    final now = DateTime.now();
    final day7Before = nextDue.subtract(const Duration(days: 7));
    final scheduled = DateTime(day7Before.year, day7Before.month, day7Before.day, 9, 0, 0);
    if (scheduled.isBefore(now)) return;

    final baseId = loan.id.hashCode.abs() % 100000;
    await _scheduleNotification(
      id: baseId + 900,
      title: _smartTitle(7, lang),
      body: _smartBody(loan.name, loan.currencySymbol, loan.emiAmount, 7, lang),
      scheduledDate: scheduled,
      payload: loan.id,
    );
    debugPrint('✅ 7-day reminder scheduled for ${loan.name} on $scheduled');
  }

  // ─────────────────────────────────────────────
  // MONTHLY SUMMARY NOTIFICATION
  // ─────────────────────────────────────────────

  /// Schedule a monthly summary notification on the 1st of every month at 8 AM
  Future<void> scheduleMonthSummaryNotification(List<Loan> loans) async {
    if (!_isInitialized || !_hasPermission || loans.isEmpty) return;

    // Cancel previous monthly summary (id 999999)
    await _flutterLocalNotificationsPlugin.cancel(999999);

    final lang = await _getCurrentLanguage();
    final now = DateTime.now();

    // Schedule for 1st of next month at 8:00 AM
    final nextMonth = DateTime(now.month == 12 ? now.year + 1 : now.year,
        now.month == 12 ? 1 : now.month + 1, 1, 8, 0, 0);

    final totalEmi = loans.fold<double>(0, (s, l) => s + l.emiAmount);
    final loanCount = loans.length;
    final symbol = loans.first.currencySymbol;
    final totalStr = '$symbol${totalEmi.toStringAsFixed(0)}';

    // Upcoming due loans this month
    final dueSoon = loans.where((l) => !l.isPaid && l.daysUntilDue() <= 7).length;

    final title = _smartText(lang, {
      'en': '📊 Your Monthly EMI Summary',
      'hi': '📊 आपका मासिक EMI सारांश',
      'ta': '📊 உங்கள் மாதாந்திர EMI சுருக்கம்',
      'te': '📊 మీ నెలవారీ EMI సారాంశం',
    });

    final body = _smartText(lang, {
      'en': 'You have $loanCount loans totalling $totalStr/month.${dueSoon > 0 ? ' $dueSoon payments due soon!' : ' Stay on track! 💪'}',
      'hi': 'आपके $loanCount लोन हैं, कुल $totalStr/माह।${dueSoon > 0 ? ' $dueSoon भुगतान जल्द देय है!' : ' ट्रैक पर रहें! 💪'}',
      'ta': 'உங்களிடம் $loanCount கடன்கள் உள்ளன, மொத்தம் $totalStr/மாதம்।${dueSoon > 0 ? ' $dueSoon கொடுப்பனவுகள் விரைவில்!' : ' தொடர்ந்து முன்னேறுங்கள்! 💪'}',
      'te': 'మీకు $loanCount రుణాలు ఉన్నాయి, మొత్తం $totalStr/నెల।${dueSoon > 0 ? ' $dueSoon చెల్లింపులు త్వరలో!' : ' ట్రాక్‌లో ఉండండి! 💪'}',
    });

    await _scheduleNotification(
      id: 999999,
      title: title,
      body: body,
      scheduledDate: nextMonth,
      payload: 'monthly_summary',
    );
    debugPrint('✅ Monthly summary notification scheduled for $nextMonth');
  }
}

