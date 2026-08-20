import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isJa = locale == 'ja';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.steelDark,
        title: Text(
          l10n.settingsPrivacyPolicy,
          style: AppTextStyles.headlineMedium,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, AppColors.borderGold, Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: isJa ? const _JaContent() : const _EnContent(),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.borderGold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.goldBright,
                  letterSpacing: 0.06,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...children,
        const SizedBox(height: 8),
        const Divider(color: AppColors.borderSubtle, height: 1),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.bodySmall.copyWith(height: 1.7)),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('▸ ', style: AppTextStyles.bodySmall.copyWith(color: AppColors.goldDim)),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall.copyWith(height: 1.6))),
        ],
      ),
    );
  }
}

class _SubTitle extends StatelessWidget {
  final String text;
  const _SubTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        text,
        style: AppTextStyles.labelMedium.copyWith(color: AppColors.goldLight),
      ),
    );
  }
}

// ── English content ───────────────────────────────────────────────────────────

class _EnContent extends StatelessWidget {
  const _EnContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy Policy',
          style: AppTextStyles.headlineLarge.copyWith(color: AppColors.goldBright),
        ),
        const SizedBox(height: 4),
        Text(
          'Steel Verdict  ·  Last updated: March 28, 2026',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        const _Body(
          'This Privacy Policy explains how Steel Verdict collects, uses, and protects your information when you use our mobile application.',
        ),

        _Section(title: '1. Information We Collect', children: [
          const _SubTitle('Account Information'),
          const _Body('You may use the app anonymously or register with an email address. If you register, we store your email address and a unique user ID in Firebase Authentication.'),
          const _SubTitle('Game Data'),
          const _Body('We store the following in Firebase Firestore:'),
          const _Bullet('Race name and stats (Strength, Intellect, Skill, Magic, Art, Life)'),
          const _Bullet('Battle history, results, and AI-generated battle reports'),
          const _Bullet('Ticket balance and subscription status'),
          const _Bullet('PvP match data (strategies submitted, outcomes)'),
          const _Bullet('War chronicle entries and saved favorites'),
          const _SubTitle('Battle Strategy Text'),
          const _Body('When you submit a battle, the strategy text you type is sent to Google Gemini or Anthropic Claude to generate the battle report. We do not store your raw strategy text beyond what is saved in your battle history.'),
          const _SubTitle('Local Storage'),
          const _Body('Some preferences and cached data are stored locally on your device using Hive and never leave your device unless synced to Firestore.'),
          const _SubTitle('Advertising Data'),
          const _Body('The app uses Google AdMob to display rewarded ads. AdMob may collect device identifiers and usage data to serve relevant advertisements.'),
          const _SubTitle('Purchase Data'),
          const _Body('In-app purchases are processed by Apple App Store or Google Play. We receive a receipt token to validate purchases but do not store your payment information.'),
        ]),

        _Section(title: '2. How We Use Your Information', children: [
          const _Bullet('To operate and deliver the game experience'),
          const _Bullet('To generate AI battle reports using your submitted strategy'),
          const _Bullet('To manage your ticket balance and subscription entitlements'),
          const _Bullet('To match you with opponents in PvP mode'),
          const _Bullet('To display rewarded advertisements and credit earned tickets'),
          const _Bullet('To validate in-app purchases'),
        ]),

        _Section(title: '3. Third-Party Services', children: [
          const _Bullet('Firebase (Google) — Authentication, Firestore, Cloud Functions, Remote Config'),
          const _Bullet('Google Gemini API — AI battle report generation'),
          const _Bullet('Anthropic Claude API — AI battle report generation (Epic mode)'),
          const _Bullet('Google AdMob — Rewarded advertisements'),
          const _Bullet('Google Play / Apple App Store — In-app purchases'),
        ]),

        _Section(title: '4. Data Retention', children: [
          const _Body('Your account and game data are retained while your account is active. PvP matches are automatically deleted after 24 hours of inactivity. Inactive accounts may be deleted after an extended period.'),
        ]),

        _Section(title: '5. Data Security', children: [
          const _Body('Firebase security rules restrict access so only authenticated users can read or write their own records. Cloud Functions perform server-side validation before processing any battle request.'),
        ]),

        _Section(title: '6. Children\'s Privacy', children: [
          const _Body('Steel Verdict is not directed at children under 13. We do not knowingly collect personal information from children under 13. If you believe a child has provided personal data, contact us and we will delete it promptly.'),
        ]),

        _Section(title: '7. Your Rights', children: [
          const _Body('You may request deletion of your account and data at any time by contacting us. We will delete your records within 30 days of your request.'),
        ]),

        _Section(title: '8. Contact', children: [
          const _Body('For any questions about this Privacy Policy, please contact us at: your@example.com'),
        ]),

        const SizedBox(height: 32),
        Center(
          child: Text(
            '© 2026 Steel Verdict. All rights reserved.',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Japanese content ──────────────────────────────────────────────────────────

class _JaContent extends StatelessWidget {
  const _JaContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'プライバシーポリシー',
          style: AppTextStyles.headlineLarge.copyWith(color: AppColors.goldBright),
        ),
        const SizedBox(height: 4),
        Text(
          '鋼鉄の審判  ·  最終更新日：2026年3月28日',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        const _Body('本プライバシーポリシーは、鋼鉄の審判（以下「本アプリ」）がご利用者の情報をどのように収集・利用・保護するかについて説明します。'),

        _Section(title: '1. 収集する情報', children: [
          const _SubTitle('アカウント情報'),
          const _Body('本アプリは匿名またはメールアドレスで利用できます。メールアドレスで登録された場合、Firebase Authentication にメールアドレスと一意のユーザーIDを保存します。'),
          const _SubTitle('ゲームデータ'),
          const _Body('以下のデータを Firebase Firestore に保存します：'),
          const _Bullet('種族名および能力値（Strength・Intellect・Skill・Magic・Art・Life）'),
          const _Bullet('戦闘履歴・結果・AIが生成した戦闘レポート'),
          const _Bullet('チケット残高とサブスクリプションの状態'),
          const _Bullet('PvP対戦データ（提出した戦略・結果）'),
          const _Bullet('生成した戦争年代記およびお気に入り'),
          const _SubTitle('戦略テキスト'),
          const _Body('戦闘を送信する際、入力した戦略テキストはGoogle GeminiまたはAnthropic Claudeへ送信されます。入力された戦略テキストは、戦闘履歴として保存されるもの以外は永続的に保存されません。'),
          const _SubTitle('ローカルストレージ'),
          const _Body('一部の設定やキャッシュデータはHiveを使用してデバイス上にローカル保存されます。Firestoreに同期されない限り、デバイス外に送信されることはありません。'),
          const _SubTitle('広告データ'),
          const _Body('本アプリはGoogle AdMobを使用してリワード広告を表示します。AdMobはデバイス識別子や利用状況データを収集する場合があります。'),
          const _SubTitle('購入データ'),
          const _Body('アプリ内購入はApple App StoreまたはGoogle Playによって処理されます。当方は購入確認のためのレシートトークンを受け取りますが、支払い情報は保存しません。'),
        ]),

        _Section(title: '2. 情報の利用目的', children: [
          const _Bullet('ゲームの提供および運営'),
          const _Bullet('入力された戦略に基づくAI戦闘レポートの生成'),
          const _Bullet('チケット残高およびサブスクリプション特典の管理'),
          const _Bullet('PvPモードでの対戦相手とのマッチング'),
          const _Bullet('リワード広告の表示および獲得チケットの付与'),
          const _Bullet('アプリ内購入の検証'),
        ]),

        _Section(title: '3. 利用する第三者サービス', children: [
          const _Bullet('Firebase（Google）— 認証・データベース・Cloud Functions・Remote Config'),
          const _Bullet('Google Gemini API — AIによる戦闘レポート生成'),
          const _Bullet('Anthropic Claude API — AIによる戦闘レポート生成（Epicモード）'),
          const _Bullet('Google AdMob — リワード広告'),
          const _Bullet('Google Play / Apple App Store — アプリ内購入'),
        ]),

        _Section(title: '4. データの保持期間', children: [
          const _Body('アカウントおよびゲームデータはアカウントが有効な期間中保持されます。PvP対戦データは非アクティブ後24時間で自動削除されます。長期間利用されていないアカウントは削除される場合があります。'),
        ]),

        _Section(title: '5. データのセキュリティ', children: [
          const _Body('Firebaseのセキュリティルールにより、各ユーザーは自分のデータのみにアクセスできます。Cloud Functionsはリクエスト処理前にサーバー側でバリデーションを行います。'),
        ]),

        _Section(title: '6. 児童のプライバシー', children: [
          const _Body('本アプリは13歳未満の児童を対象としていません。13歳未満の児童から故意に個人情報を収集することはありません。'),
        ]),

        _Section(title: '7. お客様の権利', children: [
          const _Body('アカウントおよび関連データの削除はいつでもご依頼いただけます。ご依頼から30日以内に削除いたします。'),
        ]),

        _Section(title: '8. お問い合わせ', children: [
          const _Body('本プライバシーポリシーに関するお問い合わせは your@example.com までご連絡ください。'),
        ]),

        const SizedBox(height: 32),
        Center(
          child: Text(
            '© 2026 鋼鉄の審判. All rights reserved.',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
