import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/storage/storage_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables safely
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // If .env is missing or cannot be read, continue with defaults
  }

  // Initialize persistent key-value store
  SharedPreferences? sharedPreferences;
  try {
    sharedPreferences = await SharedPreferences.getInstance();
  } catch (_) {
    // Fallback if platform channels are unavailable in isolated test environments
  }

  runApp(
    ProviderScope(
      overrides: [
        if (sharedPreferences != null)
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const CyberOSApp(),
    ),
  );
}

class CyberOSApp extends StatelessWidget {
  const CyberOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CYBER_OS — Security Layer',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
