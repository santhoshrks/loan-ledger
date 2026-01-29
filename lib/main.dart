import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/loan_storage_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services with error handling
  LoanStorageService? storageService;
  NotificationService? notificationService;

  try {
    // Initialize Hive for local storage
    storageService = LoanStorageService();
    await storageService.init();
    debugPrint('✅ Storage service initialized');
  } catch (e) {
    debugPrint('❌ Storage service error: $e');
  }

  try {
    // Initialize notification service
    notificationService = NotificationService();
    await notificationService.init();
    debugPrint('✅ Notification service initialized');
  } catch (e) {
    debugPrint('❌ Notification service error: $e');
  }

  runApp(
    EmiReminderApp(
      storageService: storageService,
      notificationService: notificationService,
    ),
  );
}

class EmiReminderApp extends StatelessWidget {
  final LoanStorageService? storageService;
  final NotificationService? notificationService;

  const EmiReminderApp({
    super.key,
    this.storageService,
    this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EMI Reminder & Loan Tracker',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: HomeScreen(
        storageService: storageService,
        notificationService: notificationService,
      ),
    );
  }
}

