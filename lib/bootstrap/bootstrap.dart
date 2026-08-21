import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../app.dart';
import '../core/constants/app_constants.dart';
import '../firebase_options.dart';
import '../services/local_storage/hive_storage_service.dart';
import 'hive_adapters.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize Hive and open all boxes BEFORE runApp so that providers
  // (currentRaceProvider, localeProvider) can read from Hive immediately
  // without hitting "box not open" errors on first evaluation.
  await Hive.initFlutter();
  registerHiveAdapters();
  // Open simple (untyped) boxes before runApp so providers that read
  // race/settings/locale on first evaluation don't hit "box not open" errors.
  // Typed boxes (battle_records, war_histories) are opened with adapters
  // inside HiveStorageService.initialize() to avoid type-mismatch errors.
  try {
    await Future.wait([
      Hive.openBox(AppConstants.hiveBoxRace),
      Hive.openBox(AppConstants.hiveBoxSettings),
      Hive.openBox(AppConstants.hiveBoxStrategies),
    ]);
  } catch (e) {
    debugPrint('Hive box open error: $e');
  }

  // Must happen before runApp: currentRaceProvider reads the race box on its
  // first evaluation and caches the result, so migrating any later would show
  // an upgrading player "create your race" for one launch.
  await migrateLegacyRaceIfNeeded();

  runApp(const ProviderScope(child: App()));
}
