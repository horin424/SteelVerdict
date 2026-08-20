// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'スティールバーディクト';

  @override
  String get loading => '読み込み中...';

  @override
  String get error => 'エラー';

  @override
  String get retry => '再試行';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get close => '閉じる';

  @override
  String get back => '戻る';

  @override
  String get next => '次へ';

  @override
  String get tickets => 'チケット';

  @override
  String get splashInitializing => '初期化中...';

  @override
  String get splashTagline => '戦略を書け。戦場を制せ。';

  @override
  String get authTitle => 'スティールバーディクト';

  @override
  String get authSubtitle => '戦場へ';

  @override
  String get authWelcomeTo => 'ようこそ';

  @override
  String get authAppName => 'スティール\nバーディクト';

  @override
  String get authContinueJourney => '旅を続けるにはサインイン';

  @override
  String get authGoogleSignIn => 'Googleで続ける';

  @override
  String get authAppleSignIn => 'Appleで続ける';

  @override
  String get authComingSoon => '近日公開。';

  @override
  String get authOr => 'または';

  @override
  String get authSignUpEmail => 'メールで登録';

  @override
  String get authLogIn => 'ログイン';

  @override
  String get authSignIn => 'ログイン';

  @override
  String get authRegister => '登録';

  @override
  String get authAnonymous => 'ゲストとしてプレイ';

  @override
  String get authContinueGuest => 'ゲストとして続ける';

  @override
  String get authGuestWarning => 'ゲストアカウントはアプリをアンインストールするとデータが失われる可能性があります。';

  @override
  String get authCreateAccount => 'アカウント作成';

  @override
  String get authTerms => '続けることで利用規約とプライバシーポリシーに同意します';

  @override
  String get authEmail => 'メールアドレス';

  @override
  String get authPassword => 'パスワード';

  @override
  String get authAnonymousWarning =>
      'ゲストアカウントはデータが失われる可能性があります。メールを登録して進捗を保護してください。';

  @override
  String get authLinkAccount => 'メールアドレスを連携';

  @override
  String get authLinkTitle => 'アカウント連携';

  @override
  String get authLinkSubtitle => 'メールとパスワードを追加して進捗を永久に保護してください。';

  @override
  String get authEmailRequired => 'メールアドレスは必須です';

  @override
  String get authEmailInvalid => '有効なメールアドレスを入力してください';

  @override
  String get authPasswordRequired => 'パスワードは必須です';

  @override
  String get authPasswordMinLength => 'パスワードは6文字以上必要です';

  @override
  String get authLinkSuccess => 'アカウントの連携に成功しました！';

  @override
  String get authGuestProgressWarning =>
      'アプリをアンインストールすると進捗が失われる可能性があります。メールアドレスを連携してデータを保護してください。';

  @override
  String get authLinkAccountArrow => 'アカウント連携 →';

  @override
  String get homeWelcome => 'ようこそ、司令官';

  @override
  String homeHello(String name) {
    return 'こんにちは、$name！';
  }

  @override
  String get homeGuestAccount => 'ゲストアカウント';

  @override
  String get homeQuickActions => 'クイックアクション';

  @override
  String get homePlayGame => 'ゲームをプレイ';

  @override
  String get homeDailyMissions => 'デイリーミッション';

  @override
  String get homeReady => '受取可';

  @override
  String get homeDailyAlreadyClaimed => 'デイリー報酬は既に受け取り済みです。';

  @override
  String get homeDailySuccess => 'デイリー報酬を受け取りました！+3チケット';

  @override
  String get homeLeaderboard => 'リーダーボード';

  @override
  String get homeRecommended => 'おすすめ';

  @override
  String get homeChallengeAI => 'AIに挑戦';

  @override
  String get homeChallengeAISubtitle => 'スキルをテスト';

  @override
  String get homeMultiplayer => 'マルチプレイヤー';

  @override
  String get homeMultiplayerSubtitle => '友達と遊ぶ';

  @override
  String get homeWarHistorySubtitle => '過去のバトルを確認';

  @override
  String get homeAdReward => '広告報酬を獲得！+2チケット';

  @override
  String get homeAdNotAvailable => '広告が利用できません。後でもう一度お試しください。';

  @override
  String get homeLinkAccountBanner => 'アカウントを連携してデバイス間でデータを同期';

  @override
  String get homeLosses => '敗北';

  @override
  String get homeWins => '勝利';

  @override
  String get homePlay => 'プレイ';

  @override
  String get homePvP => 'PvP対戦';

  @override
  String get homeWarHistory => '戦史';

  @override
  String get homeShop => 'ショップ';

  @override
  String get homeDailyReward => 'デイリー報酬';

  @override
  String get homeWatchAd => '広告を見て+2';

  @override
  String get dailyRewardAvailable => '+3チケット受け取れます！';

  @override
  String get dailyRewardComeBack => '明日また来てね';

  @override
  String get dailyClaim => '受け取る';

  @override
  String get watchAdTitle => '広告を見る';

  @override
  String get watchAdDesc => '短い広告を見て+2チケット獲得';

  @override
  String get watchAdBonus => '+2';

  @override
  String get raceCreationTitle => '種族を作成';

  @override
  String get raceCreationNameLabel => '種族名';

  @override
  String raceCreationPointsRemaining(int points) {
    return '残りポイント: $points';
  }

  @override
  String get raceCreationConfirm => '種族を作成';

  @override
  String raceCreationWorld(String world) {
    return 'ワールド: $world';
  }

  @override
  String get raceAllocateStats => 'ステータス配分';

  @override
  String get raceCreationSuccess => '種族を作成しました！戦争を始めよう。';

  @override
  String get raceNamePlaceholder => '種族名を入力...';

  @override
  String get raceStatPoints => 'ステータスポイント';

  @override
  String get raceAllAllocated => '全ポイント配分済み！';

  @override
  String get raceOverLimit => '上限超過！';

  @override
  String get scenarioSelectionTitle => 'シナリオを選択';

  @override
  String get scenarioLocked => 'ロック中';

  @override
  String get scenarioUnlock => '解放する';

  @override
  String scenarioDifficulty(String difficulty) {
    return '難易度: $difficulty';
  }

  @override
  String get scenarioNoAvailable => 'シナリオがありません';

  @override
  String get scenarioFree => '無料';

  @override
  String scenarioVsEnemy(String enemy) {
    return '対: $enemy';
  }

  @override
  String get unlockScenarioTitle => 'シナリオを解放';

  @override
  String get unlockWatchAd => '広告を見る';

  @override
  String get unlockWatchAdDesc => '短い広告を見てアンロック';

  @override
  String get unlockFree => '無料';

  @override
  String get unlockPurchase => '購入';

  @override
  String get unlockPurchaseDesc => 'このシナリオを永久に解放';

  @override
  String get gameModeTitle => 'ゲームモードを選択';

  @override
  String get gameModeChooseMode => 'モードを選択';

  @override
  String get gameModeNormal => 'ノーマル';

  @override
  String get gameModeTabletop => 'テーブルトップ';

  @override
  String get gameModeEpic => 'エピック';

  @override
  String get gameModeBoss => 'ボス';

  @override
  String get gameModePractice => '練習';

  @override
  String get gameModePracticeDesc => '無料で戦略をテスト。レポートは保存されません。';

  @override
  String get gameModeNormalDesc => 'AI審判による標準バトル（フルレポート）。';

  @override
  String get gameModeTabletopDesc => '詳細分析付きの高度な戦術分析。';

  @override
  String get gameModeEpicDesc => 'キャンペーン形式のナラティブバトル。';

  @override
  String get gameModeEpicRequires => '司令官サブスクリプション以上が必要';

  @override
  String get gameModeBossDesc => '伝説の敵と戦う。超高難易度。';

  @override
  String get gameModeBossRequires => '特別なアンロックが必要';

  @override
  String get gameModeStartBattle => '戦闘開始';

  @override
  String get gameModeFree => '無料';

  @override
  String get gameModeLocked => 'ロック中';

  @override
  String get gameModeAiModel => 'AIモデル';

  @override
  String get gameModeAiModelDesc => 'バトルを審判するAIを選択';

  @override
  String get battleTitle => '戦闘';

  @override
  String battleEnemyLabel(String enemy) {
    return '敵: $enemy';
  }

  @override
  String battleModeLabel(String mode) {
    return 'モード: $mode';
  }

  @override
  String get battleStrategyLabel => 'あなたの戦略';

  @override
  String get battleStrategyHint => '戦闘戦略を詳しく記述してください...';

  @override
  String get battleStrategyHintFull =>
      '例: ナポレオンのように戦え\n\n戦闘戦略を詳しく記述してください...\n\n例:\n- 東から敵の側面を攻撃\n- 騎兵で補給線を妨害\n- 高地に弓兵を配置';

  @override
  String battleNeedMoreChars(int count) {
    return 'あと$count文字必要';
  }

  @override
  String get battleSubmit => '戦略を提出';

  @override
  String get battleLoadSaved => '保存した戦略を読込';

  @override
  String get battleResultTitle => '戦闘結果';

  @override
  String get battleResultVictory => '勝利！';

  @override
  String get battleResultDefeat => '敗北';

  @override
  String get battleResultDraw => '引き分け';

  @override
  String get battleVictoryFull => '勝利！';

  @override
  String get battleDefeatFull => '敗北';

  @override
  String get battleDrawFull => '引き分け';

  @override
  String get battleSaveToHistory => '戦史に保存';

  @override
  String get battleNoReport => 'レポートがありません。';

  @override
  String get battleReport => '戦闘レポート';

  @override
  String get battlePlayAgain => 'もう一度プレイ';

  @override
  String get battleViewWarHistory => '戦史を見る';

  @override
  String get generalStaffTitle => '参謀本部';

  @override
  String get generalStaffAnalyzing => '作戦を分析中...';

  @override
  String get generalStaffMsg1 => '戦術状況を確認中...';

  @override
  String get generalStaffMsg2 => '地形優位を分析中...';

  @override
  String get generalStaffMsg3 => '敵の陣形を評価中...';

  @override
  String get generalStaffMsg4 => '兵力比を計算中...';

  @override
  String get generalStaffMsg5 => '戦略的ドクトリンを参照中...';

  @override
  String get generalStaffMsg6 => '戦闘評価を準備中...';

  @override
  String get savedStrategiesTitle => '保存した戦略';

  @override
  String savedStrategiesCount(int count) {
    return '$count件保存';
  }

  @override
  String get savedStrategiesEmpty => '保存した戦略はまだありません';

  @override
  String get pvpLobbyTitle => 'PvPロビー';

  @override
  String get pvpSubtitle => '別の司令官にバトルを挑もう！';

  @override
  String get pvpFindMatch => '対戦相手を探す';

  @override
  String get pvpSearching => '検索中...';

  @override
  String get pvpMatchCreated => 'マッチ作成！対戦相手を待っています...';

  @override
  String get pvpJoined => 'マッチに参加しました！';

  @override
  String get pvpActiveMatches => '進行中の対戦';

  @override
  String get pvpNoMatches => '進行中の対戦はありません';

  @override
  String get pvpFindMatchHelp => 'マッチを探して始めましょう！';

  @override
  String pvpCountdown(String time) {
    return '残り時間: $time';
  }

  @override
  String get pvpBattleTitle => 'PvPバトル';

  @override
  String get pvpWaitingOpponent => '対戦相手の参加を待っています...';

  @override
  String get pvpStrategySubmitted => '戦略を提出しました！バトルの結果を待っています...';

  @override
  String get pvpBattleResultLabel => 'バトル結果';

  @override
  String get pvpYouWon => 'あなたの勝利！';

  @override
  String get pvpDraw => '引き分け！';

  @override
  String get pvpOpponentWon => '対戦相手の勝利';

  @override
  String get pvpYourStrategy => 'あなたの戦略';

  @override
  String get pvpStrategyHint => '戦闘戦略を記述...';

  @override
  String get pvpSubmitStrategy => '戦略を提出';

  @override
  String get pvpTimerExpired => '期限切れ';

  @override
  String get pvpWaitingForOpponent => '対戦相手を待っています...';

  @override
  String get pvpSubmitYourStrategy => '戦略を提出してください！';

  @override
  String get pvpOpponentStatsHidden => '対戦相手の情報は非表示';

  @override
  String get pvpVictory => '勝利！';

  @override
  String get pvpDefeat => '敗北';

  @override
  String get pvpTimeout => 'タイムアウト';

  @override
  String get warHistoryTitle => '戦史';

  @override
  String get warHistorySoloBattles => 'ソロバトル';

  @override
  String get warHistoryFavorites => 'お気に入り';

  @override
  String get warHistoryEmpty => 'まだ戦闘記録がありません';

  @override
  String get warHistoryEmptyMsg => 'まだ戦闘記録がありません。\nプレイして戦史を作ろう！';

  @override
  String warHistoryLoadError(String error) {
    return '履歴の読み込み失敗: $error';
  }

  @override
  String get warHistoryNoFavoritesMsg => 'まだお気に入りがありません。\n星を付けて保存しましょう！';

  @override
  String get warHistoryGenerate => '戦記を生成';

  @override
  String get warHistoryShare => 'Xでシェア';

  @override
  String get warHistorySharing => '共有中...';

  @override
  String get warHistoryBattleDetail => 'バトル詳細';

  @override
  String get warHistoryBattleNotFound => 'バトル記録が見つかりません。';

  @override
  String get warHistoryBattleReport => 'バトルレポート';

  @override
  String get warHistoryWarChronicle => '戦記';

  @override
  String get warHistoryGenerateDesc => 'このバトルから詳細な戦記を生成';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsProfile => 'プロフィール';

  @override
  String get settingsEdit => '編集';

  @override
  String get settingsComingSoon => '近日公開。';

  @override
  String get settingsChangePassword => 'パスワード変更';

  @override
  String get settingsLinkAccountFirst => 'まずアカウントを連携してください。';

  @override
  String get settingsLinkedAccounts => '連携アカウント';

  @override
  String get settingsGuestAccount => 'ゲストアカウント';

  @override
  String get settingsAccount => 'アカウント';

  @override
  String get settingsPreferences => '設定';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsSoundMusic => 'サウンド＆ミュージック';

  @override
  String get settingsSupport => 'サポート';

  @override
  String get settingsHelpCenter => 'ヘルプセンター';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsSubscription => 'サブスクリプション';

  @override
  String get settingsClearData => '全データを削除';

  @override
  String get settingsClearDataConfirm => '全てのローカルデータを完全に削除します。元に戻せません。';

  @override
  String get settingsAllDataCleared => '全データを削除しました。';

  @override
  String get settingsRace => '種族';

  @override
  String get settingsViewRace => 'マイ種族';

  @override
  String get settingsViewRaceNoRace => 'まだ種族が作成されていません。';

  @override
  String get settingsChangeRace => '種族を変更する';

  @override
  String get settingsChangeRaceConfirm =>
      '現在の種族が削除され、新しい種族を作成します。この操作は元に戻せません。';

  @override
  String get settingsSignOut => 'ログアウト';

  @override
  String get settingsSignOutConfirm => '本当にサインアウトしますか？';

  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get settingsVersion => '鋼鉄の裁き v1.0.0';

  @override
  String get settingsSelectLanguage => '言語を選択';

  @override
  String get settingsPersonalInfo => '個人情報';

  @override
  String get settingsLinkAccount => 'アカウント連携';

  @override
  String get settingsCurrentPlan => '現在のプラン';

  @override
  String get settingsUpgrade => 'アップグレード';

  @override
  String get settingsLanguageChanged => '言語を変更しました！';

  @override
  String get settingsLangEnglish => 'English';

  @override
  String get settingsLangJapanese => '日本語';

  @override
  String get shopTitle => 'ショップ';

  @override
  String get shopSubscriptions => 'サブスクリプション';

  @override
  String get shopTickets => 'チケット';

  @override
  String get shopRestore => '購入を復元';

  @override
  String get shopRestoreShort => '復元';

  @override
  String get shopUnlockMore => 'チケットと機能を解放';

  @override
  String get shopTicketPacks => 'チケットパック';

  @override
  String get shopOneTimePurchases => '1回限りの購入';

  @override
  String get shopSmallPack => 'スモールパック';

  @override
  String get shopSmallPackDesc => '10バトルチケット';

  @override
  String get shopLargePack => 'ラージパック';

  @override
  String get shopLargePackDesc => '30バトルチケット — お得！';

  @override
  String get shopScenarioPacks => 'シナリオパック';

  @override
  String get shopScenarioPacksDesc => '追加バトルシナリオ';

  @override
  String get shopAncientBattles => '古代バトルパック';

  @override
  String get shopAncientBattlesDesc => '歴史的シナリオ5つを解放';

  @override
  String get shopAutoRenew => 'サブスクリプションはキャンセルしない限り自動更新されます。価格は地域によって異なります。';

  @override
  String get shopMostPopular => '人気No.1';

  @override
  String get shopSubscribe => '登録する';

  @override
  String get subscriptionFree => '無料';

  @override
  String get subscriptionCommander => '司令官';

  @override
  String get subscriptionGeneral => '将軍';

  @override
  String get subscriptionWarlord => '覇王';

  @override
  String get gameHubTitle => 'ゲーム';

  @override
  String get gameHubChooseMode => 'ゲームモードを選択';

  @override
  String get gameHubSelectHow => '戦い方を選んでください';

  @override
  String get gameHubSinglePlayer => 'シングルプレイヤー';

  @override
  String get gameHubPlayVsAI => 'AIと対戦';

  @override
  String get gameHubSinglePlayerDesc => 'シナリオを選んで歴史上の指揮官に挑戦。AI審判のバトルで戦略をテスト。';

  @override
  String get gameHubVsAI => 'VS AI';

  @override
  String get gameHubMultiplayer => 'マルチプレイヤー';

  @override
  String get gameHubPlayOnline => '友達とオンラインプレイ';

  @override
  String get gameHubMultiplayerDesc => '実際のプレイヤーと競い合う。24時間以内に戦略を提出してAIに審判させよう。';

  @override
  String get gameHubLive => 'ライブ';

  @override
  String get gameHubManagement => '管理';

  @override
  String get gameHubWarHistoryDesc => '過去のバトルを見る';

  @override
  String get gameHubShopDesc => 'チケットとサブスクリプション';

  @override
  String get difficultyNovice => '初心者';

  @override
  String get difficultySoldier => '兵士';

  @override
  String get difficultyCaptain => '大尉';

  @override
  String get difficultyGeneral => '将軍';

  @override
  String get difficultyWarlord => '覇王';

  @override
  String get difficultyUnknown => '不明';

  @override
  String get pvpStatusWaiting => '待機中';

  @override
  String get pvpStatusActive => '進行中';

  @override
  String get pvpStatusResolved => '解決済み';

  @override
  String get pvpStatusTimedOut => 'タイムアウト';

  @override
  String get pvpLoadingMatch => 'マッチ読み込み中...';

  @override
  String get pvpOpponent => '対戦相手';

  @override
  String get pvpStatusPrefix => 'ステータス';

  @override
  String get pvpMatchPrefix => 'マッチ';

  @override
  String get warChronicleGenerated => '戦記を生成しました！';

  @override
  String get sharedToX => 'Xにシェアしました！';

  @override
  String get sharedToXWithImage => '画像付きでXにシェアしました！';

  @override
  String get parchmentFooter => '鋼鉄の裁き 戦記';

  @override
  String get anonymousCommander => '匿名司令官';

  @override
  String get battleSavedToHistory => '戦史に保存しました！';

  @override
  String get favoritesAdded => 'お気に入りに追加しました！';

  @override
  String get favoritesRemoved => 'お気に入りから削除しました';

  @override
  String get subscriptionCommanderPrice => '司令官 (¥500)';

  @override
  String get subscriptionGeneralPrice => '将軍 (¥1,000)';

  @override
  String get subscriptionWarlordPrice => '覇王 (¥3,000)';

  @override
  String shopTicketsPerDay(int count) {
    return '$count チケット/日';
  }

  @override
  String get shopFeature10Tickets => '1日10チケット';

  @override
  String get shopFeatureBasicScenarios => '全基本シナリオ解放';

  @override
  String get shopFeatureSave20Strategies => '最大20戦略を保存';

  @override
  String get shopFeaturePriorityQueue => '優先バトルキュー';

  @override
  String get shopFeature20Tickets => '1日20チケット';

  @override
  String get shopFeatureEpicMode => 'エピックモード解放';

  @override
  String get shopFeatureUnlimitedHistory => '無制限の戦史';

  @override
  String get shopFeatureSave50Strategies => '最大50戦略を保存';

  @override
  String get shopFeatureAllCommanderFeatures => '司令官の全機能';

  @override
  String get shopFeature50Tickets => '1日50チケット';

  @override
  String get shopFeatureAllModes => '全モード解放';

  @override
  String get shopFeatureBossBattles => 'ボスバトル解放';

  @override
  String get shopFeatureUnlimitedAll => '全機能無制限';

  @override
  String get shopFeatureAllGeneralFeatures => '将軍の全機能';

  @override
  String get splashTitleLine1 => '鋼鉄の';

  @override
  String get splashTitleLine2 => '裁き';

  @override
  String get navHome => 'ホーム';

  @override
  String get navGame => 'ゲーム';

  @override
  String get navMissions => 'ミッション';

  @override
  String get navProfile => 'プロフィール';

  @override
  String get dismiss => '閉じる';

  @override
  String get shopPurchaseInitiated => '購入手続き中！';

  @override
  String get shopPurchasesRestored => '購入を復元しました！';

  @override
  String get shopPurchaseFailed => '購入に失敗しました';

  @override
  String get shopRestoreFailed => '復元に失敗しました';

  @override
  String get statAttack => '攻撃';

  @override
  String get statDefense => '防御';

  @override
  String get statSpeed => '速度';

  @override
  String get statMorale => '士気';

  @override
  String get statMagic => '魔力';

  @override
  String get statLeadership => '統率';

  @override
  String get statStrength => '筋力';

  @override
  String get statIntellect => '知力';

  @override
  String get statSkill => '技巧';

  @override
  String get statArt => '芸術';

  @override
  String get statLife => '生命';

  @override
  String get raceOverviewLabel => '種族の概要';

  @override
  String get raceOverviewHint => '種族の背景・文化・戦闘スタイルを簡単に記述してください...';

  @override
  String get authErrNoAccount => 'このメールアドレスのアカウントが見つかりません。';

  @override
  String get authErrWrongPassword => 'パスワードが違います。';

  @override
  String get authErrEmailInUse => 'このメールアドレスはすでに使用されています。';

  @override
  String get authErrWeakPassword => 'パスワードが弱すぎます。6文字以上にしてください。';

  @override
  String get authErrInvalidEmail => '無効なメールアドレスです。';

  @override
  String get authErrCredentialInUse => 'この認証情報はすでに別のアカウントに連携されています。';

  @override
  String get authErrDefault => '認証に失敗しました。';

  @override
  String get authErrSignInFailed => 'サインインに失敗しました。';

  @override
  String get authErrSignOutFailed => 'サインアウトに失敗しました。';

  @override
  String get battleSaveStrategy => '作戦を保存';

  @override
  String get battleSaveStrategyDialogTitle => '作戦を保存';

  @override
  String get battleSaveStrategyNameHint => '作戦名を入力...';

  @override
  String get battleSaveStrategySuccess => '作戦を保存しました！';

  @override
  String get battleSaveStrategyLimitReached =>
      '保存上限に達しました。上位プランにアップグレードするとより多く保存できます。';

  @override
  String get xShareRewardEarned => 'Xへのシェアでチケット+1獲得！';

  @override
  String get xShareRewardAlreadyClaimed => '本日のXシェア報酬はすでに受け取り済みです。';

  @override
  String get gameModeHistoryPuzzle => '歴史パズル';

  @override
  String get gameModeHistoryPuzzleDesc => '固定された歴史的兵力で対戦。クリアなし — 自己ベストを更新せよ！';

  @override
  String get personalBest => '自己ベスト';

  @override
  String personalBestScore(int wins, int total) {
    return '$wins勝 / $total回';
  }

  @override
  String get personalBestNone => 'まだ記録なし';

  @override
  String get skipAdCost => 'スキップ（チケット-1）';

  @override
  String get watchAdFree => '広告を見る（無料）';

  @override
  String get skipAdSuccess => '広告をスキップしました。チケット-1。';

  @override
  String get skipAdNoTickets => 'スキップするチケットが足りません。';

  @override
  String get practiceAdPrompt => '広告の準備ができています。無料で視聴するかスキップしてください。';

  @override
  String get contentFilterBlocked => '不適切なコンテンツが含まれています。内容を修正してください。';

  @override
  String get battleFailedRetry => 'バトルに失敗しました。もう一度お試しください。';

  @override
  String get battleSignInRequired => '続行するにはサインインしてください。';

  @override
  String get deleteConfirmWord => '削除';

  @override
  String get deleteConfirmHint => '「削除」と入力してください';

  @override
  String get homeNoRaceBanner => 'プレイを始めるには種族を作成してください';

  @override
  String get homeNoRaceBannerSub => '「プレイ」をタップして種族を設定し、戦場へ';

  @override
  String get homeWorldSetting => '世界設定';

  @override
  String get homeWorldSettingChange => '変更';

  @override
  String get homeWorldSettingNone => '世界を選択';

  @override
  String get battleTypeTitle => 'バトルタイプ';

  @override
  String get battleTypeChoose => 'バトルタイプを選択';

  @override
  String get battleTypeSubtitle => '戦いたいバトルのタイプを選んでください';

  @override
  String get battleTypeStandard => 'スタンダードバトル';

  @override
  String get battleTypeStandardDesc => 'シナリオを選んで歴史的な指揮官に挑戦。複数のサブモードが利用可能。';

  @override
  String get battleTypeSubModeBadge => '4モード';

  @override
  String get battleTypeBoss => 'ボスバトル';

  @override
  String get battleTypeBossDesc => '伝説的な敵との極限の戦い。';

  @override
  String get battleTypeBossBadge => 'BOSS';

  @override
  String get battleTypeHistory => '歴史パズル';

  @override
  String get battleTypeHistoryDesc => '固定された歴史的戦力でクリア条件なし。自己ベストを更新しよう！';

  @override
  String get battleTypeHistoryBadge => 'パズル';

  @override
  String get pvpOpponentSubmittedUrge => '相手が戦略を送信しました — 今すぐ送信してください！';

  @override
  String get pvpBothSubmittedResolving => '両者送信済み — バトル解決中...';

  @override
  String get gameHubMyRace => 'マイ種族';

  @override
  String get gameHubMyRaceDesc => '種族のステータスと特性を確認';

  @override
  String get myRaceNoRace => 'まだ種族が作成されていません。「プレイ」をタップして作成してください。';

  @override
  String get myRaceStats => 'ステータス';

  @override
  String get myRaceOverview => '概要';

  @override
  String get validStrategyRequired => '戦略テキストは必須です。';

  @override
  String validStrategyTooLong(int max) {
    return '戦略は$max文字以内で入力してください。';
  }

  @override
  String get validStrategyInappropriate => '不適切なコンテンツが含まれています。内容を修正してください。';

  @override
  String get validRaceNameRequired => '種族名は必須です。';

  @override
  String validRaceNameTooShort(int min) {
    return '種族名は$min文字以上で入力してください。';
  }

  @override
  String validRaceNameTooLong(int max) {
    return '種族名は$max文字以内で入力してください。';
  }

  @override
  String get validRaceNameInvalidChars => '種族名に使用できない文字が含まれています。';

  @override
  String get validRaceNameInappropriate => '種族名に不適切なコンテンツが含まれています。';

  @override
  String get validEmailRequired => 'メールアドレスは必須です。';

  @override
  String get validEmailInvalid => '有効なメールアドレスを入力してください。';

  @override
  String get validPasswordRequired => 'パスワードは必須です。';

  @override
  String get validPasswordTooShort => 'パスワードは6文字以上必要です。';

  @override
  String get settingsBgmVolume => 'BGM音量';

  @override
  String get settingsSfxVolume => '効果音音量';

  @override
  String get gameModeModelSelect => 'AIモデル';

  @override
  String gameModeTicketInfo(int cost) {
    return '$costチケット';
  }

  @override
  String get gameModeWorldview => '世界設定';

  @override
  String get gameModeWorldviewDesc => 'バトルの世界設定を選択してください';

  @override
  String get adminPanel => '管理パネル';

  @override
  String get adminWorldviews => '世界設定';

  @override
  String get adminWorldviewsDesc => '世界設定とAI判定ルールを編集';

  @override
  String get adminScenarios => 'シナリオ';

  @override
  String get adminScenariosDesc => 'バトルシナリオと敵指揮官を編集';

  @override
  String get adminModeAddons => 'モード指示';

  @override
  String get adminModeAddonsDesc => '各ゲームモードのAI指示を編集';

  @override
  String get adminCosts => 'コスト＆モデル';

  @override
  String get adminCostsDesc => 'チケットコストとAIモデル設定を編集';

  @override
  String get adminSave => '保存';

  @override
  String get adminSaveSuccess => '設定を保存しました';

  @override
  String adminSaveError(String error) {
    return '保存に失敗しました: $error';
  }

  @override
  String get adminAdd => '追加';

  @override
  String get adminDelete => '削除';

  @override
  String get adminDeleteConfirm => 'このアイテムを削除してもよろしいですか？';

  @override
  String get adminTitle => 'タイトル';

  @override
  String get adminTitleJa => 'タイトル（日本語）';

  @override
  String get adminDescription => '説明';

  @override
  String get adminDescriptionJa => '説明（日本語）';

  @override
  String get adminCommonJudgment => '判定ルール';

  @override
  String get adminCommanderDef => '指揮官定義';

  @override
  String get adminEnemyName => '敵名';

  @override
  String get adminDifficulty => '難易度';

  @override
  String get adminBattleType => 'バトルタイプ';

  @override
  String get adminKey => 'キー';

  @override
  String get adminValue => '値';

  @override
  String get adminNewWorldview => '新しい世界設定';

  @override
  String get adminNewScenario => '新しいシナリオ';

  @override
  String get worldSettingChoose => '世界設定を選択';

  @override
  String get worldSettingSubtitle => 'バトルルールとシナリオを決定する世界を選んでください';

  @override
  String get worldSettingSelect => '選択';
}
