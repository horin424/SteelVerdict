/**
 * Every product the stores sell, and what it grants. The one place the server
 * decides what a purchase is worth: the request only names a product, and the
 * store's own answer must name the same one.
 *
 * Must match lib/services/purchase/iap_purchase_service.dart ProductIds and the
 * store listings (App Store Connect, Play Console).
 */

export type Tier = "sub500" | "sub1000" | "sub3000";

export type Product =
  | { kind: "subscription"; tier: Tier; rank: number }
  | { kind: "consumable"; tickets: number }
  | { kind: "non_consumable"; unlockField: "scenarioPack1Unlocked" };

export const PRODUCTS: Record<string, Product> = {
  // Subscriptions: one group, ranked. The highest active one decides the tier.
  strategy_game_sub_500_monthly: { kind: "subscription", tier: "sub500", rank: 1 },
  strategy_game_sub_1000_monthly: { kind: "subscription", tier: "sub1000", rank: 2 },
  strategy_game_sub_3000_monthly: { kind: "subscription", tier: "sub3000", rank: 3 },
  // Ticket packs: each purchase adds tickets once.
  strategy_game_tickets_10: { kind: "consumable", tickets: 10 },
  strategy_game_tickets_30: { kind: "consumable", tickets: 30 },
  // Scenario pack: bought once, owned for good (B13).
  strategy_game_scenario_pack_1: { kind: "non_consumable", unlockField: "scenarioPack1Unlocked" },
};

export function productFor(productId: string): Product | undefined {
  return Object.prototype.hasOwnProperty.call(PRODUCTS, productId) ? PRODUCTS[productId] : undefined;
}
