import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dravik/screens/home_screen.dart'; // Updated
import 'package:dravik/services/mission_engine/mission_engine.dart';
import 'package:dravik/services/power_manager/mission_power_manager.dart';
import 'package:dravik/theme_provider.dart'; // Updated
import 'package:dravik/theme/app_theme.dart'; // Professional theme
import 'package:flutter/foundation.dart' show kReleaseMode, debugPrint;

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // .env file is optional; use fallback API keys if not found
      debugPrint('Warning: .env file not found, using fallback values');
    }

    // Safe access to dotenv with fallbacks
    String? getEnv(String key) {
      try {
        return dotenv.env[key];
      } catch (_) {
        return null;
      }
    }

    final supabaseUrl = getEnv('SUPABASE_URL');
    final supabaseAnonKey = getEnv('SUPABASE_ANON_KEY');

    if (kReleaseMode) {
      // In release, refuse to start without explicit env configuration
      if (supabaseUrl == null || supabaseAnonKey == null) {
        runApp(const MissingConfigApp());
        return;
      }
    }

    await supabase.Supabase.initialize(
      url: supabaseUrl ?? 'https://doiamxmhtbejfylbioky.supabase.co',
      anonKey: supabaseAnonKey ??
          // Fallback is used only in debug/profile builds
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvaWFteG1odGJlamZ5bGJpb2t5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE2NDcyOTAsImV4cCI6MjA2NzIyMzI5MH0.qewM7z1o5YPViUSArsvLTJnYvGL-pKq0bTybxD3gTHw',
    );

    await Hive.initFlutter();
    await Hive.openBox<String>('guides');
    await Hive.openBox<dynamic>('offline_data');
    await Hive.openBox<dynamic>('settings');
    await Hive.openBox('user');

    // Harden network and logging in release builds
    if (kReleaseMode) {
      // Silence logs in release to avoid leaking sensitive info
      debugPrint = (String? message, {int? wrapWidth}) {};
    }

    Get.put(MissionEngine(), permanent: true);
    await Get.put(MissionPowerManager(), permanent: true).initialize();

    runApp(const DravikApp());
  } catch (e, stackTrace) {
    debugPrint('Initialization error: $e\n$stackTrace');
    runApp(const ErrorApp());
  }
}

class DravikApp extends StatelessWidget {
  const DravikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) {
        return GetMaterialApp(
          title: 'Dravik',
          debugShowCheckedModeBanner: false,
          theme: isDark ? AppTheme.darkTheme() : AppTheme.lightTheme(),
          home: const HomeScreen(),
        );
      },
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Failed to initialize app. Please check logs.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
    );
  }
}

class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.lock_outline, size: 64, color: Color(0xFF1A73E8)),
                SizedBox(height: 16),
                Text(
                  'Secure configuration required',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Missing SUPABASE_URL or SUPABASE_ANON_KEY. Add them to .env before building a release.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
