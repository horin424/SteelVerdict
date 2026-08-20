class ContentFilter {
  ContentFilter._();

  static const List<String> _blacklist = [
    'fuck',
    'shit',
    'ass',
    'bitch',
    'bastard',
    'damn',
    'crap',
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
    'kill',
    'murder',
    'suicide',
    'drugs',
    'cocaine',
    'heroin',
    // Japanese profanity
    'くそ',
    'バカ',
    'ばか',
    'アホ',
    'あほ',
    'きちく',
    'ちくしょう',
  ];

  /// Returns true if the text contains inappropriate words.
  static bool containsInappropriate(String text) {
    final lower = text.toLowerCase();
    for (final word in _blacklist) {
      if (lower.contains(word.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  /// Replaces inappropriate words with ***.
  static String filterText(String text) {
    String result = text;
    for (final word in _blacklist) {
      final regex = RegExp(
        RegExp.escape(word),
        caseSensitive: false,
        unicode: true,
      );
      result = result.replaceAllMapped(regex, (match) {
        return '*' * match.group(0)!.length;
      });
    }
    return result;
  }

  /// Adds a custom word to the runtime blacklist (not persisted).
  static final List<String> _runtimeBlacklist = [];

  static void addToBlacklist(String word) {
    if (!_runtimeBlacklist.contains(word.toLowerCase())) {
      _runtimeBlacklist.add(word.toLowerCase());
    }
  }

  static bool containsInappropriateWithRuntime(String text) {
    if (containsInappropriate(text)) return true;
    final lower = text.toLowerCase();
    for (final word in _runtimeBlacklist) {
      if (lower.contains(word)) return true;
    }
    return false;
  }
}
