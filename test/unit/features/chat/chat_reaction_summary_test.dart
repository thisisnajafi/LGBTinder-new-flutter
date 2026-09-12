import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_reaction_summary.dart';

void main() {
  group('ChatReactionSummary.parseCounts', () {
    test('reads emoji map and drops zeros', () {
      final counts = ChatReactionSummary.parseCounts({
        '❤️': 2,
        '👍': '1',
        '😂': 0,
      });
      expect(counts, {'❤️': 2, '👍': 1});
    });

    test('reads list of emoji/count maps', () {
      final counts = ChatReactionSummary.parseCounts([
        {'emoji': '😮', 'count': 3},
        {'emoji': '😢'},
      ]);
      expect(counts, {'😮': 3, '😢': 1});
    });
  });

  group('ChatReactionSummary.toggle', () {
    test('adds then unreacts the same emoji', () {
      const empty = ChatReactionSummary();
      final added = empty.toggle('❤️');
      expect(added.mine, '❤️');
      expect(added.counts, {'❤️': 1});

      final removed = added.toggle('❤️');
      expect(removed.mine, isNull);
      expect(removed.counts, isEmpty);
    });

    test('replaces a different emoji', () {
      const current = ChatReactionSummary(counts: {'❤️': 1}, mine: '❤️');
      final next = current.toggle('👍');
      expect(next.mine, '👍');
      expect(next.counts, {'👍': 1});
    });
  });

  group('ChatReactionSummary.applyEvent', () {
    test('keeps local mine when someone else reacts', () {
      const current = ChatReactionSummary(counts: {'❤️': 1}, mine: '❤️');
      final next = ChatReactionSummary.applyEvent(
        current: current,
        reactorId: 2,
        currentUserId: 1,
        counts: {'❤️': 1, '😂': 1},
        emoji: '😂',
        reacted: true,
      );
      expect(next.mine, '❤️');
      expect(next.counts, {'❤️': 1, '😂': 1});
    });

    test('clears mine when the current user unreacts', () {
      const current = ChatReactionSummary(counts: {'👍': 1}, mine: '👍');
      final next = ChatReactionSummary.applyEvent(
        current: current,
        reactorId: 9,
        currentUserId: 9,
        counts: const {},
        emoji: '👍',
        reacted: false,
      );
      expect(next.mine, isNull);
      expect(next.counts, isEmpty);
    });
  });
}
