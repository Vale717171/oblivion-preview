import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/game/garden/garden_module.dart';
import 'package:archive_of_oblivion/features/parser/parser_state.dart';

GardenStateView _state({
  required String nodeId,
  Set<String> puzzles = const {},
  Map<String, int> counters = const {},
  List<String> inventory = const ['notebook'],
  int psychoWeight = 0,
}) {
  return GardenStateView(
    nodeId: nodeId,
    completedPuzzles: puzzles,
    puzzleCounters: counters,
    inventory: inventory,
    psychoWeight: psychoWeight,
  );
}

void main() {
  group('Garden arrival', () {
    test('first entry from the threshold lands with slower weight', () {
      final arrival = GardenModule.onEnterNode(
        fromNode: 'la_soglia',
        destNode: 'garden_portico',
        state: _state(nodeId: 'la_soglia'),
      );

      expect(arrival, isNotNull);
      expect(arrival!.newNode, 'garden_portico');
      expect(arrival.completePuzzle, GardenModule.arrivalPuzzle);
      expect(arrival.revealMode, TextRevealMode.slow);
      expect(arrival.narrativeText, contains('does not welcome you with beauty first'));
    });
  });

  group('Garden leaf arrangements', () {
    const preparedPuzzles = {'garden_columns_read', 'garden_leaves_read'};

    test('distinguishes unprepared, alternative, and correct orders', () {
      final unprepared = GardenModule.handleArrange(
        cmd: const ParsedCommand(
          verb: CommandVerb.arrange,
          args: [
            'prudence',
            'friendship',
            'pleasure',
            'simplicity',
            'absence',
            'tranquillity',
            'memory'
          ],
          rawInput:
              'arrange leaves prudence friendship pleasure simplicity absence tranquillity memory',
        ),
        state: _state(nodeId: 'garden_cypress'),
      );
      expect(unprepared, isNotNull);
      expect(unprepared!.narrativeText, contains('Read both before arranging'));
      expect(unprepared.completePuzzle, isNull);

      final alternative = GardenModule.handleArrange(
        cmd: const ParsedCommand(
          verb: CommandVerb.arrange,
          args: [
            'friendship',
            'prudence',
            'pleasure',
            'simplicity',
            'absence',
            'tranquillity',
            'memory'
          ],
          rawInput:
              'arrange leaves friendship prudence pleasure simplicity absence tranquillity memory',
        ),
        state: _state(nodeId: 'garden_cypress', puzzles: preparedPuzzles),
      );
      expect(alternative, isNotNull);
      expect(
          alternative!.narrativeText, contains('coherent, almost persuasive'));
      expect(alternative.completePuzzle, isNull);

      final correct = GardenModule.handleArrange(
        cmd: const ParsedCommand(
          verb: CommandVerb.arrange,
          args: [
            'prudence',
            'friendship',
            'pleasure',
            'simplicity',
            'absence',
            'tranquillity',
            'memory'
          ],
          rawInput:
              'arrange leaves prudence friendship pleasure simplicity absence tranquillity memory',
        ),
        state: _state(nodeId: 'garden_cypress', puzzles: preparedPuzzles),
      );
      expect(correct, isNotNull);
      expect(correct!.completePuzzle, 'leaves_arranged');
    });
  });

  group('Garden fountain patience', () {
    test('resists spam until reflection checkpoints are met', () {
      final firstWait = GardenModule.handleWait(
        state: _state(nodeId: 'garden_fountain'),
      );
      expect(firstWait, isNotNull);
      expect(firstWait!.incrementCounter, 'fountain_waits');

      final blockedSecond = GardenModule.handleWait(
        state: _state(
            nodeId: 'garden_fountain', counters: const {'fountain_waits': 1}),
      );
      expect(blockedSecond, isNotNull);
      expect(blockedSecond!.incrementCounter, isNull);
      expect(blockedSecond.narrativeText,
          contains('does not reward repetition alone'));

      final unlockedSecond = GardenModule.handleWait(
        state: _state(
          nodeId: 'garden_fountain',
          puzzles: const {'fountain_reflection_1'},
          counters: const {'fountain_waits': 1},
        ),
      );
      expect(unlockedSecond, isNotNull);
      expect(unlockedSecond!.incrementCounter, 'fountain_waits');

      final completion = GardenModule.handleWait(
        state: _state(
          nodeId: 'garden_fountain',
          puzzles: const {'fountain_reflection_1', 'fountain_reflection_2'},
          counters: const {'fountain_waits': 2},
        ),
      );
      expect(completion, isNotNull);
      expect(completion!.completePuzzle, 'fountain_waited');
    });
  });

  group('Garden stele evaluation', () {
    test('distinguishes generic from substantial inscriptions', () {
      final generic = GardenModule.handleWrite(
        cmd: const ParsedCommand(
          verb: CommandVerb.write,
          args: ['friendship'],
          rawInput: 'write friendship',
        ),
        state: _state(nodeId: 'garden_stelae'),
      );
      expect(generic, isNotNull);
      expect(generic!.completePuzzle, isNull);
      expect(generic.narrativeText, contains('rejects slogans'));

      final substantial = GardenModule.handleWrite(
        cmd: const ParsedCommand(
          verb: CommandVerb.write,
          args: [
            'friendship',
            'asked',
            'me',
            'to',
            'return',
            'to',
            'that',
            'winter',
            'street',
            'and',
            'apologize',
            'by',
            'name'
          ],
          rawInput:
              'write friendship asked me to return to that winter street and apologize by name',
        ),
        state: _state(nodeId: 'garden_stelae'),
      );
      expect(substantial, isNotNull);
      expect(substantial!.completePuzzle, 'stele_inscribed');
    });
  });

  group('Garden statue relinquishment', () {
    test('enforces triadic relinquishment before Ataraxia', () {
      final blocked = GardenModule.handleDeposit(
        state: _state(
          nodeId: 'garden_grove',
          puzzles: const {'alcove_pleasures_walked', 'alcove_pains_walked'},
          inventory: const ['notebook', 'coin'],
        ),
      );
      expect(blocked, isNotNull);
      expect(blocked!.completePuzzle, isNull);
      expect(
        blocked.narrativeText,
        contains('Only one relinquishment remains'),
      );

      final success = GardenModule.handleDeposit(
        state: _state(
          nodeId: 'garden_grove',
          puzzles: const {'alcove_pleasures_walked', 'alcove_pains_walked'},
          inventory: const ['notebook', 'coin', 'mirror shard'],
        ),
      );
      expect(success, isNotNull);
      expect(success!.completePuzzle, 'garden_complete');
      expect(success.grantItem, 'ataraxia');
      expect(success.clearInventoryOnDeposit, isTrue);
      expect(success.feedbackKind, FeedbackKind.majorRevelation);
      expect(success.revealMode, TextRevealMode.wordByWord);
      expect(success.preDisplayPause, const Duration(seconds: 3));
      expect(success.narrativeText, contains('the grove asks nothing of you'));
    });

    test('offer feedback makes the remaining relinquishments legible', () {
      final firstOffer = GardenModule.handleOffer(
        cmd: const ParsedCommand(
          verb: CommandVerb.offer,
          args: ['stylus'],
          rawInput: 'offer stylus',
        ),
        state: _state(
          nodeId: 'garden_grove',
          inventory: const ['stylus', 'mirror shard'],
        ),
      );

      expect(firstOffer, isNotNull);
      expect(firstOffer!.completePuzzle, 'garden_offer_useful');
      expect(firstOffer.narrativeText, contains('Still required:'));

      final secondOffer = GardenModule.handleOffer(
        cmd: const ParsedCommand(
          verb: CommandVerb.offer,
          args: ['mirror shard'],
          rawInput: 'offer mirror shard',
        ),
        state: _state(
          nodeId: 'garden_grove',
          puzzles: const {'garden_offer_useful'},
          inventory: const ['mirror shard', 'notebook', 'coin'],
        ),
      );

      expect(secondOffer, isNotNull);
      expect(secondOffer!.completePuzzle, 'garden_offer_pain');
      expect(secondOffer.narrativeText, contains('One relinquishment remains'));
    });
  });

  group('Garden depth model', () {
    test('deep completion requires more than obtaining Ataraxia', () {
      expect(
        GardenModule.isSurfaceComplete({'garden_complete'}),
        isTrue,
      );
      expect(
        GardenModule.isDeepComplete(
          puzzles: {'garden_complete'},
          counters: const {'depth_garden': 12},
        ),
        isFalse,
      );
      expect(
        GardenModule.isDeepComplete(
          puzzles: {
            'garden_complete',
            'garden_revisited',
            'garden_cross_sector_hint'
          },
          counters: const {'depth_garden': 6},
        ),
        isFalse,
      );
      expect(
        GardenModule.isDeepComplete(
          puzzles: {
            'garden_complete',
            'garden_revisited',
            'garden_cross_sector_hint'
          },
          counters: const {'depth_garden': 7},
        ),
        isTrue,
      );
    });
  });
}
