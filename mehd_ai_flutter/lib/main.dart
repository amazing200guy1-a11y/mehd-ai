import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mehd_ai_flutter/core/theme.dart';
import 'package:mehd_ai_flutter/services/auth_service.dart';
import 'package:mehd_ai_flutter/services/language_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mehd_ai_flutter/screens/splash_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mehd_ai_flutter/firebase_options.dart';

import 'package:mehd_ai_flutter/controllers/trading_controller.dart';
import 'package:mehd_ai_flutter/controllers/market_data_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("DEN_BOOT: Launching App...");
  
  // Instant boot: Run App immediately with SharedPreferences
  // we wait for prefs because it's local and nearly instant.
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
      ],
      child: Consumer<LanguageService>(
        builder: (context, languageOpts, child) {
          return MaterialApp(
            title: 'Mehd AI Terminal',
            theme: MehdAiTheme.themeData,
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
              return Directionality(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: child,
              );
            },
            home: SplashScreen(prefs: prefs),
          );
        },
      ),
    );
  }
}
