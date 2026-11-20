// The 「報告」 sheet (reporting AI output, Google Play's AI-Generated Content
// policy): it sends what the server's reportAiContent expects, waits for a
// reason, offers the chronicle when there is one, and keeps the sheet open
// with a message when the server refuses.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_game/app.dart' show appScaffoldMessengerKey;
import 'package:strategy_game/core/constants/app_constants.dart';
import 'package:strategy_game/core/l10n/app_localizations.dart';
import 'package:strategy_game/features/reports/ai_report_sheet.dart';

void main() {
  late List<Map<String, dynamic>> sent;
  late List<AiReportResult> answers;

  Future<AiReportResult> fakeSend(Map<String, dynamic> payload) async {
    sent.add(payload);
    return answers.isEmpty ? AiReportResult.sent : answers.removeAt(0);
  }

  Future<void> open(WidgetTester tester, List<AiReportTarget> targets) async {
    await tester.pumpWidget(MaterialApp(
      scaffoldMessengerKey: appScaffoldMessengerKey,
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showAiReportSheet(
                context,
                targets: targets,
                strategy: '丘を守る',
                gameMode: 'normal',
                scenarioId: 'aces_001',
                worldviewKey: 'modern',
                send: fakeSend,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  FilledButton sendButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, '送信'));

  setUp(() {
    sent = [];
    answers = [];
  });

  testWidgets('one text: send waits for a reason, then sends the whole report', (tester) async {
    await open(tester, const [AiReportTarget(kind: 'battle', text: 'AIの文')]);
    expect(find.text('AIの出力を報告'), findsOneWidget);
    expect(find.text('報告する文章'), findsNothing, reason: 'only one text: nothing to choose');
    expect(sendButton(tester).onPressed, isNull);

    await tester.tap(find.text('過度に暴力的な表現'));
    await tester.pump();
    expect(sendButton(tester).onPressed, isNotNull);
    await tester.enterText(find.byType(TextField), '  表現がひどい  ');
    await tester.tap(find.text('送信'));
    await tester.pumpAndSettle();

    expect(sent, [
      {
        'kind': 'battle',
        'reason': 'violence',
        'aiText': 'AIの文',
        'strategy': '丘を守る',
        'comment': '表現がひどい',
        'gameMode': 'normal',
        'scenarioId': 'aces_001',
        'worldviewKey': 'modern',
        'appVersion': AppConstants.appVersion,
      }
    ]);
    expect(find.text('AIの出力を報告'), findsNothing, reason: 'the sheet closes');
    expect(find.text('報告を受け付けました。ご協力ありがとうございます。'), findsOneWidget);
  });

  testWidgets('two texts: the chronicle can be chosen', (tester) async {
    await open(tester, const [
      AiReportTarget(kind: 'battle', text: '戦闘の文'),
      AiReportTarget(kind: 'chronicle', text: '戦記の文'),
    ]);
    expect(find.text('報告する文章'), findsOneWidget);
    await tester.tap(find.text('戦記'));
    await tester.tap(find.text('その他'));
    await tester.pump();
    await tester.tap(find.text('送信'));
    await tester.pumpAndSettle();
    expect([sent.single['kind'], sent.single['aiText'], sent.single['reason']], ['chronicle', '戦記の文', 'other']);
  });

  testWidgets('the daily limit: the sheet stays open and says so', (tester) async {
    answers = [AiReportResult.limit];
    await open(tester, const [AiReportTarget(kind: 'battle', text: 'AIの文')]);
    await tester.tap(find.text('性的な表現'));
    await tester.pump();
    await tester.tap(find.text('送信'));
    await tester.pumpAndSettle();
    expect(find.text('報告は1日20件までです。明日またお試しください。'), findsOneWidget);
    expect(find.text('AIの出力を報告'), findsOneWidget);
  });

  testWidgets('a failure says try again, and a retry can go through', (tester) async {
    answers = [AiReportResult.failed, AiReportResult.sent];
    await open(tester, const [AiReportTarget(kind: 'battle', text: 'AIの文')]);
    await tester.tap(find.text('不快・差別的な表現'));
    await tester.pump();
    await tester.tap(find.text('送信'));
    await tester.pumpAndSettle();
    expect(find.text('報告を送れませんでした。時間をおいて、もう一度お試しください。'), findsOneWidget);
    await tester.tap(find.text('送信'));
    await tester.pumpAndSettle();
    expect(sent.length, 2);
    expect(find.text('AIの出力を報告'), findsNothing);
  });

  testWidgets('cancel closes without sending', (tester) async {
    await open(tester, const [AiReportTarget(kind: 'battle', text: 'AIの文')]);
    await tester.tap(find.text('その他'));
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(sent, isEmpty);
    expect(find.text('AIの出力を報告'), findsNothing);
  });

  testWidgets('nothing to report: no sheet', (tester) async {
    await open(tester, const [AiReportTarget(kind: 'battle', text: '   ')]);
    expect(find.text('AIの出力を報告'), findsNothing);
  });
}
