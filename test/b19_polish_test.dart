import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_game/app.dart' show appScaffoldMessengerKey;
import 'package:strategy_game/core/l10n/app_localizations.dart';
import 'package:strategy_game/core/theme/app_colors.dart';
import 'package:strategy_game/core/widgets/error_snackbar.dart';
import 'package:strategy_game/features/race_creation/widgets/points_remaining_indicator.dart';

/// Two small things seen on the emulator (B19).
void main() {
  Widget app(Widget home) => MaterialApp(
        scaffoldMessengerKey: appScaffoldMessengerKey,
        locale: const Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: home),
      );

  testWidgets('an error message closes by itself after 4 seconds', (tester) async {
    await tester.pumpWidget(app(Builder(
      builder: (context) => TextButton(
        onPressed: () => ErrorSnackbar.showError(context, 'Battle failed'),
        child: const Text('go'),
      ),
    )));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Battle failed'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Battle failed'), findsNothing,
        reason: 'with a Dismiss button Flutter kept it up until tapped');
  });

  Future<({Color border, Color bar})> colours(WidgetTester tester, int used) async {
    await tester.pumpWidget(app(PointsRemainingIndicator(used: used, total: 30)));
    final box = tester.widget<Container>(find.byType(Container).first).decoration! as BoxDecoration;
    final bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    return (
      border: (box.border! as Border).top.color,
      bar: (bar.valueColor! as AlwaysStoppedAnimation<Color>).value,
    );
  }

  testWidgets('30 of 30 points is complete: green, not red', (tester) async {
    final c = await colours(tester, 30);
    expect(c.border, AppColors.victoryGreen);
    expect(c.bar, AppColors.victoryGreen);
    expect(find.text('全ポイント配分済み！'), findsOneWidget);
  });

  testWidgets('over the limit is red', (tester) async {
    final c = await colours(tester, 31);
    expect(c.border, AppColors.warRed);
    expect(c.bar, AppColors.warRed);
  });

  testWidgets('nearly there is gold, early is green', (tester) async {
    expect((await colours(tester, 25)).bar, AppColors.goldAccent);
    expect((await colours(tester, 10)).bar, AppColors.victoryGreen);
    expect((await colours(tester, 10)).border, AppColors.borderColor);
  });
}
