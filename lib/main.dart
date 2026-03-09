import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/loan_storage_service.dart';
import 'services/notification_service.dart';
import 'services/language_provider.dart';
import 'theme/app_theme.dart';
import 'localization/app_localizations.dart';

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
  LanguageProvider languageProvider = LanguageProvider();

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

  try {
    // Initialize language provider
    await languageProvider.init();
    debugPrint('✅ Language provider initialized');
  } catch (e) {
    debugPrint('❌ Language provider error: $e');
  }

  runApp(
    ChangeNotifierProvider<LanguageProvider>.value(
      value: languageProvider,
      child: EmiReminderApp(
        storageService: storageService,
        notificationService: notificationService,
      ),
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
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'EMI Reminder & Loan Tracker',
          theme: AppTheme.lightTheme,
          themeMode: ThemeMode.light,
          locale: languageProvider.currentLocale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ta'),
            Locale('te'),
            Locale('hi'),
          ],
          home: HomeScreen(
            storageService: storageService,
            notificationService: notificationService,
          ),
        );
      },
    );
  }
}

