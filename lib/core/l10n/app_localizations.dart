import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Steel Verdict'**
  String get appTitle;

  /// Generic loading text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Generic error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Confirm button label
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Back button label
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Next button label
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Ticket currency label
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get tickets;

  /// Splash screen loading text
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get splashInitializing;

  /// Splash screen tagline
  ///
  /// In en, this message translates to:
  /// **'Write your strategy. Command the battle.'**
  String get splashTagline;

  /// Auth screen title
  ///
  /// In en, this message translates to:
  /// **'Steel Verdict'**
  String get authTitle;

  /// Auth screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter the battlefield'**
  String get authSubtitle;

  /// Auth welcome line 1
  ///
  /// In en, this message translates to:
  /// **'Welcome to'**
  String get authWelcomeTo;

  /// Auth screen large app name
  ///
  /// In en, this message translates to:
  /// **'STEEL\nVERDICT'**
  String get authAppName;

  /// Auth screen sign in prompt
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your journey'**
  String get authContinueJourney;

  /// Google sign in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authGoogleSignIn;

  /// Apple sign in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authAppleSignIn;

  /// Coming soon placeholder
  ///
  /// In en, this message translates to:
  /// **'Coming soon.'**
  String get authComingSoon;

  /// Separator between auth options
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// Sign up with email button
  ///
  /// In en, this message translates to:
  /// **'Sign Up with Email'**
  String get authSignUpEmail;

  /// Log in button label
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get authLogIn;

  /// Sign in button label
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// Register button label
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegister;

  /// Anonymous sign in button label
  ///
  /// In en, this message translates to:
  /// **'Play as Guest'**
  String get authAnonymous;

  /// Continue as guest button
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get authContinueGuest;

  /// Guest data loss warning
  ///
  /// In en, this message translates to:
  /// **'Guest accounts may lose data if the app is uninstalled.'**
  String get authGuestWarning;

  /// Create account button label
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccount;

  /// Terms agreement text
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms & Privacy Policy'**
  String get authTerms;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// Anonymous account warning
  ///
  /// In en, this message translates to:
  /// **'Guest accounts may lose data. Link an email to secure your progress.'**
  String get authAnonymousWarning;

  /// Link account button label
  ///
  /// In en, this message translates to:
  /// **'Link Email to Account'**
  String get authLinkAccount;

  /// Link account screen title
  ///
  /// In en, this message translates to:
  /// **'Link Account'**
  String get authLinkTitle;

  /// Link account screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Add an email and password to permanently secure your progress.'**
  String get authLinkSubtitle;

  /// Email validation error
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get authEmailRequired;

  /// Email format validation error
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authEmailInvalid;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authPasswordRequired;

  /// Password length validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authPasswordMinLength;

  /// Account link success message
  ///
  /// In en, this message translates to:
  /// **'Account linked successfully!'**
  String get authLinkSuccess;

  /// Guest progress warning in banner
  ///
  /// In en, this message translates to:
  /// **'Your progress may be lost if you uninstall the app. Link an email address to secure your data.'**
  String get authGuestProgressWarning;

  /// Link account arrow button in banner
  ///
  /// In en, this message translates to:
  /// **'Link Account →'**
  String get authLinkAccountArrow;

  /// Home screen welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome, Commander'**
  String get homeWelcome;

  /// Home screen greeting with name
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String homeHello(String name);

  /// Guest account label on home
  ///
  /// In en, this message translates to:
  /// **'Guest Account'**
  String get homeGuestAccount;

  /// Quick actions section header
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get homeQuickActions;

  /// Play game quick action
  ///
  /// In en, this message translates to:
  /// **'Play Game'**
  String get homePlayGame;

  /// Daily missions quick action
  ///
  /// In en, this message translates to:
  /// **'Daily Missions'**
  String get homeDailyMissions;

  /// Daily reward ready badge
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get homeReady;

  /// Daily reward already claimed message
  ///
  /// In en, this message translates to:
  /// **'Daily reward already claimed.'**
  String get homeDailyAlreadyClaimed;

  /// Daily reward success message
  ///
  /// In en, this message translates to:
  /// **'Daily reward claimed! +3 tickets'**
  String get homeDailySuccess;

  /// Leaderboard quick action
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get homeLeaderboard;

  /// Recommended section header
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get homeRecommended;

  /// Challenge AI recommended tile title
  ///
  /// In en, this message translates to:
  /// **'Challenge AI'**
  String get homeChallengeAI;

  /// Challenge AI subtitle
  ///
  /// In en, this message translates to:
  /// **'Test your skills'**
  String get homeChallengeAISubtitle;

  /// Multiplayer recommended tile title
  ///
  /// In en, this message translates to:
  /// **'Multiplayer'**
  String get homeMultiplayer;

  /// Multiplayer subtitle
  ///
  /// In en, this message translates to:
  /// **'Play with friends'**
  String get homeMultiplayerSubtitle;

  /// War history subtitle on home
  ///
  /// In en, this message translates to:
  /// **'Review past battles'**
  String get homeWarHistorySubtitle;

  /// Ad reward success message
  ///
  /// In en, this message translates to:
  /// **'Ad reward earned! +2 tickets'**
  String get homeAdReward;

  /// Ad not available message
  ///
  /// In en, this message translates to:
  /// **'Ad not available. Try again later.'**
  String get homeAdNotAvailable;

  /// Link account banner text on home
  ///
  /// In en, this message translates to:
  /// **'Link your account to save data across devices'**
  String get homeLinkAccountBanner;

  /// Losses stat label
  ///
  /// In en, this message translates to:
  /// **'Losses'**
  String get homeLosses;

  /// Wins stat label
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get homeWins;

  /// Play button label
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get homePlay;

  /// PvP button label
  ///
  /// In en, this message translates to:
  /// **'PvP Battle'**
  String get homePvP;

  /// War History button label
  ///
  /// In en, this message translates to:
  /// **'War History'**
  String get homeWarHistory;

  /// Shop button label
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get homeShop;

  /// Daily reward button label
  ///
  /// In en, this message translates to:
  /// **'Daily Reward'**
  String get homeDailyReward;

  /// Watch ad for tickets button label
  ///
  /// In en, this message translates to:
  /// **'Watch Ad +2'**
  String get homeWatchAd;

  /// Daily reward available message
  ///
  /// In en, this message translates to:
  /// **'+3 tickets available!'**
  String get dailyRewardAvailable;

  /// Daily reward not available message
  ///
  /// In en, this message translates to:
  /// **'Come back tomorrow'**
  String get dailyRewardComeBack;

  /// Claim daily reward button
  ///
  /// In en, this message translates to:
  /// **'CLAIM'**
  String get dailyClaim;

  /// Watch ad button title
  ///
  /// In en, this message translates to:
  /// **'Watch Ad'**
  String get watchAdTitle;

  /// Watch ad description
  ///
  /// In en, this message translates to:
  /// **'Earn +2 tickets by watching a short ad'**
  String get watchAdDesc;

  /// Watch ad bonus label
  ///
  /// In en, this message translates to:
  /// **'+2'**
  String get watchAdBonus;

  /// Race creation screen title
  ///
  /// In en, this message translates to:
  /// **'Create Your Race'**
  String get raceCreationTitle;

  /// Race name field label
  ///
  /// In en, this message translates to:
  /// **'Race Name'**
  String get raceCreationNameLabel;

  /// Points remaining display
  ///
  /// In en, this message translates to:
  /// **'{points} points remaining'**
  String raceCreationPointsRemaining(int points);

  /// Confirm race creation button
  ///
  /// In en, this message translates to:
  /// **'Create Race'**
  String get raceCreationConfirm;

  /// World label in race creation
  ///
  /// In en, this message translates to:
  /// **'World: {world}'**
  String raceCreationWorld(String world);

  /// Allocate stats section header
  ///
  /// In en, this message translates to:
  /// **'Allocate Stats'**
  String get raceAllocateStats;

  /// Race creation success message
  ///
  /// In en, this message translates to:
  /// **'Race created! Let the wars begin.'**
  String get raceCreationSuccess;

  /// Race name input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your race name...'**
  String get raceNamePlaceholder;

  /// Stat points label
  ///
  /// In en, this message translates to:
  /// **'Stat Points'**
  String get raceStatPoints;

  /// All stat points allocated message
  ///
  /// In en, this message translates to:
  /// **'All points allocated!'**
  String get raceAllAllocated;

  /// Over stat point limit message
  ///
  /// In en, this message translates to:
  /// **'Over limit!'**
  String get raceOverLimit;

  /// Scenario selection title
  ///
  /// In en, this message translates to:
  /// **'Choose Scenario'**
  String get scenarioSelectionTitle;

  /// Locked scenario label
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get scenarioLocked;

  /// Unlock scenario button label
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get scenarioUnlock;

  /// Scenario difficulty label
  ///
  /// In en, this message translates to:
  /// **'Difficulty: {difficulty}'**
  String scenarioDifficulty(String difficulty);

  /// No scenarios placeholder
  ///
  /// In en, this message translates to:
  /// **'No scenarios available'**
  String get scenarioNoAvailable;

  /// Free scenario badge
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get scenarioFree;

  /// Versus enemy label
  ///
  /// In en, this message translates to:
  /// **'vs. {enemy}'**
  String scenarioVsEnemy(String enemy);

  /// Unlock scenario dialog title
  ///
  /// In en, this message translates to:
  /// **'Unlock Scenario'**
  String get unlockScenarioTitle;

  /// Unlock by watching ad button
  ///
  /// In en, this message translates to:
  /// **'Watch Ad'**
  String get unlockWatchAd;

  /// Watch ad unlock description
  ///
  /// In en, this message translates to:
  /// **'Unlock by watching a short advertisement'**
  String get unlockWatchAdDesc;

  /// Free unlock badge
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get unlockFree;

  /// Purchase unlock button
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get unlockPurchase;

  /// Purchase unlock description
  ///
  /// In en, this message translates to:
  /// **'Permanently unlock this scenario'**
  String get unlockPurchaseDesc;

  /// Game mode selection title
  ///
  /// In en, this message translates to:
  /// **'Choose Game Mode'**
  String get gameModeTitle;

  /// Choose mode screen title (short)
  ///
  /// In en, this message translates to:
  /// **'Choose Mode'**
  String get gameModeChooseMode;

  /// Normal game mode
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get gameModeNormal;

  /// Tabletop game mode
  ///
  /// In en, this message translates to:
  /// **'Tabletop'**
  String get gameModeTabletop;

  /// Epic game mode
  ///
  /// In en, this message translates to:
  /// **'Epic'**
  String get gameModeEpic;

  /// Boss game mode
  ///
  /// In en, this message translates to:
  /// **'Boss'**
  String get gameModeBoss;

  /// Practice game mode
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get gameModePractice;

  /// Practice mode description
  ///
  /// In en, this message translates to:
  /// **'Test your strategy for free. No report saved.'**
  String get gameModePracticeDesc;

  /// Normal mode description
  ///
  /// In en, this message translates to:
  /// **'Standard AI-judged battle with full report.'**
  String get gameModeNormalDesc;

  /// Tabletop mode description
  ///
  /// In en, this message translates to:
  /// **'Enhanced tactical analysis with detailed breakdown.'**
  String get gameModeTabletopDesc;

  /// Epic mode description
  ///
  /// In en, this message translates to:
  /// **'Full campaign-style narrative battle.'**
  String get gameModeEpicDesc;

  /// Epic mode subscription requirement
  ///
  /// In en, this message translates to:
  /// **'Requires Commander subscription or higher'**
  String get gameModeEpicRequires;

  /// Boss mode description
  ///
  /// In en, this message translates to:
  /// **'Face a legendary enemy. Extreme difficulty.'**
  String get gameModeBossDesc;

  /// Boss mode unlock requirement
  ///
  /// In en, this message translates to:
  /// **'Requires special unlock'**
  String get gameModeBossRequires;

  /// Start battle button
  ///
  /// In en, this message translates to:
  /// **'Start Battle'**
  String get gameModeStartBattle;

  /// Free mode badge
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get gameModeFree;

  /// Locked mode label
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get gameModeLocked;

  /// AI model selector label
  ///
  /// In en, this message translates to:
  /// **'AI Model'**
  String get gameModeAiModel;

  /// AI model selector description
  ///
  /// In en, this message translates to:
  /// **'Choose which AI judges your battle'**
  String get gameModeAiModelDesc;

  /// Battle screen title
  ///
  /// In en, this message translates to:
  /// **'Battle'**
  String get battleTitle;

  /// Enemy label in battle
  ///
  /// In en, this message translates to:
  /// **'Enemy: {enemy}'**
  String battleEnemyLabel(String enemy);

  /// Mode label in battle
  ///
  /// In en, this message translates to:
  /// **'Mode: {mode}'**
  String battleModeLabel(String mode);

  /// Strategy input label
  ///
  /// In en, this message translates to:
  /// **'Your Strategy'**
  String get battleStrategyLabel;

  /// Strategy input hint short
  ///
  /// In en, this message translates to:
  /// **'Describe your battle strategy in detail...'**
  String get battleStrategyHint;

  /// Strategy input hint with examples
  ///
  /// In en, this message translates to:
  /// **'e.g. Fight like Napoleon\n\nDescribe your battle strategy in detail...\n\nExamples:\n- Flank the enemy from the east\n- Use cavalry to disrupt supply lines\n- Deploy archers on the high ground'**
  String get battleStrategyHintFull;

  /// Need more characters message
  ///
  /// In en, this message translates to:
  /// **'Need {count} more characters'**
  String battleNeedMoreChars(int count);

  /// Submit strategy button label
  ///
  /// In en, this message translates to:
  /// **'Submit Strategy'**
  String get battleSubmit;

  /// Load saved strategy button label
  ///
  /// In en, this message translates to:
  /// **'Load Saved Strategy'**
  String get battleLoadSaved;

  /// Battle result screen title
  ///
  /// In en, this message translates to:
  /// **'Battle Result'**
  String get battleResultTitle;

  /// Victory outcome label
  ///
  /// In en, this message translates to:
  /// **'Victory!'**
  String get battleResultVictory;

  /// Defeat outcome label
  ///
  /// In en, this message translates to:
  /// **'Defeat'**
  String get battleResultDefeat;

  /// Draw outcome label
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get battleResultDraw;

  /// Victory full caps display
  ///
  /// In en, this message translates to:
  /// **'VICTORY!'**
  String get battleVictoryFull;

  /// Defeat full caps display
  ///
  /// In en, this message translates to:
  /// **'DEFEAT'**
  String get battleDefeatFull;

  /// Draw full caps display
  ///
  /// In en, this message translates to:
  /// **'DRAW'**
  String get battleDrawFull;

  /// Save battle to history button
  ///
  /// In en, this message translates to:
  /// **'Save to History'**
  String get battleSaveToHistory;

  /// No battle report placeholder
  ///
  /// In en, this message translates to:
  /// **'No report available.'**
  String get battleNoReport;

  /// Battle report section title
  ///
  /// In en, this message translates to:
  /// **'Battle Report'**
  String get battleReport;

  /// Play again button
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get battlePlayAgain;

  /// View war history button
  ///
  /// In en, this message translates to:
  /// **'View War History'**
  String get battleViewWarHistory;

  /// General staff overlay title
  ///
  /// In en, this message translates to:
  /// **'General Staff'**
  String get generalStaffTitle;

  /// General staff analyzing message
  ///
  /// In en, this message translates to:
  /// **'Analyzing your battle plan...'**
  String get generalStaffAnalyzing;

  /// General staff status message 1
  ///
  /// In en, this message translates to:
  /// **'Reviewing tactical situation...'**
  String get generalStaffMsg1;

  /// General staff status message 2
  ///
  /// In en, this message translates to:
  /// **'Analyzing terrain advantages...'**
  String get generalStaffMsg2;

  /// General staff status message 3
  ///
  /// In en, this message translates to:
  /// **'Assessing enemy formations...'**
  String get generalStaffMsg3;

  /// General staff status message 4
  ///
  /// In en, this message translates to:
  /// **'Calculating force ratios...'**
  String get generalStaffMsg4;

  /// General staff status message 5
  ///
  /// In en, this message translates to:
  /// **'Consulting strategic doctrine...'**
  String get generalStaffMsg5;

  /// General staff status message 6
  ///
  /// In en, this message translates to:
  /// **'Preparing battle assessment...'**
  String get generalStaffMsg6;

  /// Saved strategies picker title
  ///
  /// In en, this message translates to:
  /// **'Saved Strategies'**
  String get savedStrategiesTitle;

  /// Saved strategies count
  ///
  /// In en, this message translates to:
  /// **'{count} saved'**
  String savedStrategiesCount(int count);

  /// No saved strategies placeholder
  ///
  /// In en, this message translates to:
  /// **'No saved strategies yet'**
  String get savedStrategiesEmpty;

  /// PvP lobby screen title
  ///
  /// In en, this message translates to:
  /// **'PvP Lobby'**
  String get pvpLobbyTitle;

  /// PvP lobby subtitle
  ///
  /// In en, this message translates to:
  /// **'Challenge another commander to battle!'**
  String get pvpSubtitle;

  /// Find PvP match button label
  ///
  /// In en, this message translates to:
  /// **'Find Match'**
  String get pvpFindMatch;

  /// PvP searching for match
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get pvpSearching;

  /// PvP match created message
  ///
  /// In en, this message translates to:
  /// **'Match created! Waiting for opponent...'**
  String get pvpMatchCreated;

  /// PvP joined match message
  ///
  /// In en, this message translates to:
  /// **'Joined a match!'**
  String get pvpJoined;

  /// Active matches section label
  ///
  /// In en, this message translates to:
  /// **'Active Matches'**
  String get pvpActiveMatches;

  /// No matches placeholder
  ///
  /// In en, this message translates to:
  /// **'No active matches'**
  String get pvpNoMatches;

  /// PvP find match help text
  ///
  /// In en, this message translates to:
  /// **'Find a match to get started!'**
  String get pvpFindMatchHelp;

  /// PvP countdown label
  ///
  /// In en, this message translates to:
  /// **'Time remaining: {time}'**
  String pvpCountdown(String time);

  /// PvP battle screen title
  ///
  /// In en, this message translates to:
  /// **'PvP Battle'**
  String get pvpBattleTitle;

  /// PvP waiting for opponent
  ///
  /// In en, this message translates to:
  /// **'Waiting for opponent to join...'**
  String get pvpWaitingOpponent;

  /// PvP strategy submitted message
  ///
  /// In en, this message translates to:
  /// **'Strategy submitted! Waiting for the battle to resolve...'**
  String get pvpStrategySubmitted;

  /// PvP battle result label
  ///
  /// In en, this message translates to:
  /// **'Battle Result'**
  String get pvpBattleResultLabel;

  /// PvP you won message
  ///
  /// In en, this message translates to:
  /// **'You won!'**
  String get pvpYouWon;

  /// PvP draw message
  ///
  /// In en, this message translates to:
  /// **'Draw!'**
  String get pvpDraw;

  /// PvP opponent won message
  ///
  /// In en, this message translates to:
  /// **'Opponent won'**
  String get pvpOpponentWon;

  /// PvP your strategy label
  ///
  /// In en, this message translates to:
  /// **'Your Strategy'**
  String get pvpYourStrategy;

  /// PvP strategy input hint
  ///
  /// In en, this message translates to:
  /// **'Describe your battle strategy...'**
  String get pvpStrategyHint;

  /// PvP submit strategy button
  ///
  /// In en, this message translates to:
  /// **'Submit Strategy'**
  String get pvpSubmitStrategy;

  /// PvP timer expired label
  ///
  /// In en, this message translates to:
  /// **'EXPIRED'**
  String get pvpTimerExpired;

  /// PvP match card waiting for opponent
  ///
  /// In en, this message translates to:
  /// **'Waiting for opponent...'**
  String get pvpWaitingForOpponent;

  /// PvP match card submit strategy prompt
  ///
  /// In en, this message translates to:
  /// **'Submit your strategy!'**
  String get pvpSubmitYourStrategy;

  /// Opponent stats hidden message
  ///
  /// In en, this message translates to:
  /// **'Opponent stats hidden'**
  String get pvpOpponentStatsHidden;

  /// PvP match card victory
  ///
  /// In en, this message translates to:
  /// **'Victory!'**
  String get pvpVictory;

  /// PvP match card defeat
  ///
  /// In en, this message translates to:
  /// **'Defeat'**
  String get pvpDefeat;

  /// PvP match timed out
  ///
  /// In en, this message translates to:
  /// **'Timed out'**
  String get pvpTimeout;

  /// War history screen title
  ///
  /// In en, this message translates to:
  /// **'War History'**
  String get warHistoryTitle;

  /// Solo battles tab label
  ///
  /// In en, this message translates to:
  /// **'Solo Battles'**
  String get warHistorySoloBattles;

  /// Favorites tab label
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get warHistoryFavorites;

  /// Empty war history message
  ///
  /// In en, this message translates to:
  /// **'No battles recorded yet'**
  String get warHistoryEmpty;

  /// Empty war history with instruction
  ///
  /// In en, this message translates to:
  /// **'No battles recorded yet.\nStart playing to build your history!'**
  String get warHistoryEmptyMsg;

  /// War history load error
  ///
  /// In en, this message translates to:
  /// **'Failed to load history: {error}'**
  String warHistoryLoadError(String error);

  /// No favorites placeholder
  ///
  /// In en, this message translates to:
  /// **'No favorites yet.\nStar battles to save them here!'**
  String get warHistoryNoFavoritesMsg;

  /// Generate war chronicle button
  ///
  /// In en, this message translates to:
  /// **'Generate Chronicle'**
  String get warHistoryGenerate;

  /// Share to X button
  ///
  /// In en, this message translates to:
  /// **'Share to X'**
  String get warHistoryShare;

  /// Sharing in progress label
  ///
  /// In en, this message translates to:
  /// **'Sharing...'**
  String get warHistorySharing;

  /// Battle detail screen title
  ///
  /// In en, this message translates to:
  /// **'Battle Detail'**
  String get warHistoryBattleDetail;

  /// Battle not found message
  ///
  /// In en, this message translates to:
  /// **'Battle record not found.'**
  String get warHistoryBattleNotFound;

  /// Battle report section in detail
  ///
  /// In en, this message translates to:
  /// **'Battle Report'**
  String get warHistoryBattleReport;

  /// War chronicle section label
  ///
  /// In en, this message translates to:
  /// **'War Chronicle'**
  String get warHistoryWarChronicle;

  /// War chronicle generate description
  ///
  /// In en, this message translates to:
  /// **'Generate a detailed war chronicle from this battle'**
  String get warHistoryGenerateDesc;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings profile section
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// Edit button in settings
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get settingsEdit;

  /// Coming soon placeholder in settings
  ///
  /// In en, this message translates to:
  /// **'Coming soon.'**
  String get settingsComingSoon;

  /// Change password option
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get settingsChangePassword;

  /// Link account first message
  ///
  /// In en, this message translates to:
  /// **'Link an account first.'**
  String get settingsLinkAccountFirst;

  /// Linked accounts section
  ///
  /// In en, this message translates to:
  /// **'Linked Accounts'**
  String get settingsLinkedAccounts;

  /// Guest account label in settings
  ///
  /// In en, this message translates to:
  /// **'Guest Account'**
  String get settingsGuestAccount;

  /// Account section in settings
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// Preferences section in settings
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// Notifications setting
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// Sound and music setting
  ///
  /// In en, this message translates to:
  /// **'Sound & Music'**
  String get settingsSoundMusic;

  /// Support section in settings
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSupport;

  /// Help center link
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get settingsHelpCenter;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Subscription setting label
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSubscription;

  /// Clear data button label
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get settingsClearData;

  /// Clear data confirmation message
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all local data. Cannot be undone.'**
  String get settingsClearDataConfirm;

  /// Data cleared success message
  ///
  /// In en, this message translates to:
  /// **'All data cleared.'**
  String get settingsAllDataCleared;

  /// Race section label in settings
  ///
  /// In en, this message translates to:
  /// **'Race'**
  String get settingsRace;

  /// View current race details button label
  ///
  /// In en, this message translates to:
  /// **'My Race'**
  String get settingsViewRace;

  /// Shown when player has no race
  ///
  /// In en, this message translates to:
  /// **'No race created yet.'**
  String get settingsViewRaceNoRace;

  /// Change race button label
  ///
  /// In en, this message translates to:
  /// **'Change Race'**
  String get settingsChangeRace;

  /// Change race confirmation message
  ///
  /// In en, this message translates to:
  /// **'Your current race will be deleted and you will create a new one. This cannot be undone.'**
  String get settingsChangeRaceConfirm;

  /// Sign out button label
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOut;

  /// Sign out confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get settingsSignOutConfirm;

  /// Privacy policy link label
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'Steel Verdict v1.0.0'**
  String get settingsVersion;

  /// Select language dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get settingsSelectLanguage;

  /// Personal info section
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get settingsPersonalInfo;

  /// Link account option in settings
  ///
  /// In en, this message translates to:
  /// **'Link Account'**
  String get settingsLinkAccount;

  /// Current plan label in settings
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get settingsCurrentPlan;

  /// Upgrade button in settings
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get settingsUpgrade;

  /// Language changed success message
  ///
  /// In en, this message translates to:
  /// **'Language changed!'**
  String get settingsLanguageChanged;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLangEnglish;

  /// Japanese language option
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get settingsLangJapanese;

  /// Shop screen title
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopTitle;

  /// Subscriptions section label
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get shopSubscriptions;

  /// Tickets section label
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get shopTickets;

  /// Restore purchases button label
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get shopRestore;

  /// Restore button short label
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get shopRestoreShort;

  /// Shop subscriptions subtitle
  ///
  /// In en, this message translates to:
  /// **'Unlock more tickets and features'**
  String get shopUnlockMore;

  /// Ticket packs section header
  ///
  /// In en, this message translates to:
  /// **'TICKET PACKS'**
  String get shopTicketPacks;

  /// One-time purchases subtitle
  ///
  /// In en, this message translates to:
  /// **'One-time ticket purchases'**
  String get shopOneTimePurchases;

  /// Small ticket pack name
  ///
  /// In en, this message translates to:
  /// **'Small Pack'**
  String get shopSmallPack;

  /// Small pack description
  ///
  /// In en, this message translates to:
  /// **'10 battle tickets'**
  String get shopSmallPackDesc;

  /// Large ticket pack name
  ///
  /// In en, this message translates to:
  /// **'Large Pack'**
  String get shopLargePack;

  /// Large pack description
  ///
  /// In en, this message translates to:
  /// **'30 battle tickets — Best value!'**
  String get shopLargePackDesc;

  /// Scenario packs section header
  ///
  /// In en, this message translates to:
  /// **'SCENARIO PACKS'**
  String get shopScenarioPacks;

  /// Scenario packs subtitle
  ///
  /// In en, this message translates to:
  /// **'Additional battle scenarios'**
  String get shopScenarioPacksDesc;

  /// Ancient battles pack name
  ///
  /// In en, this message translates to:
  /// **'Ancient Battles Pack'**
  String get shopAncientBattles;

  /// Ancient battles pack description
  ///
  /// In en, this message translates to:
  /// **'Unlock 5 historical scenarios'**
  String get shopAncientBattlesDesc;

  /// Auto-renew disclaimer
  ///
  /// In en, this message translates to:
  /// **'Subscriptions auto-renew unless cancelled. Prices vary by region.'**
  String get shopAutoRenew;

  /// Most popular badge on subscription
  ///
  /// In en, this message translates to:
  /// **'MOST POPULAR'**
  String get shopMostPopular;

  /// Subscribe button
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get shopSubscribe;

  /// Free tier label
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get subscriptionFree;

  /// Sub 500 tier label
  ///
  /// In en, this message translates to:
  /// **'Commander'**
  String get subscriptionCommander;

  /// Sub 1000 tier label
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get subscriptionGeneral;

  /// Sub 3000 tier label
  ///
  /// In en, this message translates to:
  /// **'Warlord'**
  String get subscriptionWarlord;

  /// Game hub screen title
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get gameHubTitle;

  /// Game hub choose mode header
  ///
  /// In en, this message translates to:
  /// **'Choose Game Mode'**
  String get gameHubChooseMode;

  /// Game hub mode selection subtitle
  ///
  /// In en, this message translates to:
  /// **'Select how you want to battle'**
  String get gameHubSelectHow;

  /// Single player mode title
  ///
  /// In en, this message translates to:
  /// **'Single Player'**
  String get gameHubSinglePlayer;

  /// Play vs AI subtitle
  ///
  /// In en, this message translates to:
  /// **'Play vs AI'**
  String get gameHubPlayVsAI;

  /// Single player description
  ///
  /// In en, this message translates to:
  /// **'Choose a scenario and challenge historical commanders. Test your strategy against AI-judged battles.'**
  String get gameHubSinglePlayerDesc;

  /// VS AI badge
  ///
  /// In en, this message translates to:
  /// **'VS AI'**
  String get gameHubVsAI;

  /// Multiplayer mode title
  ///
  /// In en, this message translates to:
  /// **'Multiplayer'**
  String get gameHubMultiplayer;

  /// Play online subtitle
  ///
  /// In en, this message translates to:
  /// **'Play online with friends'**
  String get gameHubPlayOnline;

  /// Multiplayer description
  ///
  /// In en, this message translates to:
  /// **'Compete against real players. Submit your strategy within 24 hours and let AI judge the outcome.'**
  String get gameHubMultiplayerDesc;

  /// Live badge
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get gameHubLive;

  /// Management section header in game hub
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get gameHubManagement;

  /// War history nav description
  ///
  /// In en, this message translates to:
  /// **'View your past battles'**
  String get gameHubWarHistoryDesc;

  /// Shop nav description
  ///
  /// In en, this message translates to:
  /// **'Get tickets & subscriptions'**
  String get gameHubShopDesc;

  /// Difficulty level 1
  ///
  /// In en, this message translates to:
  /// **'Novice'**
  String get difficultyNovice;

  /// Difficulty level 2
  ///
  /// In en, this message translates to:
  /// **'Soldier'**
  String get difficultySoldier;

  /// Difficulty level 3
  ///
  /// In en, this message translates to:
  /// **'Captain'**
  String get difficultyCaptain;

  /// Difficulty level 4
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get difficultyGeneral;

  /// Difficulty level 5
  ///
  /// In en, this message translates to:
  /// **'Warlord'**
  String get difficultyWarlord;

  /// Unknown difficulty
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get difficultyUnknown;

  /// PvP match status: waiting
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get pvpStatusWaiting;

  /// PvP match status: active
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get pvpStatusActive;

  /// PvP match status: resolved
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get pvpStatusResolved;

  /// PvP match status: timed out
  ///
  /// In en, this message translates to:
  /// **'Timed Out'**
  String get pvpStatusTimedOut;

  /// PvP loading match message
  ///
  /// In en, this message translates to:
  /// **'Loading match...'**
  String get pvpLoadingMatch;

  /// Generic opponent label in PvP
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get pvpOpponent;

  /// PvP status label prefix
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get pvpStatusPrefix;

  /// PvP match label prefix
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get pvpMatchPrefix;

  /// War chronicle generation success
  ///
  /// In en, this message translates to:
  /// **'Chronicle generated!'**
  String get warChronicleGenerated;

  /// Shared to X success message
  ///
  /// In en, this message translates to:
  /// **'Shared to X!'**
  String get sharedToX;

  /// Shared to X with image success
  ///
  /// In en, this message translates to:
  /// **'Shared to X with image!'**
  String get sharedToXWithImage;

  /// Footer label on parchment share image
  ///
  /// In en, this message translates to:
  /// **'Steel Verdict Chronicle'**
  String get parchmentFooter;

  /// Default display name for anonymous users
  ///
  /// In en, this message translates to:
  /// **'Anonymous Commander'**
  String get anonymousCommander;

  /// Battle save success message
  ///
  /// In en, this message translates to:
  /// **'Battle saved to history!'**
  String get battleSavedToHistory;

  /// Added to favorites success message
  ///
  /// In en, this message translates to:
  /// **'Added to favorites!'**
  String get favoritesAdded;

  /// Removed from favorites message
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get favoritesRemoved;

  /// Commander tier with price
  ///
  /// In en, this message translates to:
  /// **'Commander (¥500)'**
  String get subscriptionCommanderPrice;

  /// General tier with price
  ///
  /// In en, this message translates to:
  /// **'General (¥1,000)'**
  String get subscriptionGeneralPrice;

  /// Warlord tier with price
  ///
  /// In en, this message translates to:
  /// **'Warlord (¥3,000)'**
  String get subscriptionWarlordPrice;

  /// Tickets per day label on subscription card
  ///
  /// In en, this message translates to:
  /// **'{count} tickets/day'**
  String shopTicketsPerDay(int count);

  /// Commander plan: 10 tickets feature
  ///
  /// In en, this message translates to:
  /// **'10 daily tickets'**
  String get shopFeature10Tickets;

  /// Commander plan: basic scenarios feature
  ///
  /// In en, this message translates to:
  /// **'All basic scenarios'**
  String get shopFeatureBasicScenarios;

  /// Commander plan: save 20 strategies feature
  ///
  /// In en, this message translates to:
  /// **'Save up to 20 strategies'**
  String get shopFeatureSave20Strategies;

  /// Commander plan: priority queue feature
  ///
  /// In en, this message translates to:
  /// **'Priority battle queue'**
  String get shopFeaturePriorityQueue;

  /// General plan: 20 tickets feature
  ///
  /// In en, this message translates to:
  /// **'20 daily tickets'**
  String get shopFeature20Tickets;

  /// General plan: epic mode feature
  ///
  /// In en, this message translates to:
  /// **'Epic mode unlocked'**
  String get shopFeatureEpicMode;

  /// General plan: unlimited history feature
  ///
  /// In en, this message translates to:
  /// **'Unlimited war history'**
  String get shopFeatureUnlimitedHistory;

  /// General plan: save 50 strategies feature
  ///
  /// In en, this message translates to:
  /// **'Save up to 50 strategies'**
  String get shopFeatureSave50Strategies;

  /// General plan: all commander features
  ///
  /// In en, this message translates to:
  /// **'All Commander features'**
  String get shopFeatureAllCommanderFeatures;

  /// Warlord plan: 50 tickets feature
  ///
  /// In en, this message translates to:
  /// **'50 daily tickets'**
  String get shopFeature50Tickets;

  /// Warlord plan: all modes feature
  ///
  /// In en, this message translates to:
  /// **'All modes unlocked'**
  String get shopFeatureAllModes;

  /// Warlord plan: boss battles feature
  ///
  /// In en, this message translates to:
  /// **'Boss battles enabled'**
  String get shopFeatureBossBattles;

  /// Warlord plan: unlimited all feature
  ///
  /// In en, this message translates to:
  /// **'Unlimited everything'**
  String get shopFeatureUnlimitedAll;

  /// Warlord plan: all general features
  ///
  /// In en, this message translates to:
  /// **'All General features'**
  String get shopFeatureAllGeneralFeatures;

  /// Splash screen title line 1
  ///
  /// In en, this message translates to:
  /// **'STEEL'**
  String get splashTitleLine1;

  /// Splash screen title line 2
  ///
  /// In en, this message translates to:
  /// **'VERDICT'**
  String get splashTitleLine2;

  /// Bottom nav: Home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom nav: Game
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get navGame;

  /// Bottom nav: Missions
  ///
  /// In en, this message translates to:
  /// **'Missions'**
  String get navMissions;

  /// Bottom nav: Profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Dismiss snackbar action button
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Purchase started success message
  ///
  /// In en, this message translates to:
  /// **'Purchase initiated!'**
  String get shopPurchaseInitiated;

  /// Purchases restored success message
  ///
  /// In en, this message translates to:
  /// **'Purchases restored!'**
  String get shopPurchasesRestored;

  /// Purchase failed error prefix
  ///
  /// In en, this message translates to:
  /// **'Purchase failed'**
  String get shopPurchaseFailed;

  /// Restore failed error prefix
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get shopRestoreFailed;

  /// Attack stat name (legacy)
  ///
  /// In en, this message translates to:
  /// **'Attack'**
  String get statAttack;

  /// Defense stat name (legacy)
  ///
  /// In en, this message translates to:
  /// **'Defense'**
  String get statDefense;

  /// Speed stat name (legacy)
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get statSpeed;

  /// Morale stat name (legacy)
  ///
  /// In en, this message translates to:
  /// **'Morale'**
  String get statMorale;

  /// Magic stat name
  ///
  /// In en, this message translates to:
  /// **'Magic'**
  String get statMagic;

  /// Leadership stat name (legacy)
  ///
  /// In en, this message translates to:
  /// **'Leadership'**
  String get statLeadership;

  /// Strength stat name
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get statStrength;

  /// Intellect stat name
  ///
  /// In en, this message translates to:
  /// **'Intellect'**
  String get statIntellect;

  /// Skill stat name
  ///
  /// In en, this message translates to:
  /// **'Skill'**
  String get statSkill;

  /// Art stat name
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get statArt;

  /// Life stat name
  ///
  /// In en, this message translates to:
  /// **'Life'**
  String get statLife;

  /// Label for race overview field
  ///
  /// In en, this message translates to:
  /// **'Race Overview'**
  String get raceOverviewLabel;

  /// Hint text for race overview field
  ///
  /// In en, this message translates to:
  /// **'Brief description of your race\'s background, culture, or fighting style...'**
  String get raceOverviewHint;

  /// No description provided for @authErrNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get authErrNoAccount;

  /// No description provided for @authErrWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get authErrWrongPassword;

  /// No description provided for @authErrEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get authErrEmailInUse;

  /// No description provided for @authErrWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Use at least 6 characters.'**
  String get authErrWeakPassword;

  /// No description provided for @authErrInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get authErrInvalidEmail;

  /// No description provided for @authErrCredentialInUse.
  ///
  /// In en, this message translates to:
  /// **'This credential is already linked to another account.'**
  String get authErrCredentialInUse;

  /// No description provided for @authErrDefault.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed.'**
  String get authErrDefault;

  /// No description provided for @authErrSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign in.'**
  String get authErrSignInFailed;

  /// No description provided for @authErrSignOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign out failed.'**
  String get authErrSignOutFailed;

  /// Save current strategy button label
  ///
  /// In en, this message translates to:
  /// **'Save Strategy'**
  String get battleSaveStrategy;

  /// Save strategy dialog title
  ///
  /// In en, this message translates to:
  /// **'Save Strategy'**
  String get battleSaveStrategyDialogTitle;

  /// Strategy name input hint
  ///
  /// In en, this message translates to:
  /// **'Give your strategy a name...'**
  String get battleSaveStrategyNameHint;

  /// Strategy saved success message
  ///
  /// In en, this message translates to:
  /// **'Strategy saved!'**
  String get battleSaveStrategySuccess;

  /// Strategy save limit error
  ///
  /// In en, this message translates to:
  /// **'Save limit reached. Upgrade your plan to save more strategies.'**
  String get battleSaveStrategyLimitReached;

  /// X share ticket reward earned message
  ///
  /// In en, this message translates to:
  /// **'+1 ticket earned for sharing to X!'**
  String get xShareRewardEarned;

  /// X share reward already claimed message
  ///
  /// In en, this message translates to:
  /// **'X share reward already claimed today.'**
  String get xShareRewardAlreadyClaimed;

  /// Historical puzzle game mode name
  ///
  /// In en, this message translates to:
  /// **'Historical Puzzle'**
  String get gameModeHistoryPuzzle;

  /// Historical puzzle game mode description
  ///
  /// In en, this message translates to:
  /// **'Fixed historical forces. No clear stage — beat your personal best!'**
  String get gameModeHistoryPuzzleDesc;

  /// Personal best label
  ///
  /// In en, this message translates to:
  /// **'Personal Best'**
  String get personalBest;

  /// Personal best score format
  ///
  /// In en, this message translates to:
  /// **'{wins} wins / {total} attempts'**
  String personalBestScore(int wins, int total);

  /// No personal best record yet
  ///
  /// In en, this message translates to:
  /// **'No record yet'**
  String get personalBestNone;

  /// Skip ad button label with ticket cost
  ///
  /// In en, this message translates to:
  /// **'Skip (-1 ticket)'**
  String get skipAdCost;

  /// Watch ad for free button label
  ///
  /// In en, this message translates to:
  /// **'Watch Ad (Free)'**
  String get watchAdFree;

  /// Ad skipped success message
  ///
  /// In en, this message translates to:
  /// **'Ad skipped. -1 ticket.'**
  String get skipAdSuccess;

  /// Not enough tickets to skip ad message
  ///
  /// In en, this message translates to:
  /// **'Not enough tickets to skip.'**
  String get skipAdNoTickets;

  /// Practice mode ad choice prompt
  ///
  /// In en, this message translates to:
  /// **'An ad is ready. Watch it for free or skip.'**
  String get practiceAdPrompt;

  /// Content filter blocked message
  ///
  /// In en, this message translates to:
  /// **'Your text contains inappropriate content. Please revise.'**
  String get contentFilterBlocked;

  /// Generic battle failure message
  ///
  /// In en, this message translates to:
  /// **'Battle failed. Please try again.'**
  String get battleFailedRetry;

  /// Auth required error message
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue.'**
  String get battleSignInRequired;

  /// The exact word user must type to confirm deletion
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteConfirmWord;

  /// Hint text inside the confirmation input field
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get deleteConfirmHint;

  /// Banner shown on home when player has no race
  ///
  /// In en, this message translates to:
  /// **'Create your race to begin'**
  String get homeNoRaceBanner;

  /// Subtitle for no-race banner on home
  ///
  /// In en, this message translates to:
  /// **'Tap Play to set up your race and enter battle'**
  String get homeNoRaceBannerSub;

  /// World setting banner label on home screen
  ///
  /// In en, this message translates to:
  /// **'World Setting'**
  String get homeWorldSetting;

  /// Change world setting button on home screen
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get homeWorldSettingChange;

  /// Shown on home when no world setting selected yet
  ///
  /// In en, this message translates to:
  /// **'Select World'**
  String get homeWorldSettingNone;

  /// Battle type selection screen title
  ///
  /// In en, this message translates to:
  /// **'Battle Type'**
  String get battleTypeTitle;

  /// Battle type selection header
  ///
  /// In en, this message translates to:
  /// **'Choose Battle Type'**
  String get battleTypeChoose;

  /// Battle type selection subtitle
  ///
  /// In en, this message translates to:
  /// **'Select the type of battle you want to fight'**
  String get battleTypeSubtitle;

  /// Standard battle type title
  ///
  /// In en, this message translates to:
  /// **'Standard Battle'**
  String get battleTypeStandard;

  /// Standard battle type description
  ///
  /// In en, this message translates to:
  /// **'Choose a scenario and challenge historical commanders with multiple sub-modes.'**
  String get battleTypeStandardDesc;

  /// Badge showing sub-mode count for standard battle
  ///
  /// In en, this message translates to:
  /// **'4 MODES'**
  String get battleTypeSubModeBadge;

  /// Boss battle type title
  ///
  /// In en, this message translates to:
  /// **'Boss Battle'**
  String get battleTypeBoss;

  /// Boss battle type description
  ///
  /// In en, this message translates to:
  /// **'Face a legendary enemy in an extreme difficulty encounter.'**
  String get battleTypeBossDesc;

  /// Badge label for boss battle type
  ///
  /// In en, this message translates to:
  /// **'BOSS'**
  String get battleTypeBossBadge;

  /// History puzzle battle type title
  ///
  /// In en, this message translates to:
  /// **'History Puzzle'**
  String get battleTypeHistory;

  /// History puzzle battle type description
  ///
  /// In en, this message translates to:
  /// **'Fixed historical forces with no clear stage. Beat your personal best!'**
  String get battleTypeHistoryDesc;

  /// Badge label for history puzzle battle type
  ///
  /// In en, this message translates to:
  /// **'PUZZLE'**
  String get battleTypeHistoryBadge;

  /// Urgent prompt when opponent has submitted strategy
  ///
  /// In en, this message translates to:
  /// **'Opponent submitted — submit your strategy now!'**
  String get pvpOpponentSubmittedUrge;

  /// Status when both players submitted and AI is resolving
  ///
  /// In en, this message translates to:
  /// **'Both submitted — battle resolving...'**
  String get pvpBothSubmittedResolving;

  /// My race tile label in Game Hub management
  ///
  /// In en, this message translates to:
  /// **'My Race'**
  String get gameHubMyRace;

  /// My race tile subtitle in Game Hub management
  ///
  /// In en, this message translates to:
  /// **'View your race stats and traits'**
  String get gameHubMyRaceDesc;

  /// Shown in My Race sheet when no race exists
  ///
  /// In en, this message translates to:
  /// **'No race created yet. Tap Play to create one.'**
  String get myRaceNoRace;

  /// Stats section label in My Race sheet
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get myRaceStats;

  /// Overview section label in My Race sheet
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get myRaceOverview;

  /// Validation: strategy field empty
  ///
  /// In en, this message translates to:
  /// **'Strategy text is required.'**
  String get validStrategyRequired;

  /// Validation: strategy too long
  ///
  /// In en, this message translates to:
  /// **'Strategy must be at most {max} characters.'**
  String validStrategyTooLong(int max);

  /// Validation: strategy has inappropriate content
  ///
  /// In en, this message translates to:
  /// **'Strategy contains inappropriate content. Please revise.'**
  String get validStrategyInappropriate;

  /// Validation: race name empty
  ///
  /// In en, this message translates to:
  /// **'Race name is required.'**
  String get validRaceNameRequired;

  /// Validation: race name too short
  ///
  /// In en, this message translates to:
  /// **'Race name must be at least {min} characters.'**
  String validRaceNameTooShort(int min);

  /// Validation: race name too long
  ///
  /// In en, this message translates to:
  /// **'Race name must be at most {max} characters.'**
  String validRaceNameTooLong(int max);

  /// Validation: race name has invalid characters
  ///
  /// In en, this message translates to:
  /// **'Race name contains invalid characters.'**
  String get validRaceNameInvalidChars;

  /// Validation: race name has inappropriate content
  ///
  /// In en, this message translates to:
  /// **'Race name contains inappropriate content.'**
  String get validRaceNameInappropriate;

  /// Validation: email field empty
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get validEmailRequired;

  /// Validation: email format invalid
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get validEmailInvalid;

  /// Validation: password field empty
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get validPasswordRequired;

  /// Validation: password too short
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get validPasswordTooShort;

  /// Background music volume slider label
  ///
  /// In en, this message translates to:
  /// **'BGM Volume'**
  String get settingsBgmVolume;

  /// Sound effects volume slider label
  ///
  /// In en, this message translates to:
  /// **'SFX Volume'**
  String get settingsSfxVolume;

  /// AI model dropdown label at top
  ///
  /// In en, this message translates to:
  /// **'AI Model'**
  String get gameModeModelSelect;

  /// Ticket cost display with count
  ///
  /// In en, this message translates to:
  /// **'{cost} tickets'**
  String gameModeTicketInfo(int cost);

  /// Worldview selector label
  ///
  /// In en, this message translates to:
  /// **'World Setting'**
  String get gameModeWorldview;

  /// Worldview selector description
  ///
  /// In en, this message translates to:
  /// **'Choose the world setting for your battle'**
  String get gameModeWorldviewDesc;

  /// Admin panel title
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// Admin worldviews editor title
  ///
  /// In en, this message translates to:
  /// **'Worldviews'**
  String get adminWorldviews;

  /// Admin worldviews description
  ///
  /// In en, this message translates to:
  /// **'Edit world settings and AI judgment rules'**
  String get adminWorldviewsDesc;

  /// Admin scenarios editor title
  ///
  /// In en, this message translates to:
  /// **'Scenarios'**
  String get adminScenarios;

  /// Admin scenarios description
  ///
  /// In en, this message translates to:
  /// **'Edit battle scenarios and enemy commanders'**
  String get adminScenariosDesc;

  /// Admin mode addons editor title
  ///
  /// In en, this message translates to:
  /// **'Mode Instructions'**
  String get adminModeAddons;

  /// Admin mode addons description
  ///
  /// In en, this message translates to:
  /// **'Edit AI instructions for each game mode'**
  String get adminModeAddonsDesc;

  /// Admin costs editor title
  ///
  /// In en, this message translates to:
  /// **'Costs & Models'**
  String get adminCosts;

  /// Admin costs description
  ///
  /// In en, this message translates to:
  /// **'Edit ticket costs and AI model configuration'**
  String get adminCostsDesc;

  /// Admin save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get adminSave;

  /// Admin save success message
  ///
  /// In en, this message translates to:
  /// **'Configuration saved successfully'**
  String get adminSaveSuccess;

  /// Admin save error message
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String adminSaveError(String error);

  /// Admin add button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get adminAdd;

  /// Admin delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get adminDelete;

  /// Admin delete confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get adminDeleteConfirm;

  /// Admin field label: title
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get adminTitle;

  /// Admin field label: Japanese title
  ///
  /// In en, this message translates to:
  /// **'Title (JA)'**
  String get adminTitleJa;

  /// Admin field label: description
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adminDescription;

  /// Admin field label: Japanese description
  ///
  /// In en, this message translates to:
  /// **'Description (JA)'**
  String get adminDescriptionJa;

  /// Admin field label: common judgment
  ///
  /// In en, this message translates to:
  /// **'Judgment Rules'**
  String get adminCommonJudgment;

  /// Admin field label: commander definition
  ///
  /// In en, this message translates to:
  /// **'Commander Definition'**
  String get adminCommanderDef;

  /// Admin field label: enemy name
  ///
  /// In en, this message translates to:
  /// **'Enemy Name'**
  String get adminEnemyName;

  /// Admin field label: difficulty
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get adminDifficulty;

  /// Admin field label: battle type
  ///
  /// In en, this message translates to:
  /// **'Battle Type'**
  String get adminBattleType;

  /// Admin field label: key identifier
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get adminKey;

  /// Admin field label: value
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get adminValue;

  /// Admin add worldview dialog title
  ///
  /// In en, this message translates to:
  /// **'New Worldview'**
  String get adminNewWorldview;

  /// Admin add scenario dialog title
  ///
  /// In en, this message translates to:
  /// **'New Scenario'**
  String get adminNewScenario;

  /// World setting selection screen title
  ///
  /// In en, this message translates to:
  /// **'Choose World Setting'**
  String get worldSettingChoose;

  /// World setting selection subtitle
  ///
  /// In en, this message translates to:
  /// **'Select a world to define your battle rules and scenarios'**
  String get worldSettingSubtitle;

  /// Select world setting button
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get worldSettingSelect;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
