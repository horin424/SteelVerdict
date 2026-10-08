import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/error_snackbar.dart';
import '../../services/purchase/iap_purchase_service.dart';
import '../../services/purchase/purchase_service.dart';

/// What to tell the user about a purchase; null when there is nothing to say
/// (the user closed the store's sheet).
String? purchaseOutcomeMessage(AppLocalizations l10n, PurchaseOutcome outcome) {
  switch (outcome.status) {
    case PurchaseOutcomeStatus.granted:
    case PurchaseOutcomeStatus.alreadyGranted:
      final productId = outcome.productId;
      switch (ProductIds.kindOf(productId)) {
        case ProductKind.consumable:
          return l10n.shopTicketsAdded(outcome.amount ?? ProductIds.tickets[productId] ?? 0);
        case ProductKind.subscription:
          return l10n.shopPlanActive(_planName(l10n, productId));
        case ProductKind.nonConsumable:
          return l10n.shopPackUnlocked(l10n.shopAncientBattles);
        case null:
          return l10n.shopPurchasesRestored;
      }
    case PurchaseOutcomeStatus.pending:
      return l10n.shopPaymentPending;
    case PurchaseOutcomeStatus.retryLater:
      return l10n.shopPurchaseCheckLater;
    case PurchaseOutcomeStatus.refused:
      switch (outcome.reason) {
        case 'other_account':
        case 'claimed_by_other_account':
          return l10n.shopPurchaseOtherAccount;
        case 'expired':
        case 'not_active':
          return l10n.shopPurchaseEnded;
        case 'refunded':
          return l10n.shopPurchaseRefunded;
        default:
          return l10n.shopPurchaseNotValid;
      }
    case PurchaseOutcomeStatus.failed:
      return l10n.shopPurchaseFailed;
    case PurchaseOutcomeStatus.canceled:
      return null;
  }
}

/// The message after a restore: what came back, or that there was nothing.
String restoreSummaryMessage(AppLocalizations l10n, List<PurchaseOutcome> outcomes) {
  if (outcomes.isEmpty) return l10n.shopNothingToRestore;
  if (outcomes.any((o) => o.isGranted)) return l10n.shopPurchasesRestored;
  if (outcomes.any((o) => o.status == PurchaseOutcomeStatus.retryLater)) {
    return l10n.shopPurchaseCheckLater;
  }
  if (outcomes.any((o) => o.status == PurchaseOutcomeStatus.pending)) {
    return l10n.shopPaymentPending;
  }
  return purchaseOutcomeMessage(l10n, outcomes.first) ?? l10n.shopNothingToRestore;
}

void showPurchaseOutcome(BuildContext context, PurchaseOutcome outcome) {
  final l10n = AppLocalizations.of(context)!;
  final message = purchaseOutcomeMessage(l10n, outcome);
  if (message == null) return;
  if (outcome.isGranted || outcome.status == PurchaseOutcomeStatus.pending) {
    ErrorSnackbar.showSuccess(context, message);
  } else {
    ErrorSnackbar.showError(context, message);
  }
}

/// [outcomes] is null when the store couldn't be asked.
void showRestoreSummary(BuildContext context, List<PurchaseOutcome>? outcomes) {
  final l10n = AppLocalizations.of(context)!;
  if (outcomes == null) {
    ErrorSnackbar.showError(context, l10n.shopRestoreFailed);
  } else if (outcomes.isEmpty || outcomes.any((o) => o.isGranted)) {
    ErrorSnackbar.showSuccess(context, restoreSummaryMessage(l10n, outcomes));
  } else {
    ErrorSnackbar.showError(context, restoreSummaryMessage(l10n, outcomes));
  }
}

String _planName(AppLocalizations l10n, String productId) {
  switch (productId) {
    case ProductIds.sub500Monthly:
      return l10n.subscriptionCommander;
    case ProductIds.sub1000Monthly:
      return l10n.subscriptionGeneral;
    default:
      return l10n.subscriptionWarlord;
  }
}
