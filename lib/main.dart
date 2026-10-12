import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'services/analytics_service.dart';
import 'services/loan_storage_service.dart';
import 'services/notification_service.dart';
import 'services/language_provider.dart';
import 'services/auth_service.dart';
import 'services/auth_provider.dart';
import 'theme/app_theme.dart';
import 'localization/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  LoanStorageService? storageService;
  NotificationService? notificationService;
  final languageProvider = LanguageProvider();

  await Future.wait([
    () async {
      try {
        storageService = LoanStorageService();
        await storageService!.init();
        debugPrint('✅ Storage service initialized');
      } catch (e) {
        debugPrint('❌ Storage service error: $e');
      }
    }(),
    () async {
      try {
        notificationService = NotificationService();
        await notificationService!.init();
        debugPrint('✅ Notification service initialized');
      } catch (e) {
        debugPrint('❌ Notification service error: $e');
      }
    }(),
    () async {
      try {
        await languageProvider.init();
        debugPrint('✅ Language provider initialized');
      } catch (e) {
        debugPrint('❌ Language provider error: $e');
      }
    }(),
    () async {
      try {
        await AuthService.initializeFirebase();
        debugPrint('✅ Firebase initialized');
      } catch (e) {
        debugPrint('❌ Firebase initialization error: $e');
      }
    }(),
  ]);

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;

  try {
    await AnalyticsService.track('app_opened');
  } catch (e) {
    debugPrint('❌ Analytics event error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ],
      child: P2PReminderApp(
        storageService: storageService,
        notificationService: notificationService,
        showOnboarding: !onboardingDone,
      ),
    ),
  );
}

class P2PReminderApp extends StatelessWidget {
  final LoanStorageService? storageService;
  final NotificationService? notificationService;
  final bool showOnboarding;

  const P2PReminderApp({
    super.key,
    this.storageService,
    this.notificationService,
    this.showOnboarding = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LoanLedger',
          theme: AppTheme.lightTheme,
          locale: languageProvider.currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            Locale('ta'),
            Locale('te'),
            Locale('kn'),
            Locale('ml'),
            Locale('mr'),
            Locale('bn'),
            Locale('gu'),
            Locale('id'),
            Locale('fil'),
            Locale('ur'), // Urdu — Pakistan
            Locale('es'), // Spanish — Mexico, Colombia, Argentina, etc.
          ],
          // Splash screen handles routing to onboarding or home
          home: SplashScreen(
            storageService: storageService,
            notificationService: notificationService,
          ),
        );
      },
    );
  }
}
