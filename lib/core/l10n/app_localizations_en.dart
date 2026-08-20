// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Steel Verdict';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get tickets => 'Tickets';

  @override
  String get splashInitializing => 'Initializing...';

  @override
  String get splashTagline => 'Write your strategy. Command the battle.';

  @override
  String get authTitle => 'Steel Verdict';

  @override
  String get authSubtitle => 'Enter the battlefield';

  @override
  String get authWelcomeTo => 'Welcome to';

  @override
  String get authAppName => 'STEEL\nVERDICT';

  @override
  String get authContinueJourney => 'Sign in to continue your journey';

  @override
  String get authGoogleSignIn => 'Continue with Google';

  @override
  String get authAppleSignIn => 'Continue with Apple';

  @override
  String get authComingSoon => 'Coming soon.';

  @override
  String get authOr => 'or';

  @override
  String get authSignUpEmail => 'Sign Up with Email';

  @override
  String get authLogIn => 'Log In';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authRegister => 'Register';

  @override
  String get authAnonymous => 'Play as Guest';

  @override
  String get authContinueGuest => 'Continue as Guest';

  @override
  String get authGuestWarning =>
      'Guest accounts may lose data if the app is uninstalled.';

  @override
  String get authCreateAccount => 'Create Account';

  @override
  String get authTerms =>
      'By continuing, you agree to our Terms & Privacy Policy';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authAnonymousWarning =>
      'Guest accounts may lose data. Link an email to secure your progress.';

  @override
  String get authLinkAccount => 'Link Email to Account';

  @override
  String get authLinkTitle => 'Link Account';

  @override
  String get authLinkSubtitle =>
      'Add an email and password to permanently secure your progress.';

  @override
  String get authEmailRequired => 'Email is required';

  @override
  String get authEmailInvalid => 'Enter a valid email';

  @override
  String get authPasswordRequired => 'Password is required';

  @override
  String get authPasswordMinLength => 'Password must be at least 6 characters';

  @override
  String get authLinkSuccess => 'Account linked successfully!';

  @override
  String get authGuestProgressWarning =>
      'Your progress may be lost if you uninstall the app. Link an email address to secure your data.';

  @override
  String get authLinkAccountArrow => 'Link Account →';

  @override
  String get homeWelcome => 'Welcome, Commander';

  @override
  String homeHello(String name) {
    return 'Hello, $name!';
  }

  @override
  String get homeGuestAccount => 'Guest Account';

  @override
  String get homeQuickActions => 'Quick Actions';

  @override
  String get homePlayGame => 'Play Game';

  @override
  String get homeDailyMissions => 'Daily Missions';

  @override
  String get homeReady => 'READY';

  @override
  String get homeDailyAlreadyClaimed => 'Daily reward already claimed.';

  @override
  String get homeDailySuccess => 'Daily reward claimed! +3 tickets';

  @override
  String get homeLeaderboard => 'Leaderboard';

  @override
  String get homeRecommended => 'Recommended';

  @override
  String get homeChallengeAI => 'Challenge AI';

  @override
  String get homeChallengeAISubtitle => 'Test your skills';

  @override
  String get homeMultiplayer => 'Multiplayer';

  @override
  String get homeMultiplayerSubtitle => 'Play with friends';

  @override
  String get homeWarHistorySubtitle => 'Review past battles';

  @override
  String get homeAdReward => 'Ad reward earned! +2 tickets';

  @override
  String get homeAdNotAvailable => 'Ad not available. Try again later.';

  @override
  String get homeLinkAccountBanner =>
      'Link your account to save data across devices';

  @override
  String get homeLosses => 'Losses';

  @override
  String get homeWins => 'Wins';

  @override
  String get homePlay => 'Play';

  @override
  String get homePvP => 'PvP Battle';

  @override
  String get homeWarHistory => 'War History';

  @override
  String get homeShop => 'Shop';

  @override
  String get homeDailyReward => 'Daily Reward';

  @override
  String get homeWatchAd => 'Watch Ad +2';

  @override
  String get dailyRewardAvailable => '+3 tickets available!';

  @override
  String get dailyRewardComeBack => 'Come back tomorrow';

  @override
  String get dailyClaim => 'CLAIM';

  @override
  String get watchAdTitle => 'Watch Ad';

  @override
  String get watchAdDesc => 'Earn +2 tickets by watching a short ad';

  @override
  String get watchAdBonus => '+2';

  @override
  String get raceCreationTitle => 'Create Your Race';

  @override
  String get raceCreationNameLabel => 'Race Name';

  @override
  String raceCreationPointsRemaining(int points) {
    return '$points points remaining';
  }

  @override
  String get raceCreationConfirm => 'Create Race';

  @override
  String raceCreationWorld(String world) {
    return 'World: $world';
  }

  @override
  String get raceAllocateStats => 'Allocate Stats';

  @override
  String get raceCreationSuccess => 'Race created! Let the wars begin.';

  @override
  String get raceNamePlaceholder => 'Enter your race name...';

  @override
  String get raceStatPoints => 'Stat Points';

  @override
  String get raceAllAllocated => 'All points allocated!';

  @override
  String get raceOverLimit => 'Over limit!';

  @override
  String get scenarioSelectionTitle => 'Choose Scenario';

  @override
  String get scenarioLocked => 'Locked';

  @override
  String get scenarioUnlock => 'Unlock';

  @override
  String scenarioDifficulty(String difficulty) {
    return 'Difficulty: $difficulty';
  }

  @override
  String get scenarioNoAvailable => 'No scenarios available';

  @override
  String get scenarioFree => 'FREE';

  @override
  String scenarioVsEnemy(String enemy) {
    return 'vs. $enemy';
  }

  @override
  String get unlockScenarioTitle => 'Unlock Scenario';

  @override
  String get unlockWatchAd => 'Watch Ad';

  @override
  String get unlockWatchAdDesc => 'Unlock by watching a short advertisement';

  @override
  String get unlockFree => 'FREE';

  @override
  String get unlockPurchase => 'Purchase';

  @override
  String get unlockPurchaseDesc => 'Permanently unlock this scenario';

  @override
  String get gameModeTitle => 'Choose Game Mode';

  @override
  String get gameModeChooseMode => 'Choose Mode';

  @override
  String get gameModeNormal => 'Normal';

  @override
  String get gameModeTabletop => 'Tabletop';

  @override
  String get gameModeEpic => 'Epic';

  @override
  String get gameModeBoss => 'Boss';

  @override
  String get gameModePractice => 'Practice';

  @override
  String get gameModePracticeDesc =>
      'Test your strategy for free. No report saved.';

  @override
  String get gameModeNormalDesc =>
      'Standard AI-judged battle with full report.';

  @override
  String get gameModeTabletopDesc =>
      'Enhanced tactical analysis with detailed breakdown.';

  @override
  String get gameModeEpicDesc => 'Full campaign-style narrative battle.';

  @override
  String get gameModeEpicRequires =>
      'Requires Commander subscription or higher';

  @override
  String get gameModeBossDesc => 'Face a legendary enemy. Extreme difficulty.';

  @override
  String get gameModeBossRequires => 'Requires special unlock';

  @override
  String get gameModeStartBattle => 'Start Battle';

  @override
  String get gameModeFree => 'FREE';

  @override
  String get gameModeLocked => 'Locked';

  @override
  String get gameModeAiModel => 'AI Model';

  @override
  String get gameModeAiModelDesc => 'Choose which AI judges your battle';

  @override
  String get battleTitle => 'Battle';

  @override
  String battleEnemyLabel(String enemy) {
    return 'Enemy: $enemy';
  }

  @override
  String battleModeLabel(String mode) {
    return 'Mode: $mode';
  }

  @override
  String get battleStrategyLabel => 'Your Strategy';

  @override
  String get battleStrategyHint => 'Describe your battle strategy in detail...';

  @override
  String get battleStrategyHintFull =>
      'e.g. Fight like Napoleon\n\nDescribe your battle strategy in detail...\n\nExamples:\n- Flank the enemy from the east\n- Use cavalry to disrupt supply lines\n- Deploy archers on the high ground';

  @override
  String battleNeedMoreChars(int count) {
    return 'Need $count more characters';
  }

  @override
  String get battleSubmit => 'Submit Strategy';

  @override
  String get battleLoadSaved => 'Load Saved Strategy';

  @override
  String get battleResultTitle => 'Battle Result';

  @override
  String get battleResultVictory => 'Victory!';

  @override
  String get battleResultDefeat => 'Defeat';

  @override
  String get battleResultDraw => 'Draw';

  @override
  String get battleVictoryFull => 'VICTORY!';

  @override
  String get battleDefeatFull => 'DEFEAT';

  @override
  String get battleDrawFull => 'DRAW';

  @override
  String get battleSaveToHistory => 'Save to History';

  @override
  String get battleNoReport => 'No report available.';

  @override
  String get battleReport => 'Battle Report';

  @override
  String get battlePlayAgain => 'Play Again';

  @override
  String get battleViewWarHistory => 'View War History';

  @override
  String get generalStaffTitle => 'General Staff';

  @override
  String get generalStaffAnalyzing => 'Analyzing your battle plan...';

  @override
  String get generalStaffMsg1 => 'Reviewing tactical situation...';

  @override
  String get generalStaffMsg2 => 'Analyzing terrain advantages...';

  @override
  String get generalStaffMsg3 => 'Assessing enemy formations...';

  @override
  String get generalStaffMsg4 => 'Calculating force ratios...';

  @override
  String get generalStaffMsg5 => 'Consulting strategic doctrine...';

  @override
  String get generalStaffMsg6 => 'Preparing battle assessment...';

  @override
  String get savedStrategiesTitle => 'Saved Strategies';

  @override
  String savedStrategiesCount(int count) {
    return '$count saved';
  }

  @override
  String get savedStrategiesEmpty => 'No saved strategies yet';

  @override
  String get pvpLobbyTitle => 'PvP Lobby';

  @override
  String get pvpSubtitle => 'Challenge another commander to battle!';

  @override
  String get pvpFindMatch => 'Find Match';

  @override
  String get pvpSearching => 'Searching...';

  @override
  String get pvpMatchCreated => 'Match created! Waiting for opponent...';

  @override
  String get pvpJoined => 'Joined a match!';

  @override
  String get pvpActiveMatches => 'Active Matches';

  @override
  String get pvpNoMatches => 'No active matches';

  @override
  String get pvpFindMatchHelp => 'Find a match to get started!';

  @override
  String pvpCountdown(String time) {
    return 'Time remaining: $time';
  }

  @override
  String get pvpBattleTitle => 'PvP Battle';

  @override
  String get pvpWaitingOpponent => 'Waiting for opponent to join...';

  @override
  String get pvpStrategySubmitted =>
      'Strategy submitted! Waiting for the battle to resolve...';

  @override
  String get pvpBattleResultLabel => 'Battle Result';

  @override
  String get pvpYouWon => 'You won!';

  @override
  String get pvpDraw => 'Draw!';

  @override
  String get pvpOpponentWon => 'Opponent won';

  @override
  String get pvpYourStrategy => 'Your Strategy';

  @override
  String get pvpStrategyHint => 'Describe your battle strategy...';

  @override
  String get pvpSubmitStrategy => 'Submit Strategy';

  @override
  String get pvpTimerExpired => 'EXPIRED';

  @override
  String get pvpWaitingForOpponent => 'Waiting for opponent...';

  @override
  String get pvpSubmitYourStrategy => 'Submit your strategy!';

  @override
  String get pvpOpponentStatsHidden => 'Opponent stats hidden';

  @override
  String get pvpVictory => 'Victory!';

  @override
  String get pvpDefeat => 'Defeat';

  @override
  String get pvpTimeout => 'Timed out';

  @override
  String get warHistoryTitle => 'War History';

  @override
  String get warHistorySoloBattles => 'Solo Battles';

  @override
  String get warHistoryFavorites => 'Favorites';

  @override
  String get warHistoryEmpty => 'No battles recorded yet';

  @override
  String get warHistoryEmptyMsg =>
      'No battles recorded yet.\nStart playing to build your history!';

  @override
  String warHistoryLoadError(String error) {
    return 'Failed to load history: $error';
  }

  @override
  String get warHistoryNoFavoritesMsg =>
      'No favorites yet.\nStar battles to save them here!';

  @override
  String get warHistoryGenerate => 'Generate Chronicle';

  @override
  String get warHistoryShare => 'Share to X';

  @override
  String get warHistorySharing => 'Sharing...';

  @override
  String get warHistoryBattleDetail => 'Battle Detail';

  @override
  String get warHistoryBattleNotFound => 'Battle record not found.';

  @override
  String get warHistoryBattleReport => 'Battle Report';

  @override
  String get warHistoryWarChronicle => 'War Chronicle';

  @override
  String get warHistoryGenerateDesc =>
      'Generate a detailed war chronicle from this battle';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsEdit => 'Edit';

  @override
  String get settingsComingSoon => 'Coming soon.';

  @override
  String get settingsChangePassword => 'Change Password';

  @override
  String get settingsLinkAccountFirst => 'Link an account first.';

  @override
  String get settingsLinkedAccounts => 'Linked Accounts';

  @override
  String get settingsGuestAccount => 'Guest Account';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsSoundMusic => 'Sound & Music';

  @override
  String get settingsSupport => 'Support';

  @override
  String get settingsHelpCenter => 'Help Center';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsSubscription => 'Subscription';

  @override
  String get settingsClearData => 'Clear All Data';

  @override
  String get settingsClearDataConfirm =>
      'This will permanently delete all local data. Cannot be undone.';

  @override
  String get settingsAllDataCleared => 'All data cleared.';

  @override
  String get settingsRace => 'Race';

  @override
  String get settingsViewRace => 'My Race';

  @override
  String get settingsViewRaceNoRace => 'No race created yet.';

  @override
  String get settingsChangeRace => 'Change Race';

  @override
  String get settingsChangeRaceConfirm =>
      'Your current race will be deleted and you will create a new one. This cannot be undone.';

  @override
  String get settingsSignOut => 'Sign Out';

  @override
  String get settingsSignOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsVersion => 'Steel Verdict v1.0.0';

  @override
  String get settingsSelectLanguage => 'Select Language';

  @override
  String get settingsPersonalInfo => 'Personal Info';

  @override
  String get settingsLinkAccount => 'Link Account';

  @override
  String get settingsCurrentPlan => 'Current Plan';

  @override
  String get settingsUpgrade => 'Upgrade';

  @override
  String get settingsLanguageChanged => 'Language changed!';

  @override
  String get settingsLangEnglish => 'English';

  @override
  String get settingsLangJapanese => '日本語';

  @override
  String get shopTitle => 'Shop';

  @override
  String get shopSubscriptions => 'Subscriptions';

  @override
  String get shopTickets => 'Tickets';

  @override
  String get shopRestore => 'Restore Purchases';

  @override
  String get shopRestoreShort => 'Restore';

  @override
  String get shopUnlockMore => 'Unlock more tickets and features';

  @override
  String get shopTicketPacks => 'TICKET PACKS';

  @override
  String get shopOneTimePurchases => 'One-time ticket purchases';

  @override
  String get shopSmallPack => 'Small Pack';

  @override
  String get shopSmallPackDesc => '10 battle tickets';

  @override
  String get shopLargePack => 'Large Pack';

  @override
  String get shopLargePackDesc => '30 battle tickets — Best value!';

  @override
  String get shopScenarioPacks => 'SCENARIO PACKS';

  @override
  String get shopScenarioPacksDesc => 'Additional battle scenarios';

  @override
  String get shopAncientBattles => 'Ancient Battles Pack';

  @override
  String get shopAncientBattlesDesc => 'Unlock 5 historical scenarios';

  @override
  String get shopAutoRenew =>
      'Subscriptions auto-renew unless cancelled. Prices vary by region.';

  @override
  String get shopMostPopular => 'MOST POPULAR';

  @override
  String get shopSubscribe => 'Subscribe';

  @override
  String get subscriptionFree => 'Free';

  @override
  String get subscriptionCommander => 'Commander';

  @override
  String get subscriptionGeneral => 'General';

  @override
  String get subscriptionWarlord => 'Warlord';

  @override
  String get gameHubTitle => 'Game';

  @override
  String get gameHubChooseMode => 'Choose Game Mode';

  @override
  String get gameHubSelectHow => 'Select how you want to battle';

  @override
  String get gameHubSinglePlayer => 'Single Player';

  @override
  String get gameHubPlayVsAI => 'Play vs AI';

  @override
  String get gameHubSinglePlayerDesc =>
      'Choose a scenario and challenge historical commanders. Test your strategy against AI-judged battles.';

  @override
  String get gameHubVsAI => 'VS AI';

  @override
  String get gameHubMultiplayer => 'Multiplayer';

  @override
  String get gameHubPlayOnline => 'Play online with friends';

  @override
  String get gameHubMultiplayerDesc =>
      'Compete against real players. Submit your strategy within 24 hours and let AI judge the outcome.';

  @override
  String get gameHubLive => 'LIVE';

  @override
  String get gameHubManagement => 'Management';

  @override
  String get gameHubWarHistoryDesc => 'View your past battles';

  @override
  String get gameHubShopDesc => 'Get tickets & subscriptions';

  @override
  String get difficultyNovice => 'Novice';

  @override
  String get difficultySoldier => 'Soldier';

  @override
  String get difficultyCaptain => 'Captain';

  @override
  String get difficultyGeneral => 'General';

  @override
  String get difficultyWarlord => 'Warlord';

  @override
  String get difficultyUnknown => 'Unknown';

  @override
  String get pvpStatusWaiting => 'Waiting';

  @override
  String get pvpStatusActive => 'Active';

  @override
  String get pvpStatusResolved => 'Resolved';

  @override
  String get pvpStatusTimedOut => 'Timed Out';

  @override
  String get pvpLoadingMatch => 'Loading match...';

  @override
  String get pvpOpponent => 'Opponent';

  @override
  String get pvpStatusPrefix => 'Status';

  @override
  String get pvpMatchPrefix => 'Match';

  @override
  String get warChronicleGenerated => 'Chronicle generated!';

  @override
  String get sharedToX => 'Shared to X!';

  @override
  String get sharedToXWithImage => 'Shared to X with image!';

  @override
  String get parchmentFooter => 'Steel Verdict Chronicle';

  @override
  String get anonymousCommander => 'Anonymous Commander';

  @override
  String get battleSavedToHistory => 'Battle saved to history!';

  @override
  String get favoritesAdded => 'Added to favorites!';

  @override
  String get favoritesRemoved => 'Removed from favorites';

  @override
  String get subscriptionCommanderPrice => 'Commander (¥500)';

  @override
  String get subscriptionGeneralPrice => 'General (¥1,000)';

  @override
  String get subscriptionWarlordPrice => 'Warlord (¥3,000)';

  @override
  String shopTicketsPerDay(int count) {
    return '$count tickets/day';
  }

  @override
  String get shopFeature10Tickets => '10 daily tickets';

  @override
  String get shopFeatureBasicScenarios => 'All basic scenarios';

  @override
  String get shopFeatureSave20Strategies => 'Save up to 20 strategies';

  @override
  String get shopFeaturePriorityQueue => 'Priority battle queue';

  @override
  String get shopFeature20Tickets => '20 daily tickets';

  @override
  String get shopFeatureEpicMode => 'Epic mode unlocked';

  @override
  String get shopFeatureUnlimitedHistory => 'Unlimited war history';

  @override
  String get shopFeatureSave50Strategies => 'Save up to 50 strategies';

  @override
  String get shopFeatureAllCommanderFeatures => 'All Commander features';

  @override
  String get shopFeature50Tickets => '50 daily tickets';

  @override
  String get shopFeatureAllModes => 'All modes unlocked';

  @override
  String get shopFeatureBossBattles => 'Boss battles enabled';

  @override
  String get shopFeatureUnlimitedAll => 'Unlimited everything';

  @override
  String get shopFeatureAllGeneralFeatures => 'All General features';

  @override
  String get splashTitleLine1 => 'STEEL';

  @override
  String get splashTitleLine2 => 'VERDICT';

  @override
  String get navHome => 'Home';

  @override
  String get navGame => 'Game';

  @override
  String get navMissions => 'Missions';

  @override
  String get navProfile => 'Profile';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get shopPurchaseInitiated => 'Purchase initiated!';

  @override
  String get shopPurchasesRestored => 'Purchases restored!';

  @override
  String get shopPurchaseFailed => 'Purchase failed';

  @override
  String get shopRestoreFailed => 'Restore failed';

  @override
  String get statAttack => 'Attack';

  @override
  String get statDefense => 'Defense';

  @override
  String get statSpeed => 'Speed';

  @override
  String get statMorale => 'Morale';

  @override
  String get statMagic => 'Magic';

  @override
  String get statLeadership => 'Leadership';

  @override
  String get statStrength => 'Strength';

  @override
  String get statIntellect => 'Intellect';

  @override
  String get statSkill => 'Skill';

  @override
  String get statArt => 'Art';

  @override
  String get statLife => 'Life';

  @override
  String get raceOverviewLabel => 'Race Overview';

  @override
  String get raceOverviewHint =>
      'Brief description of your race\'s background, culture, or fighting style...';

  @override
  String get authErrNoAccount => 'No account found with this email.';

  @override
  String get authErrWrongPassword => 'Incorrect password.';

  @override
  String get authErrEmailInUse => 'This email is already in use.';

  @override
  String get authErrWeakPassword =>
      'Password is too weak. Use at least 6 characters.';

  @override
  String get authErrInvalidEmail => 'Invalid email address.';

  @override
  String get authErrCredentialInUse =>
      'This credential is already linked to another account.';

  @override
  String get authErrDefault => 'Authentication failed.';

  @override
  String get authErrSignInFailed => 'Failed to sign in.';

  @override
  String get authErrSignOutFailed => 'Sign out failed.';

  @override
  String get battleSaveStrategy => 'Save Strategy';

  @override
  String get battleSaveStrategyDialogTitle => 'Save Strategy';

  @override
  String get battleSaveStrategyNameHint => 'Give your strategy a name...';

  @override
  String get battleSaveStrategySuccess => 'Strategy saved!';

  @override
  String get battleSaveStrategyLimitReached =>
      'Save limit reached. Upgrade your plan to save more strategies.';

  @override
  String get xShareRewardEarned => '+1 ticket earned for sharing to X!';

  @override
  String get xShareRewardAlreadyClaimed =>
      'X share reward already claimed today.';

  @override
  String get gameModeHistoryPuzzle => 'Historical Puzzle';

  @override
  String get gameModeHistoryPuzzleDesc =>
      'Fixed historical forces. No clear stage — beat your personal best!';

  @override
  String get personalBest => 'Personal Best';

  @override
  String personalBestScore(int wins, int total) {
    return '$wins wins / $total attempts';
  }

  @override
  String get personalBestNone => 'No record yet';

  @override
  String get skipAdCost => 'Skip (-1 ticket)';

  @override
  String get watchAdFree => 'Watch Ad (Free)';

  @override
  String get skipAdSuccess => 'Ad skipped. -1 ticket.';

  @override
  String get skipAdNoTickets => 'Not enough tickets to skip.';

  @override
  String get practiceAdPrompt => 'An ad is ready. Watch it for free or skip.';

  @override
  String get contentFilterBlocked =>
      'Your text contains inappropriate content. Please revise.';

  @override
  String get battleFailedRetry => 'Battle failed. Please try again.';

  @override
  String get battleSignInRequired => 'Please sign in to continue.';

  @override
  String get deleteConfirmWord => 'DELETE';

  @override
  String get deleteConfirmHint => 'Type DELETE to confirm';

  @override
  String get homeNoRaceBanner => 'Create your race to begin';

  @override
  String get homeNoRaceBannerSub =>
      'Tap Play to set up your race and enter battle';

  @override
  String get homeWorldSetting => 'World Setting';

  @override
  String get homeWorldSettingChange => 'Change';

  @override
  String get homeWorldSettingNone => 'Select World';

  @override
  String get battleTypeTitle => 'Battle Type';

  @override
  String get battleTypeChoose => 'Choose Battle Type';

  @override
  String get battleTypeSubtitle =>
      'Select the type of battle you want to fight';

  @override
  String get battleTypeStandard => 'Standard Battle';

  @override
  String get battleTypeStandardDesc =>
      'Choose a scenario and challenge historical commanders with multiple sub-modes.';

  @override
  String get battleTypeSubModeBadge => '4 MODES';

  @override
  String get battleTypeBoss => 'Boss Battle';

  @override
  String get battleTypeBossDesc =>
      'Face a legendary enemy in an extreme difficulty encounter.';

  @override
  String get battleTypeBossBadge => 'BOSS';

  @override
  String get battleTypeHistory => 'History Puzzle';

  @override
  String get battleTypeHistoryDesc =>
      'Fixed historical forces with no clear stage. Beat your personal best!';

  @override
  String get battleTypeHistoryBadge => 'PUZZLE';

  @override
  String get pvpOpponentSubmittedUrge =>
      'Opponent submitted — submit your strategy now!';

  @override
  String get pvpBothSubmittedResolving =>
      'Both submitted — battle resolving...';

  @override
  String get gameHubMyRace => 'My Race';

  @override
  String get gameHubMyRaceDesc => 'View your race stats and traits';

  @override
  String get myRaceNoRace => 'No race created yet. Tap Play to create one.';

  @override
  String get myRaceStats => 'Stats';

  @override
  String get myRaceOverview => 'Overview';

  @override
  String get validStrategyRequired => 'Strategy text is required.';

  @override
  String validStrategyTooLong(int max) {
    return 'Strategy must be at most $max characters.';
  }

  @override
  String get validStrategyInappropriate =>
      'Strategy contains inappropriate content. Please revise.';

  @override
  String get validRaceNameRequired => 'Race name is required.';

  @override
  String validRaceNameTooShort(int min) {
    return 'Race name must be at least $min characters.';
  }

  @override
  String validRaceNameTooLong(int max) {
    return 'Race name must be at most $max characters.';
  }

  @override
  String get validRaceNameInvalidChars =>
      'Race name contains invalid characters.';

  @override
  String get validRaceNameInappropriate =>
      'Race name contains inappropriate content.';

  @override
  String get validEmailRequired => 'Email is required.';

  @override
  String get validEmailInvalid => 'Enter a valid email address.';

  @override
  String get validPasswordRequired => 'Password is required.';

  @override
  String get validPasswordTooShort => 'Password must be at least 6 characters.';

  @override
  String get settingsBgmVolume => 'BGM Volume';

  @override
  String get settingsSfxVolume => 'SFX Volume';

  @override
  String get gameModeModelSelect => 'AI Model';

  @override
  String gameModeTicketInfo(int cost) {
    return '$cost tickets';
  }

  @override
  String get gameModeWorldview => 'World Setting';

  @override
  String get gameModeWorldviewDesc =>
      'Choose the world setting for your battle';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get adminWorldviews => 'Worldviews';

  @override
  String get adminWorldviewsDesc => 'Edit world settings and AI judgment rules';

  @override
  String get adminScenarios => 'Scenarios';

  @override
  String get adminScenariosDesc => 'Edit battle scenarios and enemy commanders';

  @override
  String get adminModeAddons => 'Mode Instructions';

  @override
  String get adminModeAddonsDesc => 'Edit AI instructions for each game mode';

  @override
  String get adminCosts => 'Costs & Models';

  @override
  String get adminCostsDesc => 'Edit ticket costs and AI model configuration';

  @override
  String get adminSave => 'Save';

  @override
  String get adminSaveSuccess => 'Configuration saved successfully';

  @override
  String adminSaveError(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get adminAdd => 'Add';

  @override
  String get adminDelete => 'Delete';

  @override
  String get adminDeleteConfirm => 'Are you sure you want to delete this item?';

  @override
  String get adminTitle => 'Title';

  @override
  String get adminTitleJa => 'Title (JA)';

  @override
  String get adminDescription => 'Description';

  @override
  String get adminDescriptionJa => 'Description (JA)';

  @override
  String get adminCommonJudgment => 'Judgment Rules';

  @override
  String get adminCommanderDef => 'Commander Definition';

  @override
  String get adminEnemyName => 'Enemy Name';

  @override
  String get adminDifficulty => 'Difficulty';

  @override
  String get adminBattleType => 'Battle Type';

  @override
  String get adminKey => 'Key';

  @override
  String get adminValue => 'Value';

  @override
  String get adminNewWorldview => 'New Worldview';

  @override
  String get adminNewScenario => 'New Scenario';

  @override
  String get worldSettingChoose => 'Choose World Setting';

  @override
  String get worldSettingSubtitle =>
      'Select a world to define your battle rules and scenarios';

  @override
  String get worldSettingSelect => 'Select';
}
