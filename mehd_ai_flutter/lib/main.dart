import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/services/auth_service.dart';
import 'package:mehd_ai_flutter/services/language_service.dart';
import 'package:mehd_ai_flutter/services/settings_service.dart';
import 'package:mehd_ai_flutter/screens/splash_screen.dart';
import 'package:mehd_ai_flutter/screens/auth_screen.dart';
import 'package:mehd_ai_flutter/screens/autopilot_command_center.dart';
import 'package:mehd_ai_flutter/screens/den/tutorial_blueprint_screen.dart';
import 'package:mehd_ai_flutter/screens/onboarding/broker_connect_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mehd_ai_flutter/firebase_options.dart';

import 'package:mehd_ai_flutter/controllers/trading_controller.dart';
import 'package:mehd_ai_flutter/controllers/market_data_controller.dart';
import 'package:mehd_ai_flutter/services/payment_service.dart';
import 'package:mehd_ai_flutter/services/broker_service.dart';
import 'package:mehd_ai_flutter/services/nlg_engine.dart';
import 'package:mehd_ai_flutter/widgets/inactivity_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load local Pulse Trading templates
  await NLGEngine().loadTemplates();
  
  // Catch rendering errors so we don't get a blank screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.red.shade900,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('CRITICAL UI CRASH', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text(details.exceptionAsString(), style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 20),
              Text(details.stack.toString(), style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  };

  debugPrint("DEN_BOOT: Launching App...");
  
  // Instant boot: Run App immediately with SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  // Non-blocking Firebase init
  _initFirebaseAsync();

  runApp(MehdAiApp(prefs: prefs));
}

/// Non-blocking Firebase init — runs in background so boot is instant.
Future<void> _initFirebaseAsync() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10)); // 10s is plenty for a healthy init
    debugPrint("DEN_BOOT: Firebase Initialized.");

    // FCM Notification Initialization — safe no-op if unconfigured
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      debugPrint("DEN_BOOT: FCM Token acquired: ${token?.substring(0, 10)}...");

      // Foreground handler — routes to in-app notification banner
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("DEN_NOTIFY: ${message.notification?.title} — ${message.notification?.body}");
      });
    } catch (e) {
      debugPrint("DEN_BOOT: FCM not configured — notifications disabled: $e");
    }
  } catch (e) {
    debugPrint("DEN_BOOT: Firebase bypassed or failed: $e");
  }
}

class MehdAiApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MehdAiApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService(prefs: prefs), lazy: false),
        ChangeNotifierProvider(create: (_) => LanguageService(prefs: prefs)),
        ChangeNotifierProvider(create: (_) => TradingController()),
        ChangeNotifierProvider(create: (_) => MarketDataController()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs: prefs), lazy: false),
        ChangeNotifierProvider(create: (_) => SettingsService()..load(), lazy: false),
        ChangeNotifierProvider(create: (_) => PaymentService(), lazy: false),
        ChangeNotifierProvider(create: (_) => BrokerService()..init(), lazy: false),
      ],
      child: Consumer2<LanguageService, ThemeProvider>(
        builder: (context, languageOpts, themeProvider, child) {
          return MaterialApp(
            title: 'Mehd AI Terminal',
            theme: themeProvider.theme,
            debugShowCheckedModeBanner: false,
            locale: languageOpts.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
              Locale('fr'),
              Locale('es'),
              Locale('pt'),
              Locale('id'),
              Locale('zh'),
              Locale('ru'),
            ],
            builder: (context, child) {
              if (child == null) return const SizedBox.shrink();
              // RTL support for Arabic
              final isRtl = languageOpts.currentLocale.languageCode == 'ar';
              return InactivityGuard(
                timeoutDuration: const Duration(minutes: 15),
                child: Directionality(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: child,
                ),
              );
            },
            home: const SplashScreen(),
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/welcome': (context) => const AuthScreen(initialIsLogin: false),
              '/login': (context) => const AuthScreen(initialIsLogin: true),
              '/register': (context) => const AuthScreen(initialIsLogin: false),
              '/home': (context) => const AutopilotCommandCenter(),
              '/tutorial': (context) => const TutorialBlueprintScreen(),
              '/onboarding/broker': (context) => const BrokerConnectScreen(),
            },
          );
        },
      ),
    );
  }
}
