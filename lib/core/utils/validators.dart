import '../constants/app_constants.dart';
import '../l10n/app_localizations.dart';
import 'content_filter.dart';

class Validators {
  Validators._();

  static String? validateStrategyText(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.validStrategyRequired ?? 'Strategy text is required.';
    }
    final trimmed = value.trim();
    if (trimmed.length > AppConstants.maxStrategyLength) {
      return l10n?.validStrategyTooLong(AppConstants.maxStrategyLength) ??
          'Strategy must be at most ${AppConstants.maxStrategyLength} characters.';
    }
    if (ContentFilter.containsInappropriate(trimmed)) {
      return l10n?.validStrategyInappropriate ?? 'Strategy contains inappropriate content. Please revise.';
    }
    return null;
  }

  static String? validateRaceName(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.validRaceNameRequired ?? 'Race name is required.';
    }
    final trimmed = value.trim();
    if (trimmed.length < AppConstants.minRaceNameLength) {
      return l10n?.validRaceNameTooShort(AppConstants.minRaceNameLength) ??
          'Race name must be at least ${AppConstants.minRaceNameLength} characters.';
    }
    if (trimmed.length > AppConstants.maxRaceNameLength) {
      return l10n?.validRaceNameTooLong(AppConstants.maxRaceNameLength) ??
          'Race name must be at most ${AppConstants.maxRaceNameLength} characters.';
    }
    final validChars = RegExp(r'^[a-zA-Z0-9\u3040-\u30FF\u4E00-\u9FFF\s\-_]+$');
    if (!validChars.hasMatch(trimmed)) {
      return l10n?.validRaceNameInvalidChars ?? 'Race name contains invalid characters.';
    }
    if (ContentFilter.containsInappropriate(trimmed)) {
      return l10n?.validRaceNameInappropriate ?? 'Race name contains inappropriate content.';
    }
    return null;
  }

  static String? validateStatAllocation(Map<String, int> stats, int maxPoints) {
    if (stats.isEmpty) {
      return 'No stats allocated.';
    }
    int total = 0;
    for (final entry in stats.entries) {
      if (entry.value < 0) {
        return 'Stat "${entry.key}" cannot be negative.';
      }
      total += entry.value;
    }
    if (total > maxPoints) {
      return 'Total stat points ($total) exceeds maximum ($maxPoints).';
    }
    if (total == 0) {
      return 'At least one stat point must be allocated.';
    }
    return null;
  }

  static String? validateEmail(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.validEmailRequired ?? 'Email is required.';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return l10n?.validEmailInvalid ?? 'Enter a valid email address.';
    }
    return null;
  }

  static String? validatePassword(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.isEmpty) {
      return l10n?.validPasswordRequired ?? 'Password is required.';
    }
    if (value.length < 6) {
      return l10n?.validPasswordTooShort ?? 'Password must be at least 6 characters.';
    }
    return null;
  }
}
