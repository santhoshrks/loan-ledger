import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/loan.dart';
import '../models/subscription.dart';
import '../constants/app_constants.dart';
import 'reminder_experiment_service.dart';

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

  static const int _sevenDayReminderOffset = 900;
  static const int _monthlySummaryNotificationId = 999999;
  static const int _subscriptionIdRangeStart = 200000;

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

    const settings = InitializationSettings(android: android, iOS: iOS);

    try {
      await _flutterLocalNotificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse:
            _onBackgroundNotificationTapped,
      );

      // Get Android-specific implementation
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

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
        debugPrint(
          '✅ Notification channel created: ${NotificationConstants.channelId}',
        );

        // Request notification permission (Android 13+)
        final notifPermission = await androidImplementation
            .requestNotificationsPermission();
        _hasPermission = notifPermission ?? false;
        debugPrint('✅ Notification permission granted: $_hasPermission');

        // Request exact alarm permission (Android 12+)
        final alarmPermission = await androidImplementation
            .requestExactAlarmsPermission();
        debugPrint('✅ Exact alarm permission granted: $alarmPermission');

        // Check if notifications are enabled
        final areEnabled = await androidImplementation
            .areNotificationsEnabled();
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
      '5:30': 'Asia/Kolkata', // India
      '5:45': 'Asia/Kathmandu', // Nepal
      '6:0': 'Asia/Dhaka', // Bangladesh
      '6:30': 'Asia/Yangon', // Myanmar
      '7:0': 'Asia/Bangkok', // Thailand, Vietnam
      '8:0': 'Asia/Singapore', // Singapore, Malaysia, Philippines
      '9:0': 'Asia/Tokyo', // Japan, Korea
      '9:30': 'Australia/Darwin', // Australia Central
      '10:0': 'Australia/Sydney', // Australia Eastern
      '11:0': 'Pacific/Noumea', // New Caledonia
      '12:0': 'Pacific/Auckland', // New Zealand
      // Middle East
      '3:0': 'Asia/Riyadh', // Saudi Arabia, East Africa
      '3:30': 'Asia/Tehran', // Iran
      '4:0': 'Asia/Dubai', // UAE
      '4:30': 'Asia/Kabul', // Afghanistan
      // Europe
      '0:0': 'Europe/London', // UK (GMT)
      '1:0': 'Europe/Paris', // Central Europe, West Africa
      '2:0': 'Europe/Helsinki', // Eastern Europe, Egypt
      // Americas
      '-5:0': 'America/New_York', // US Eastern
      '-6:0': 'America/Chicago', // US Central
      '-7:0': 'America/Denver', // US Mountain
      '-8:0': 'America/Los_Angeles', // US Pacific
      '-3:0': 'America/Sao_Paulo', // Brazil
      '-4:0': 'America/Caracas', // Venezuela, Atlantic
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
    final translatedLoanName = _getTranslatedLoanName(
      loan.loanTypeName ?? loan.name,
      lang,
    );
    final notificationLoanName = _buildReminderLoanName(
      loan,
      translatedLoanName,
    );

    if (testMode) {
      // TEST MODE: Show immediate notification to verify it works
      debugPrint('========================================');
      debugPrint('🧪 TEST MODE: Attempting to show notification');
      debugPrint('Loan: ${loan.name}, EMI: ${loan.emiAmount}');
      try {
        final testTitle = '🔔 ${_getLocalizedText('emiReminderTest', lang)}';
        final testBody =
            '$translatedLoanName - $currencySymbol${loan.emiAmount.toStringAsFixed(0)} ${_getLocalizedText('notificationWorking', lang)}';

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

    // Always clear this loan's previous reminders first to avoid duplicates.
    await cancelLoanReminders(loan.id);

    // Completed loans should not keep generating future reminders.
    if (loan.tenureMonths != null && loan.emisPaidCount >= loan.tenureMonths!) {
      debugPrint('✅ Skipping schedule for completed loan: ${loan.name}');
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

    final bucket = await ReminderExperimentService.getOrAssignBucket();
    final notificationHours =
        await ReminderExperimentService.getHoursForResolvedRegion(bucket);
    final dueIn3DaysCount = _countDueLoansForStage(3);
    final dueTomorrowCount = _countDueLoansForStage(1);
    final dueTodayCount = _countDueLoansForStage(0);
    final remainingEmis = _remainingEmis(loan);

    debugPrint('   Reminder timing bucket: $bucket -> $notificationHours');

    int notificationIndex = 0;
    int scheduledCount = 0;

    // Day 1: 3 days before due date
    for (int hour in notificationHours) {
      final scheduledDate = DateTime(
        day3Before.year,
        day3Before.month,
        day3Before.day,
        hour,
        0,
        0,
      );
      if (scheduledDate.isAfter(now)) {
        final success = await _scheduleNotification(
          id: baseId + notificationIndex,
          title: _smartTitle(3, lang),
          body: _smartBody(
            loanName: notificationLoanName,
            symbol: currencySymbol,
            amount: loan.emiAmount,
            daysLeft: 3,
            lang: lang,
            dueLoansCount: dueIn3DaysCount,
            emisRemaining: remainingEmis,
          ),
          scheduledDate: scheduledDate,
          payload: loan.id,
        );
        if (success) scheduledCount++;
      }
      notificationIndex++;
    }

    // Day 2: 1 day before due date
    for (int hour in notificationHours) {
      final scheduledDate = DateTime(
        day1Before.year,
        day1Before.month,
        day1Before.day,
        hour,
        0,
        0,
      );
      if (scheduledDate.isAfter(now)) {
        final success = await _scheduleNotification(
          id: baseId + notificationIndex,
          title: _smartTitle(1, lang),
          body: _smartBody(
            loanName: notificationLoanName,
            symbol: currencySymbol,
            amount: loan.emiAmount,
            daysLeft: 1,
            lang: lang,
            dueLoansCount: dueTomorrowCount,
            emisRemaining: remainingEmis,
          ),
          scheduledDate: scheduledDate,
          payload: loan.id,
        );
        if (success) scheduledCount++;
      }
      notificationIndex++;
    }

    // Day 3: On due date
    for (int hour in notificationHours) {
      final scheduledDate = DateTime(
        dueDay.year,
        dueDay.month,
        dueDay.day,
        hour,
        0,
        0,
      );
      if (scheduledDate.isAfter(now)) {
        final success = await _scheduleNotification(
          id: baseId + notificationIndex,
          title: _smartTitle(0, lang),
          body: _smartBody(
            loanName: notificationLoanName,
            symbol: currencySymbol,
            amount: loan.emiAmount,
            daysLeft: 0,
            lang: lang,
            dueLoansCount: dueTodayCount,
            emisRemaining: remainingEmis,
          ),
          scheduledDate: scheduledDate,
          payload: loan.id,
        );
        if (success) scheduledCount++;
      }
      notificationIndex++;
    }

    debugPrint(
      '✅ Scheduled $scheduledCount out of $notificationIndex notifications for ${loan.name}',
    );

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
    final normalizedLang = _normalizeLang(lang);
    final translations = {
      'emiDueIn3Days': {
        'en': 'EMI Due in 3 Days',
        'ta': '3 நாட்களில் EMI செலுத்த வேண்டும்',
        'te': '3 రోజుల్లో EMI చెల్లించాలి',
        'hi': '3 दिनों में EMI देय है',
        'ur': 'EMI 3 din mein due hai',
        'bn': '3 diner moddhe EMI due',
        'fil': 'EMI due in 3 days',
      },
      'emiDueTomorrow': {
        'en': 'EMI Due Tomorrow',
        'ta': 'நாளை EMI செலுத்த வேண்டும்',
        'te': 'రేపు EMI చెల్లించాలి',
        'hi': 'कल EMI देय है',
        'ur': 'Kal EMI due hai',
        'bn': 'Kal EMI due',
        'fil': 'EMI is due tomorrow',
      },
      'emiDueToday': {
        'en': 'EMI Due Today!',
        'ta': 'இன்று EMI செலுத்த வேண்டும்!',
        'te': 'ఈరోజు EMI చెల్లించాలి!',
        'hi': 'आज EMI देय है!',
        'ur': 'Aaj EMI due hai!',
        'bn': 'Aj EMI due!',
        'fil': 'EMI is due today!',
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
        'ta':
            'இன்று செலுத்த வேண்டும்! தாமதக் கட்டணத்தைத் தவிர்க்க இப்போதே செலுத்துங்கள்.',
        'te':
            'ఈరోజు చెల్లించాలి! ఆలస్య రుసుము నివారించడానికి ఇప్పుడే చెల్లించండి.',
        'hi': 'आज देय है! विलंब शुल्क से बचने के लिए अभी भुगतान करें।',
      },
      'emiReminderTest': {
        'en': 'EMI Reminder Test',
        'ta': 'EMI நினைவூட்டல் சோதனை',
        'te': 'EMI రిమైండర్ టెస్ట్',
        'hi': 'EMI रिमाइंडर टेस्ट',
        'ur': 'EMI reminder test',
        'bn': 'EMI reminder test',
        'fil': 'EMI reminder test',
      },
      'notificationWorking': {
        'en': 'notification is working!',
        'ta': 'அறிவிப்பு வேலை செய்கிறது!',
        'te': 'నోటిఫికేషన్ పని చేస్తోంది!',
        'hi': 'नोटिफिकेशन काम कर रहा है!',
        'ur': 'Notification kaam kar raha hai!',
        'bn': 'Notification kaj korche!',
        'fil': 'Gumagana ang notification!',
      },
      'testNotification': {
        'en': 'Test Notification',
        'ta': 'சோதனை அறிவிப்பு',
        'te': 'టెస్ట్ నోటిఫికేషన్',
        'hi': 'टेस्ट नोटिफिकेशन',
        'ur': 'Test notification',
        'bn': 'Test notification',
        'fil': 'Test notification',
      },
      'testNotificationBody': {
        'en':
            'EMI Reminder is working! You will receive timely reminders for your EMI payments.',
        'ta':
            'EMI நினைவூட்டல் வேலை செய்கிறது! உங்கள் EMI கட்டணங்களுக்கு சரியான நேரத்தில் நினைவூட்டல்களைப் பெறுவீர்கள்.',
        'te':
            'EMI రిమైండర్ పని చేస్తోంది! మీ EMI చెల్లింపులకు సకాలంలో రిమైండర్లు అందుకుంటారు.',
        'hi':
            'EMI रिमाइंडर काम कर रहा है! आपको अपने EMI भुगतान के लिए समय पर रिमाइंडर मिलेंगे।',
        'ur':
            'EMI reminder kaam kar raha hai! Aap ko EMI payments ke liye waqt par reminders milenge.',
        'bn':
            'EMI reminder kaj korche! Apni EMI payment er jonno somoy moto reminder paben.',
        'fil':
            'Gumagana ang EMI Reminder! Makakatanggap ka ng paalala para sa EMI payments mo.',
      },
    };

    return translations[key]?[normalizedLang] ??
        translations[key]?['en'] ??
        key;
  }

  /// Get translated loan type name
  String _getTranslatedLoanName(String loanName, String lang) {
    final name = loanName.toLowerCase();

    final loanTypes = {
      'home loan': {'ta': 'வீட்டுக் கடன்', 'te': 'గృహ రుణం', 'hi': 'गृह ऋण'},
      'car loan': {'ta': 'வாகனக் கடன்', 'te': 'వాహన రుణం', 'hi': 'कार ऋण'},
      'personal loan': {
        'ta': 'தனிநபர் கடன்',
        'te': 'వ్యక్తిగత రుణం',
        'hi': 'व्यक्तिगत ऋण',
      },
      'education loan': {
        'ta': 'கல்விக் கடன்',
        'te': 'విద్యా రుణం',
        'hi': 'शिक्षा ऋण',
      },
      'business loan': {
        'ta': 'தொழில் கடன்',
        'te': 'వ్యాపార రుణం',
        'hi': 'व्यापार ऋण',
      },
      'gold loan': {'ta': 'நகைக்கடன்', 'te': 'బంగారు రుణం', 'hi': 'स्वर्ण ऋण'},
      'credit card': {
        'ta': 'கிரெடிட் கார்டு',
        'te': 'క్రెడిట్ కార్డ్',
        'hi': 'क्रेडिट कार्ड',
      },
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
        debugPrint(
          '⏭️ Skipping notification $id - scheduled date ($scheduledDate) is in the past',
        );
        return false;
      }

      // Use zonedSchedule for all future notifications
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      debugPrint(
        '⏰ Scheduling notification $id at $tzScheduledDate (local: $scheduledDate)',
      );

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
        debugPrint(
          '⚠️ alarmClock mode failed: $alarmClockError, trying exactAllowWhileIdle...',
        );
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
        debugPrint(
          '✅ Notification $id scheduled with exactAllowWhileIdle mode',
        );
        return true;
      } catch (exactError) {
        debugPrint(
          '⚠️ exactAllowWhileIdle failed: $exactError, trying inexact...',
        );
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
  Future<void> cancelLoanReminders(
    String loanId, {
    int tenureMonths = 12,
  }) async {
    try {
      for (final id in _loanReminderIds(loanId)) {
        await _flutterLocalNotificationsPlugin.cancel(id);
      }
      debugPrint('✅ Cancelled all notifications for loan: $loanId');
    } catch (e) {
      debugPrint('❌ Error cancelling notifications: $e');
    }
  }

  Iterable<int> _loanReminderIds(String loanId) sync* {
    final baseId = loanId.hashCode.abs() % 100000;
    for (int i = 0; i < 12; i++) {
      yield baseId + i;
    }
    yield baseId + _sevenDayReminderOffset;
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

  /// Schedule monthly reminders for a subscription.
  Future<void> scheduleSubscriptionReminders(Subscription subscription) async {
    if (!_isInitialized || !_hasPermission) return;

    await cancelSubscriptionReminders(subscription.id);

    if (!subscription.isActive) {
      debugPrint('✅ Skipping inactive subscription: ${subscription.name}');
      return;
    }

    final lang = await _getCurrentLanguage();
    final nextDue = subscription.getNextDueDate();
    final now = DateTime.now();
    final amount =
        '${_symbolForCurrency(subscription.currencyCode)}${subscription.amount.toStringAsFixed(0)}';

    final day3Before = nextDue.subtract(const Duration(days: 3));
    final day1Before = nextDue.subtract(const Duration(days: 1));

    final baseId = _subscriptionBaseId(subscription.id);
    int idx = 0;

    Future<void> scheduleIfFuture(
      DateTime date,
      String title,
      String body,
    ) async {
      if (!date.isAfter(now)) {
        idx++;
        return;
      }
      await _scheduleNotification(
        id: baseId + idx,
        title: title,
        body: body,
        scheduledDate: date,
        payload: 'subscription:${subscription.id}',
      );
      idx++;
    }

    await scheduleIfFuture(
      DateTime(day3Before.year, day3Before.month, day3Before.day, 9, 0),
      _smartText(lang, {
        'en': '📅 ${subscription.name} renews in 3 days',
        'hi': '📅 ${subscription.name} 3 दिनों में नवीनीकरण होगा',
        'ta': '📅 ${subscription.name} 3 நாட்களில் புதுப்பிக்கப்படும்',
        'te': '📅 ${subscription.name} 3 రోజుల్లో రీన్యూ అవుతుంది',
      }),
      _smartText(lang, {
        'en':
            '$amount will be charged soon. Review if you still need this plan.',
        'hi':
            '$amount जल्द चार्ज होगा। देखें कि यह प्लान अभी भी चाहिए या नहीं।',
        'ta':
            '$amount விரைவில் பிடிக்கப்படும். இந்த திட்டம் இன்னும் தேவையா என சரிபார்க்கவும்.',
        'te': '$amount త్వరలో ఛార్జ్ అవుతుంది. ఈ ప్లాన్ ఇంకా అవసరమో చూడండి.',
      }),
    );

    await scheduleIfFuture(
      DateTime(day1Before.year, day1Before.month, day1Before.day, 9, 0),
      _smartText(lang, {
        'en': '🔔 ${subscription.name} renews tomorrow',
        'hi': '🔔 ${subscription.name} कल नवीनीकरण होगा',
        'ta': '🔔 ${subscription.name} நாளை புதுப்பிக்கப்படும்',
        'te': '🔔 ${subscription.name} రేపు రీన్యూ అవుతుంది',
      }),
      _smartText(lang, {
        'en': 'Upcoming charge: $amount. Cancel or keep it active.',
        'hi': 'आगामी शुल्क: $amount। रद्द करें या सक्रिय रखें।',
        'ta': 'வரவிருக்கும் கட்டணம்: $amount. ரத்து செய்யவோ தொடரவோ முடியும்.',
        'te': 'రాబోయే ఛార్జ్: $amount. రద్దు చేయండి లేదా కొనసాగించండి.',
      }),
    );

    await scheduleIfFuture(
      DateTime(nextDue.year, nextDue.month, nextDue.day, 9, 0),
      _smartText(lang, {
        'en': '🚨 ${subscription.name} renews today',
        'hi': '🚨 ${subscription.name} आज नवीनीकरण होगा',
        'ta': '🚨 ${subscription.name} இன்று புதுப்பிக்கப்படும்',
        'te': '🚨 ${subscription.name} ఈరోజు రీన్యూ అవుతుంది',
      }),
      _smartText(lang, {
        'en': '$amount is due today. Mark it paid after the charge.',
        'hi': '$amount आज देय है। चार्ज के बाद इसे पेड मार्क करें।',
        'ta':
            '$amount இன்று செலுத்த வேண்டும். கட்டணம் நடந்ததும் paid ஆக குறிக்கவும்.',
        'te':
            '$amount ఈరోజు చెల్లించాలి. ఛార్జ్ అయిన తర్వాత paid గా గుర్తించండి.',
      }),
    );

    await scheduleIfFuture(
      DateTime(nextDue.year, nextDue.month, nextDue.day, 19, 0),
      _smartText(lang, {
        'en': '⏰ Final reminder: ${subscription.name}',
        'hi': '⏰ अंतिम याद दिलाना: ${subscription.name}',
        'ta': '⏰ கடைசி நினைவூட்டல்: ${subscription.name}',
        'te': '⏰ చివరి రిమైండర్: ${subscription.name}',
      }),
      _smartText(lang, {
        'en': 'Still pending? Confirm $amount renewal status tonight.',
        'hi': 'अभी भी लंबित है? आज रात $amount नवीनीकरण स्थिति जांचें।',
        'ta':
            'இன்னும் நிலுவையிலா? இன்று இரவு $amount புதுப்பிப்பு நிலையை உறுதிப்படுத்தவும்.',
        'te':
            'ఇంకా పెండింగ్‌లో ఉందా? ఈ రాత్రి $amount రీన్యువల్ స్థితి చూడండి.',
      }),
    );

    debugPrint(
      '✅ Subscription reminders scheduled for ${subscription.name} on $nextDue',
    );
  }

  Future<void> cancelSubscriptionReminders(String subscriptionId) async {
    if (!_isInitialized) return;
    final baseId = _subscriptionBaseId(subscriptionId);
    for (int i = 0; i < 4; i++) {
      try {
        await _flutterLocalNotificationsPlugin.cancel(baseId + i);
      } catch (_) {}
    }
  }

  int _subscriptionBaseId(String subscriptionId) {
    return (subscriptionId.hashCode.abs() % 100000) + _subscriptionIdRangeStart;
  }

  String _symbolForCurrency(String code) {
    return '${CurrencyHelper.getSymbol(code)} ';
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
    required int dueDay, // 1-31: day of month interest is due
    required bool isLent, // true = they owe you, false = you owe them
  }) async {
    if (!_isInitialized) return;

    // Cancel existing reminders for this loan first
    await cancelP2PReminders(loanId);

    final now = DateTime.now();
    final baseId = (loanId.hashCode.abs() % 100000) + 500000;

    // Compute the next occurrence of dueDay
    int year = now.year, month = now.month;
    int clampedDay(int y, int m) => dueDay.clamp(1, DateTime(y, m + 1, 0).day);

    DateTime nextDue = DateTime(year, month, clampedDay(year, month));
    if (!nextDue.isAfter(now)) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      nextDue = DateTime(year, month, clampedDay(year, month));
    }

    final amtStr = '₹${monthlyInterest.toStringAsFixed(0)}';

    // Differentiate clearly: taken loan = you must PAY, given loan = you must COLLECT
    final String body;
    final String title3Days;
    final String title1Day;
    final String titleMorning;
    final String titleEvening;

    if (isLent) {
      // You gave the loan — remind to collect
      body = 'Collect $amtStr interest from $personName today';
      title3Days = '💰 Collect from $personName in 3 days';
      title1Day = '💰 Collect from $personName tomorrow';
      titleMorning = '🔔 Collect $amtStr from $personName today!';
      titleEvening = '⏰ Still pending: collect $amtStr from $personName';
    } else {
      // You took the loan — remind to pay
      body = 'You need to pay $amtStr interest to $personName today';
      title3Days = '💸 Pay $personName interest in 3 days';
      title1Day = '💸 Pay $personName interest tomorrow';
      titleMorning = '🔔 Pay $amtStr to $personName today!';
      titleEvening = '⏰ Don\'t forget: pay $amtStr to $personName';
    }

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
      title3Days,
    );
    // 1 day before
    await scheduleIfFuture(
      DateTime(nextDue.year, nextDue.month, nextDue.day - 1, 9, 0),
      title1Day,
    );
    // On due day — morning
    await scheduleIfFuture(
      DateTime(nextDue.year, nextDue.month, nextDue.day, 9, 0),
      titleMorning,
    );
    // On due day — evening reminder
    await scheduleIfFuture(
      DateTime(nextDue.year, nextDue.month, nextDue.day, 18, 0),
      titleEvening,
    );

    debugPrint(
      '✅ P2P reminders scheduled for $personName — next due: $nextDue',
    );
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
      final pending = await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      return pending.length;
    } catch (e) {
      debugPrint('❌ Error getting pending notifications: $e');
      return 0;
    }
  }

  /// Get list of pending notifications for debugging
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
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
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        permissions['notificationsEnabled'] =
            await androidImplementation.areNotificationsEnabled() ?? false;
      }

      permissions['notifications'] = _hasPermission;
      permissions['exactAlarms'] =
          true; // Assume granted if no error during init
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
            AndroidFlutterLocalNotificationsPlugin
          >();

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
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        return await androidImplementation.canScheduleExactNotifications() ??
            false;
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
      final pending = await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
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

  // ─────────────────────────────────────────────
  // SMART NOTIFICATIONS — Engaging copy per stage
  // ─────────────────────────────────────────────

  /// Returns a smart, engaging notification body based on days until due.
  String _smartBody({
    required String loanName,
    required String symbol,
    required double amount,
    required int daysLeft,
    required String lang,
    required int dueLoansCount,
    required int? emisRemaining,
  }) {
    final amt = '${symbol}${amount.toStringAsFixed(0)}';
    final hasMultipleDue = dueLoansCount > 1;
    final dueContext = hasMultipleDue
        ? _smartText(lang, {
            'en': ' You have $dueLoansCount EMIs due around this time.',
            'hi': ' इस समय लगभग $dueLoansCount EMI देय हैं।',
            'ta': ' இந்த நேரத்தில் சுமார் $dueLoansCount EMI செலுத்த வேண்டும்.',
            'te': ' ఈ సమయంలో సుమారు $dueLoansCount EMIలు చెల్లించాలి.',
            'ur': ' Is waqt qareeban $dueLoansCount EMI due hain.',
            'bn': ' Ei somoy pray $dueLoansCount ta EMI due ache.',
            'fil': ' May $dueLoansCount EMI kang due sa panahon na ito.',
          })
        : '';
    final remainingContext = (emisRemaining != null && emisRemaining > 0)
        ? _smartText(lang, {
            'en': ' $emisRemaining EMI${emisRemaining == 1 ? '' : 's'} left.',
            'hi': ' $emisRemaining EMI शेष हैं।',
            'ta': ' இன்னும் $emisRemaining EMI மீதமுள்ளது.',
            'te': ' ఇంకా $emisRemaining EMIలు మిగిలి ఉన్నాయి.',
            'ur': ' $emisRemaining EMI baki hain.',
            'bn': ' $emisRemaining ta EMI baki ache.',
            'fil': ' May $emisRemaining EMI pa na natitira.',
          })
        : '';

    if (daysLeft == 7) {
      return _smartText(lang, {
        'en':
            '📅 $loanName EMI of $amt is due in 7 days. Plan ahead to avoid surprises!',
        'hi': '📅 $loanName की $amt EMI 7 दिनों में है। अभी से तैयारी करें!',
        'ta':
            '📅 $loanName EMI $amt — 7 நாட்களில் செலுத்த வேண்டும். முன்கூட்டியே திட்டமிடுங்கள்!',
        'te':
            '📅 $loanName EMI $amt — 7 రోజుల్లో చెల్లించాలి. ముందే ప్లాన్ చేయండి!',
        'ur':
            '📅 $loanName ki $amt EMI 7 din mein due hai. Pehle se plan karein!',
        'bn':
            '📅 $loanName er $amt EMI 7 diner moddhe due. Agey theke plan korun!',
        'fil':
            '📅 Ang $amt na EMI ng $loanName ay due sa loob ng 7 araw. Magplano nang maaga!',
      });
    } else if (daysLeft == 3) {
      return _smartText(lang, {
        'en':
            '⚠️ $loanName EMI of $amt due in 3 days. Set aside the amount now!$dueContext$remainingContext',
        'hi':
            '⚠️ $loanName की $amt EMI 3 दिनों में है। अभी राशि तैयार रखें!$dueContext$remainingContext',
        'ta':
            '⚠️ $loanName EMI $amt — 3 நாட்களில் செலுத்த வேண்டும்!$dueContext$remainingContext',
        'te':
            '⚠️ $loanName EMI $amt — 3 రోజుల్లో చెల్లించాలి!$dueContext$remainingContext',
        'ur':
            '⚠️ $loanName ki $amt EMI 3 din mein due hai!$dueContext$remainingContext',
        'bn':
            '⚠️ $loanName er $amt EMI 3 diner moddhe due!$dueContext$remainingContext',
        'fil':
            '⚠️ Ang $amt na EMI ng $loanName ay due in 3 days!$dueContext$remainingContext',
      }).trim();
    } else if (daysLeft == 1) {
      return _smartText(lang, {
        'en':
            '🔔 Tomorrow is the day! $loanName EMI of $amt is due. Don\'t miss it!$dueContext$remainingContext',
        'hi':
            '🔔 कल $loanName की $amt EMI देय है। भूलें नहीं!$dueContext$remainingContext',
        'ta':
            '🔔 நாளை $loanName EMI $amt செலுத்த வேண்டும். மறக்காதீர்கள்!$dueContext$remainingContext',
        'te':
            '🔔 రేపు $loanName EMI $amt చెల్లించాలి. మర్చిపోకండి!$dueContext$remainingContext',
        'ur':
            '🔔 Kal $loanName ki $amt EMI due hai. Bhoolna mat!$dueContext$remainingContext',
        'bn':
            '🔔 Kal $loanName er $amt EMI due. Vulben na!$dueContext$remainingContext',
        'fil':
            '🔔 Bukas due ang $amt na EMI ng $loanName. Huwag kalimutan!$dueContext$remainingContext',
      }).trim();
    } else {
      return _smartText(lang, {
        'en':
            '🚨 Today is the last day! Pay $loanName EMI of $amt now to avoid late fees.$dueContext$remainingContext',
        'hi':
            '🚨 आज आखिरी दिन! $loanName की $amt EMI अभी दें — देरी शुल्क से बचें।$dueContext$remainingContext',
        'ta':
            '🚨 இன்றே கடைசி நாள்! $loanName EMI $amt இப்போதே செலுத்துங்கள்.$dueContext$remainingContext',
        'te':
            '🚨 ఈరోజే చివరి రోజు! $loanName EMI $amt ఇప్పుడే చెల్లించండి.$dueContext$remainingContext',
        'ur':
            '🚨 Aaj aakhri din hai! $loanName ki $amt EMI abhi pay karein.$dueContext$remainingContext',
        'bn':
            '🚨 Aj sesh din! $loanName er $amt EMI ekhoni pay korun.$dueContext$remainingContext',
        'fil':
            '🚨 Last day na ngayon! Bayaran ang $amt na EMI ng $loanName ngayon.$dueContext$remainingContext',
      }).trim();
    }
  }

  String _smartText(String lang, Map<String, String> map) =>
      map[_normalizeLang(lang)] ?? map['en'] ?? '';

  String _normalizeLang(String lang) {
    final normalized = lang.toLowerCase();
    if (normalized.contains('_')) {
      return normalized.split('_').first;
    }
    if (normalized.contains('-')) {
      return normalized.split('-').first;
    }
    return normalized;
  }

  /// Smart title per urgency level
  String _smartTitle(int daysLeft, String lang) {
    if (daysLeft == 7) {
      return _smartText(lang, {
        'en': '💡 EMI Reminder — 1 Week Left',
        'hi': '💡 EMI याद — 1 सप्ताह बाकी',
        'ta': '💡 EMI நினைவூட்டல் — 1 வாரம் உள்ளது',
        'te': '💡 EMI రిమైండర్ — 1 వారం మిగిలింది',
        'ur': '💡 EMI reminder — 1 hafta baqi',
        'bn': '💡 EMI reminder — 1 soptaho baki',
        'fil': '💡 EMI reminder — 1 linggo na lang',
      });
    } else if (daysLeft == 3) {
      return _smartText(lang, {
        'en': '⚠️ EMI Due in 3 Days',
        'hi': '⚠️ 3 दिनों में EMI देय',
        'ta': '⚠️ 3 நாட்களில் EMI',
        'te': '⚠️ 3 రోజుల్లో EMI',
        'ur': '⚠️ EMI 3 din mein due',
        'bn': '⚠️ EMI 3 diner moddhe due',
        'fil': '⚠️ EMI due in 3 days',
      });
    } else if (daysLeft == 1) {
      return _smartText(lang, {
        'en': '🔔 EMI Due Tomorrow!',
        'hi': '🔔 कल EMI देय है!',
        'ta': '🔔 நாளை EMI!',
        'te': '🔔 రేపు EMI!',
        'ur': '🔔 Kal EMI due hai!',
        'bn': '🔔 Kal EMI due!',
        'fil': '🔔 EMI due tomorrow!',
      });
    } else {
      return _smartText(lang, {
        'en': '🚨 EMI Due TODAY!',
        'hi': '🚨 आज EMI देय है!',
        'ta': '🚨 இன்று EMI!',
        'te': '🚨 ఈరోజు EMI!',
        'ur': '🚨 Aaj EMI due hai!',
        'bn': '🚨 Aj EMI due!',
        'fil': '🚨 EMI due today!',
      });
    }
  }

  /// Schedule 7-day advance reminder (smart notification)
  Future<void> scheduleSevenDayReminder(Loan loan) async {
    if (!_isInitialized || !_hasPermission) return;
    final lang = await _getCurrentLanguage();
    final nextDue = loan.getNextDueDate();
    final now = DateTime.now();
    final day7Before = nextDue.subtract(const Duration(days: 7));
    final bucket = await ReminderExperimentService.getOrAssignBucket();
    final hours = await ReminderExperimentService.getHoursForResolvedRegion(
      bucket,
    );
    final reminderHour = hours.first;
    final scheduled = DateTime(
      day7Before.year,
      day7Before.month,
      day7Before.day,
      reminderHour,
      0,
      0,
    );
    if (scheduled.isBefore(now)) return;

    final baseId = loan.id.hashCode.abs() % 100000;
    await _scheduleNotification(
      id: baseId + _sevenDayReminderOffset,
      title: _smartTitle(7, lang),
      body: _smartBody(
        loanName: _buildReminderLoanName(
          loan,
          _getTranslatedLoanName(loan.loanTypeName ?? loan.name, lang),
        ),
        symbol: loan.currencySymbol,
        amount: loan.emiAmount,
        daysLeft: 7,
        lang: lang,
        dueLoansCount: _countDueLoansForStage(7),
        emisRemaining: _remainingEmis(loan),
      ),
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

    // Cancel previous monthly summary before scheduling a fresh one.
    await _flutterLocalNotificationsPlugin.cancel(
      _monthlySummaryNotificationId,
    );

    final lang = await _getCurrentLanguage();
    final now = DateTime.now();

    // Schedule for 1st of next month at 8:00 AM
    final nextMonth = DateTime(
      now.month == 12 ? now.year + 1 : now.year,
      now.month == 12 ? 1 : now.month + 1,
      1,
      8,
      0,
      0,
    );

    final totalEmi = loans.fold<double>(0, (s, l) => s + l.emiAmount);
    final loanCount = loans.length;
    final symbol = loans.first.currencySymbol;
    final totalStr = '$symbol${totalEmi.toStringAsFixed(0)}';

    // Upcoming due loans this month
    final dueSoon = loans
        .where((l) => !l.isPaid && l.daysUntilDue() <= 7)
        .length;

    final title = _smartText(lang, {
      'en': '📊 Your Monthly EMI Summary',
      'hi': '📊 आपका मासिक EMI सारांश',
      'ta': '📊 உங்கள் மாதாந்திர EMI சுருக்கம்',
      'te': '📊 మీ నెలవారీ EMI సారాంశం',
    });

    final body = _smartText(lang, {
      'en':
          'You have $loanCount loans totalling $totalStr/month.${dueSoon > 0 ? ' $dueSoon payments due soon!' : ' Stay on track! 💪'}',
      'hi':
          'आपके $loanCount लोन हैं, कुल $totalStr/माह।${dueSoon > 0 ? ' $dueSoon भुगतान जल्द देय है!' : ' ट्रैक पर रहें! 💪'}',
      'ta':
          'உங்களிடம் $loanCount கடன்கள் உள்ளன, மொத்தம் $totalStr/மாதம்।${dueSoon > 0 ? ' $dueSoon கொடுப்பனவுகள் விரைவில்!' : ' தொடர்ந்து முன்னேறுங்கள்! 💪'}',
      'te':
          'మీకు $loanCount రుణాలు ఉన్నాయి, మొత్తం $totalStr/నెల।${dueSoon > 0 ? ' $dueSoon చెల్లింపులు త్వరలో!' : ' ట్రాక్‌లో ఉండండి! 💪'}',
    });

    await _scheduleNotification(
      id: _monthlySummaryNotificationId,
      title: title,
      body: body,
      scheduledDate: nextMonth,
      payload: 'monthly_summary',
    );
    debugPrint('✅ Monthly summary notification scheduled for $nextMonth');
  }

  Future<void> cancelMonthSummaryNotification() async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(
        _monthlySummaryNotificationId,
      );
      debugPrint('✅ Monthly summary notification cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling monthly summary notification: $e');
    }
  }

  String _buildReminderLoanName(Loan loan, String translatedLoanName) {
    final bankName = loan.bankName?.trim();
    if (bankName == null || bankName.isEmpty) {
      return translatedLoanName;
    }

    return '$bankName $translatedLoanName';
  }

  int _countDueLoansForStage(int daysLeft) {
    try {
      if (!Hive.isBoxOpen('loans')) {
        return 1;
      }

      final loans = Hive.box<Loan>('loans').values;
      final dueCount = loans.where((loan) {
        if (loan.isPaid) {
          return false;
        }
        if (loan.tenureMonths != null &&
            loan.emisPaidCount >= loan.tenureMonths!) {
          return false;
        }
        return loan.daysUntilDue() == daysLeft;
      }).length;

      return dueCount > 0 ? dueCount : 1;
    } catch (_) {
      return 1;
    }
  }

  int? _remainingEmis(Loan loan) {
    if (loan.tenureMonths == null) {
      return null;
    }

    final remaining = loan.tenureMonths! - loan.emisPaidCount;
    return remaining > 0 ? remaining : 0;
  }
}
