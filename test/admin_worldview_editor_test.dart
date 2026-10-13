import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_game/core/l10n/app_localizations.dart';
import 'package:strategy_game/features/admin/screens/admin_worldview_editor.dart';
import 'package:strategy_game/models/game_config_model.dart';
import 'package:strategy_game/services/game_config/game_config_providers.dart';

/// The world editor on a phone, in Japanese (B20): the result type was in
/// English, its dropdown overflowed by 29 px, and the list was unsorted.
void main() {
  final config = GameConfigModel.fromJson({
    'worldviews': {
      'zulu_world': {'title': 'Zulu', 'common_judgment': 'z', 'worldview_description': 'z'},
      'alpha_world': {'title': 'Alpha', 'common_judgment': 'a', 'worldview_description': 'a'},
    },
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340); // 360 x 780 dp at 3x
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [gameConfigProvider.overrideWithValue(config)],
      child: const MaterialApp(
        locale: Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdminWorldviewEditor(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the list is sorted by key', (tester) async {
    await pump(tester);
    final alpha = tester.getTopLeft(find.text('ID: alpha_world')).dy;
    final zulu = tester.getTopLeft(find.text('ID: zulu_world')).dy;
    expect(alpha, lessThan(zulu));
  });

  testWidgets('result type is in Japanese and fits a phone', (tester) async {
    await pump(tester);
    await tester.tap(find.text('ID: alpha_world'));
    await tester.pumpAndSettle();
    // The form is a lazy ListView (the second one; the first is the list).
    final form = find.descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable)).first;
    final label = find.text('結果の種類');
    await tester.scrollUntilVisible(label, 300, scrollable: form);
    await tester.pumpAndSettle();
    expect(label, findsOneWidget);
    expect(find.text('戦闘（勝利・敗北・引き分け）'), findsOneWidget);
    expect(find.text('Result type'), findsNothing);
    expect(tester.takeException(), isNull, reason: 'no overflow');
  });
}
