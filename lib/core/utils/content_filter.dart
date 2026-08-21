class ContentFilter {
  ContentFilter._();

  /// Terms matched on whole-word boundaries.
  ///
  /// The previous implementation matched raw substrings, which rejected ordinary
  /// strategy text in a *military* game: "ass" caught **ass**ault / m**ass** /
  /// p**ass** / cl**ass**, "cock" caught **cock**pit, and "sex" caught Wes**sex**
  /// and Es**sex**. Players were blocked before they could even submit.
  ///
  /// "kill" and "murder" were also removed outright — "kill the enemy commander"
  /// is the subject matter of the game, not abuse. If those should be blocked,
  /// that is a content-policy call, not a technical one.
  static const List<String> _wordBlacklist = [
    'fuck',
    'shit',
    'bitch',
    'bastard',
    'dick',
    'cock',
    'pussy',
    'nigger',
    'nigga',
    'faggot',
    'retard',
    'slut',
    'whore',
    'cunt',
    'penis',
    'vagina',
    'sex',
    'porn',
    'nude',
    'naked',
    'rape',
  ];

  /// Japanese has no word boundaries, so each term carries its own guard against
  /// the common word it would otherwise sit inside — most importantly ばかり
  /// ("only/just"), which appears constantly in ordinary Japanese.
  static const List<String> _jaPatterns = [
    'くそ(?!ま)', // くそ, but not くそまじめ
    'クソ',
    'ばか(?!り|らしい)', // ばか, but not ばかり / ばからしい
    'バカ(?!リ)',
    'アホ',
    'あほ',
    'きちく',
    'ちくしょう',
  ];

  static final List<RegExp> _patterns = [
    for (final w in _wordBlacklist)
      RegExp('\\b${RegExp.escape(w)}\\b', caseSensitive: false, unicode: true),
    for (final p in _jaPatterns) RegExp(p, caseSensitive: false, unicode: true),
  ];

  /// Returns true if the text contains inappropriate words.
  static bool containsInappropriate(String text) {
    return _patterns.any((p) => p.hasMatch(text));
  }

  /// Replaces inappropriate words with ***.
  static String filterText(String text) {
    String result = text;
    for (final pattern in _patterns) {
      result = result.replaceAllMapped(
        pattern,
        (match) => '*' * match.group(0)!.length,
      );
    }
    return result;
  }

  /// Adds a custom word to the runtime blacklist (not persisted).
  static final List<RegExp> _runtimeBlacklist = [];

  static void addToBlacklist(String word) {
    final pattern = RegExp(
      '\\b${RegExp.escape(word)}\\b',
      caseSensitive: false,
      unicode: true,
    );
    if (!_runtimeBlacklist.any((p) => p.pattern == pattern.pattern)) {
      _runtimeBlacklist.add(pattern);
    }
  }

  static bool containsInappropriateWithRuntime(String text) {
    if (containsInappropriate(text)) return true;
    return _runtimeBlacklist.any((p) => p.hasMatch(text));
  }
}
