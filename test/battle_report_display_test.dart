import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_game/features/battle/widgets/battle_report_display.dart';

/// Battle reports are markdown. Marks inside a line showed as literal
/// asterisks, ### headings kept their #, and a *** line crashed (B22).
void main() {
  const report = '# BATTLE REPORT\n'
      '### Phase One\n'
      'The **left flank** held and *rain* fell.\n'
      '***\n'
      '- **Cavalry** broke through.\n'
      'A lone * stays as written.';

  Iterable<String> renderedTexts(WidgetTester tester) => tester
      .widgetList<RichText>(find.byType(RichText))
      .map((w) => w.text.toPlainText());

  List<TextSpan> spansWith(WidgetTester tester, String text) => tester
      .widgetList<RichText>(find.byType(RichText))
      .expand((w) {
        final spans = <TextSpan>[];
        w.text.visitChildren((s) {
          if (s is TextSpan && s.text == text) spans.add(s);
          return true;
        });
        return spans;
      })
      .toList();

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: BattleReportDisplay(reportText: report))),
      ));

  testWidgets('no markdown marks are left in the text', (tester) async {
    await pump(tester);
    final texts = renderedTexts(tester).toList();
    expect(texts.where((t) => t.contains('**')), isEmpty);
    expect(texts.where((t) => t.contains('#')), isEmpty);
    expect(texts, contains('Phase One'));
    expect(texts, contains('The left flank held and rain fell.'));
    expect(texts, contains('Cavalry broke through.'));
  });

  testWidgets('bold and italic inside a line are styled', (tester) async {
    await pump(tester);
    expect(spansWith(tester, 'left flank').single.style?.fontWeight, FontWeight.bold);
    expect(spansWith(tester, 'rain').single.style?.fontStyle, FontStyle.italic);
    expect(spansWith(tester, 'Cavalry').single.style?.fontWeight, FontWeight.bold);
  });

  testWidgets('a *** line is a rule, not a crash', (tester) async {
    await pump(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('a lone asterisk stays as written', (tester) async {
    await pump(tester);
    expect(renderedTexts(tester), contains('A lone * stays as written.'));
  });
}
