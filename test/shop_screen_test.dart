// The shop shows the store's prices, can't sell what the store didn't return,
// and links the Terms of Use, the Privacy Policy and subscription management.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:strategy_game/core/l10n/app_localizations.dart';
import 'package:strategy_game/features/auth/auth_providers.dart';
import 'package:strategy_game/features/shop/screens/shop_screen.dart';
import 'package:strategy_game/features/shop/shop_providers.dart';
import 'package:strategy_game/features/shop/widgets/one_time_purchase_tile.dart';
import 'package:strategy_game/services/purchase/iap_purchase_service.dart';

ProductDetails product(String id, String price) => ProductDetails(
    id: id, title: id, description: '', price: price, rawPrice: 0, currencyCode: 'JPY');

void main() {
  testWidgets('store prices; what the store lacks is disabled; legal links', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        productsProvider.overrideWith((ref) async => [
              product(ProductIds.sub1000Monthly, '￥1,000'),
              product(ProductIds.tickets10, '￥240'),
            ]),
        currentUserModelProvider.overrideWith((ref) async => null),
      ],
      child: const MaterialApp(
        locale: Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShopScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('￥1,000/月'), findsOneWidget);
    expect(find.text('￥240'), findsOneWidget);
    expect(find.text('¥500/月'), findsNothing, reason: 'no hard-coded prices any more');
    // Commander and Warlord, the 30-ticket pack and the scenario pack: no price.
    expect(find.text('—'), findsNWidgets(4));

    final enabledPlanButtons = find.byWidgetPredicate((w) => w is ElevatedButton && w.onPressed != null);
    expect(enabledPlanButtons, findsOneWidget, reason: 'only General was returned by the store');
    final enabledTiles = find.descendant(
      of: find.byType(OneTimePurchaseTile),
      matching: find.byWidgetPredicate((w) => w is InkWell && w.onTap != null),
    );
    expect(enabledTiles, findsOneWidget, reason: 'only the 10-ticket pack was returned');

    expect(find.text('利用規約'), findsOneWidget);
    expect(find.text('プライバシーポリシー'), findsOneWidget);
    expect(find.text('サブスクリプションの管理'), findsOneWidget);
  });

  testWidgets('plan perks are what the game gives', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        productsProvider.overrideWith((ref) async => [
              product(ProductIds.sub500Monthly, '￥500'),
              product(ProductIds.sub1000Monthly, '￥1,000'),
              product(ProductIds.sub3000Monthly, '￥3,000'),
            ]),
        currentUserModelProvider.overrideWith((ref) async => null),
      ],
      child: const MaterialApp(
        locale: Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShopScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    // Daily tickets as claimDailyReward gives them; Epic for any plan; Boss for Warlord.
    for (final perk in ['1日10チケット', '1日15チケット', '1日50チケット', 'エピックモード解放', 'ボスバトル解放']) {
      expect(find.text(perk), findsOneWidget, reason: perk);
    }
    // Promised before, but not what the game does.
    for (final gone in ['1日20チケット', '優先バトルキュー', '最大20戦略を保存', '最大50戦略を保存',
        '無制限の戦史', '全機能無制限', '全基本シナリオ解放']) {
      expect(find.text(gone), findsNothing, reason: gone);
    }
  });
}
