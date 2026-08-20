import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

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
          l10n.settingsHelpCenter,
          style: AppTextStyles.headlineMedium,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.borderGold,
                  Colors.transparent,
                ],
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
          Text(
            '▸ ',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.goldDim),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(height: 1.6),
            ),
          ),
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

class _EnContent extends StatelessWidget {
  const _EnContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Help Center',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.goldBright,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Support Guide  ·  Last updated: April 2, 2026',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        const _Body(
          'Use this guide to learn the basics of Steel Verdict, understand the game flow, and find the best place to get support.',
        ),

        _Section(
          title: '1. Getting Started',
          children: [
            const _Bullet(
              'Create your race, choose a scenario, then select a game mode.',
            ),
            const _Bullet(
              'Check the world setting before starting battle. Some scenarios are tied to a specific worldview.',
            ),
            const _Bullet(
              'Practice mode is free and is a good way to test strategies.',
            ),
          ],
        ),

        _Section(
          title: '2. Game Modes',
          children: [
            const _SubTitle('Normal'),
            const _Body('The standard battle experience with a full report.'),
            const _SubTitle('Tabletop'),
            const _Body(
              'A fast simulation mode that focuses on estimated win rate.',
            ),
            const _SubTitle('Epic'),
            const _Body(
              'A more dramatic battle report with Claude support where available.',
            ),
            const _SubTitle('Practice'),
            const _Body('Free battles for experimentation and learning.'),
          ],
        ),

        _Section(
          title: '3. Helpful Tips',
          children: [
            const _Bullet('Match your strategy to your race stats.'),
            const _Bullet(
              'If a mode is locked, check your subscription status.',
            ),
            const _Bullet(
              'If something looks wrong, reload the screen once after changing settings or config.',
            ),
          ],
        ),

        _Section(
          title: '4. Support',
          children: [
            const _Body(
              'If you need help, start with this help center. For account or policy questions, use the Privacy Policy page. For bugs or feedback, contact support at your@example.com.',
            ),
          ],
        ),

        const SizedBox(height: 32),
        Center(
          child: Text(
            'Steel Verdict Support',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _JaContent extends StatelessWidget {
  const _JaContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ヘルプセンター',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.goldBright,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'サポートガイド  ·  最終更新日：2026年4月2日',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        const _Body('このガイドでは、鋼鉄の審判の基本操作、ゲームの流れ、サポートの案内をまとめています。'),

        _Section(
          title: '1. はじめに',
          children: [
            const _Bullet('種族を作成し、シナリオを選び、ゲームモードを選択します。'),
            const _Bullet('戦闘を開始する前に世界設定を確認してください。シナリオによっては特定の世界観に固定されます。'),
            const _Bullet('練習モードは無料なので、戦略の確認に向いています。'),
          ],
        ),

        _Section(
          title: '2. ゲームモード',
          children: [
            const _SubTitle('通常'),
            const _Body('標準的な戦闘体験と詳細なレポートが表示されます。'),
            const _SubTitle('卓上'),
            const _Body('勝率の推定に重点を置いた高速シミュレーションです。'),
            const _SubTitle('叙事詩'),
            const _Body('利用可能な場合は Claude を使った、より劇的な戦闘レポートです。'),
            const _SubTitle('練習'),
            const _Body('戦略を試しながら学べる無料モードです。'),
          ],
        ),

        _Section(
          title: '3. 役立つヒント',
          children: [
            const _Bullet('戦略は自分の種族ステータスに合わせて調整してください。'),
            const _Bullet('モードがロックされている場合は、サブスクリプション状態を確認してください。'),
            const _Bullet('設定やコンフィグを変更した後に表示がおかしい場合は、画面を再読み込みしてください。'),
          ],
        ),

        _Section(
          title: '4. サポート',
          children: [
            const _Body(
              '困ったときはまずこのヘルプセンターをご覧ください。アカウントや規約に関する内容はプライバシーポリシーをご確認ください。バグ報告や要望は your@example.com までお願いします。',
            ),
          ],
        ),

        const SizedBox(height: 32),
        Center(
          child: Text(
            'Steel Verdict サポート',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
