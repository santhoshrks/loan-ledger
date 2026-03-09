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
        final title = await _getNotificationTitle(3, hour);
        final success = await _scheduleNotification(
          id: baseId + notificationIndex,
          title: title,
          body: '$translatedLoanName - $currencySymbol${loan.emiAmount.toStringAsFixed(0)} ${_getLocalizedText('dueOn', lang)} ${loan.dueDay}${_getDaySuffix(loan.dueDay)}',
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
        final title = await _getNotificationTitle(1, hour);
        final success = await _scheduleNotification(
          id: baseId + notificationIndex,
          title: title,
          body: '$translatedLoanName - $currencySymbol${loan.emiAmount.toStringAsFixed(0)} ${_getLocalizedText('dueTomorrow', lang)}',
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
        final title = await _getNotificationTitle(0, hour);
        final success = await _scheduleNotification(
          id: baseId + notificationIndex,
          title: title,
          body: '$translatedLoanName - $currencySymbol${loan.emiAmount.toStringAsFixed(0)} ${_getLocalizedText('dueToday', lang)}',
          scheduledDate: scheduledDate,
          payload: loan.id,
        );
        if (success) scheduledCount++;
      }
      notificationIndex++;
    }

    debugPrint('✅ Scheduled $scheduledCount out of $notificationIndex notifications for ${loan.name}');

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
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

