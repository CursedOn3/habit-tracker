import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'models/habit.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(HabitTypeAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(GoalPeriodAdapter());
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(HabitLocationAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(HabitAdapter());

  // Open settings box
  await Hive.openBox(AppConstants.settingsBox);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notifications
  await NotificationService().init();

  // Check onboarding
  final settingsBox = Hive.box(AppConstants.settingsBox);
  final onboardingDone =
      settingsBox.get(AppConstants.onboardingKey, defaultValue: false) as bool;

  runApp(
    ProviderScope(
      child: HabitTrackerApp(showOnboarding: !onboardingDone),
    ),
  );
}

class HabitTrackerApp extends ConsumerWidget {
  final bool showOnboarding;

  const HabitTrackerApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: showOnboarding ? const OnboardingScreen() : const SplashScreen(),
    );
  }
}
