class AppConstants {
  AppConstants._();

  // The app's version, the same as pubspec.yaml's (test/startup_gate_test.dart
  // checks). Compared at start-up with Remote Config's min_app_version.
  static const String appVersion = '1.0.0';

  // Gameplay
  static const int maxStatPoints = 30;
  static const int maxPointsPerStat = 10;
  static const int maxTroopCount = 12000;
  static const String defaultWorldviewKey = '1830_fantasy';

  // Hive box names
  static const String hiveBoxBattleRecords = 'battle_records';
  static const String hiveBoxWarHistories = 'war_histories';
  static const String hiveBoxRace = 'race';
  static const String hiveBoxStrategies = 'strategies';
  static const String hiveBoxSettings = 'settings';

  // Firestore collection names
  static const String firestoreUsers = 'users';
  static const String firestorePvpMatches = 'pvp_matches';
  static const String firestoreBattleRecords = 'battle_records';
  static const String firestoreWarHistories = 'war_histories';
  static const String firestoreSystemConfig = 'system_config';
  static const String firestoreGameConfig = 'game_config';
  static const String firestoreAdminUids = 'admin_uids';

  // Subscription tiers
  static const String tierFree = 'free';
  static const String tierSub500 = 'sub500';
  static const String tierSub1000 = 'sub1000';
  static const String tierSub3000 = 'sub3000';

  // Daily rewards
  static const int dailyTicketsFree = 1;
  static const int dailyTicketsSub500 = 10;
  static const int dailyTicketsSub1000 = 15;
  static const int dailyTicketsSub3000 = 50;

  // Practice play
  static const int maxPracticePlayCount = 3;

  // PvP
  static const int pvpTimeoutHours = 24;

  // PvP is hidden in version 1 (agreed with the client, 28 Oct 2026). It comes
  // back in 1.1 with what Apple asks of apps that show other players' text: a
  // report button, a screen where the operator reviews reports, and blocking.
  // Off: no PvP tab or tiles, and /pvp-* routes go home. The server keeps PvP.
  static const bool pvpEnabled = false;

  // Strategy text
  static const int minStrategyLength = 5;
  static const int maxStrategyLength = 2000;

  // Race name
  static const int maxRaceNameLength = 20;
  static const int minRaceNameLength = 2;
}
