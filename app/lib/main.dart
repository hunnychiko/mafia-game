import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/theme/app_theme.dart';
import 'presentation/alarm/alarm_list_screen.dart';
import 'presentation/alarm/alarm_ringing_screen.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/settings/settings_screen.dart';
import 'services/alarm_service.dart';
import 'firebase_options.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}\n${details.stack}');
  };

  await runZonedGuarded(_initAndRun, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
}

Future<void> _initAndRun() async {
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.lullify.app.audio',
      androidNotificationChannelName: 'Lullify',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ).timeout(const Duration(seconds: 10));
  } catch (e, st) {
    debugPrint('JustAudioBackground init failed (non-fatal): $e\n$st');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    debugPrint('Firebase init failed: $e\n$st');
  }

  try {
    await MobileAds.instance.initialize();
  } catch (e, st) {
    debugPrint('MobileAds init failed (non-fatal): $e\n$st');
  }

  try {
    await Alarm.init();
  } catch (e, st) {
    debugPrint('Alarm init failed (non-fatal): $e\n$st');
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: SleepSoundApp()));
}

class SleepSoundApp extends ConsumerStatefulWidget {
  const SleepSoundApp({super.key});

  @override
  ConsumerState<SleepSoundApp> createState() => _SleepSoundAppState();
}

class _SleepSoundAppState extends ConsumerState<SleepSoundApp> {
  StreamSubscription<AlarmSettings>? _ringSubscription;

  @override
  void initState() {
    super.initState();
    _listenForRingingAlarms();
  }

  Future<void> _listenForRingingAlarms() async {
    try {
      final alarmService = await ref.read(alarmServiceProvider.future);
      _ringSubscription = alarmService.onRing.listen((settings) {
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => AlarmRingingScreen(
            alarmId: settings.id,
            alarmLabel: alarmService.getById(settings.id)?.label,
          ),
        ));
      });
    } catch (e, st) {
      debugPrint('Alarm ring listener failed to start: $e\n$st');
    }
  }

  @override
  void dispose() {
    _ringSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lullify',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.dark,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('de'),
        Locale('es'),
        Locale('pt'),
        Locale('ja'),
        Locale('fr'),
      ],
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/alarms': (_) => const AlarmListScreen(),
      },
    );
  }
}
