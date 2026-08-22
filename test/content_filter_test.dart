import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_game/core/utils/content_filter.dart';

void main() {
  group('ContentFilter — ordinary strategy text must pass', () {
    // Every one of these was rejected by the old substring matcher.
    const allowed = <String>[
      'I will assault the left flank at dawn.',      // ass
      'Mass my troops and pass through the valley.', // ass x2
      'A class formation of heavy infantry.',        // ass
      'Harass their supply lines with cavalry.',     // ass
      'Fire from the cockpit at close range.',       // cock
      'March the army through Wessex and Essex.',    // sex
      'Kill the enemy commander in the first charge.', // kill
      'Use skill and discipline to hold the line.',  // kill
      'The ambassador negotiates a ceasefire.',      // ass
      'Advance across the grass toward the ridge.',  // ass
    ];

    for (final text in allowed) {
      test('allows: "$text"', () {
        expect(ContentFilter.containsInappropriate(text), isFalse);
      });
    }
  });

  group('ContentFilter — Japanese strategy text must pass', () {
    const allowed = <String>[
      '敵を殺すつもりで突撃する。',   // 殺す is military vocabulary here
      '攻撃するばかりで守りが薄い。', // ばかり contains ばか
      'ばからしいほど単純な作戦だ。', // ばからしい contains ばか
    ];

    for (final text in allowed) {
      test('allows: "$text"', () {
        expect(ContentFilter.containsInappropriate(text), isFalse);
      });
    }
  });

  group('ContentFilter — genuine abuse is still blocked', () {
    const blocked = <String>[
      'fuck this game',
      'you are a bitch',
      'what a retard',
      'ばか野郎',
      'このアホが',
      'ちくしょう',
    ];

    for (final text in blocked) {
      test('blocks: "$text"', () {
        expect(ContentFilter.containsInappropriate(text), isTrue);
      });
    }
  });

  group('filterText', () {
    test('masks only the offending word', () {
      expect(ContentFilter.filterText('fuck the assault'), '**** the assault');
    });

    test('leaves clean strategy text untouched', () {
      const s = 'Assault the pass with massed cavalry.';
      expect(ContentFilter.filterText(s), s);
    });
  });

  group('runtime blacklist', () {
    test('added words match on word boundaries only', () {
      ContentFilter.addToBlacklist('zorp');
      expect(ContentFilter.containsInappropriateWithRuntime('a zorp appears'), isTrue);
      expect(ContentFilter.containsInappropriateWithRuntime('zorpington guards'), isFalse);
    });
  });
}
