import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'bootstrap/hive_adapters.dart';
import 'core/constants/app_constants.dart';
import 'features/settings/settings_providers.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  await Hive.initFlutter();
  registerHiveAdapters();
  try {
    await Future.wait([
      Hive.openBox(AppConstants.hiveBoxRace),
      Hive.openBox(AppConstants.hiveBoxSettings),
      Hive.openBox(AppConstants.hiveBoxStrategies),
    ]);
  } catch (e) {
    debugPrint('Hive box open error: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        // Force Japanese locale — cannot be changed by user in this build
        localeProvider.overrideWith((ref) => const Locale('ja')),
      ],
      child: const App(),
    ),
  );
}
