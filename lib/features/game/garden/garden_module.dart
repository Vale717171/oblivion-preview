import '../game_node.dart';
import '../../parser/parser_state.dart';

class GardenStateView {
  final String nodeId;
  final Set<String> completedPuzzles;
  final Map<String, int> puzzleCounters;
  final List<String> inventory;
  final int psychoWeight;

  const GardenStateView({
    required this.nodeId,
    required this.completedPuzzles,
    required this.puzzleCounters,
    required this.inventory,
    required this.psychoWeight,
  });
}

class GardenModule {
  static const String arrivalPuzzle = 'garden_arrival';
  static const String surfacePuzzle = 'garden_complete';
  static const String surfaceMarkerPuzzle = 'garden_surface_complete';
  static const String deepMarkerPuzzle = 'garden_deep_complete';

  static const Set<String> _gardenUsefulItems = {
    'coin',
    'compass',
    'lamp',
    'stylus',
  };

  static const Set<String> _gardenIdentityItems = {
    'book',
    'page',
  };

  static const Set<String> _gardenPainItems = {
    'rusted key',
    'key',
    'mirror shard',
    'earth',
  };

  static const Set<String> _gardenSteleBondTerms = {
    'friendship',
    'friend',
    'friends',
    'companion',
    'companionship',
  };

  static const Set<String> _gardenSteleGenericPhrases = {
    'friendship',
    'be good',
    'be kind',
    'love wins',
    'all is one',
    'live laugh love',
    'peace and love',
  };

  static const Set<String> _gardenSteleConcreteTerms = {
    'friend',
    'name',
    'door',
    'winter',
    'summer',
    'grave',
    'voice',
    'hand',
    'letter',
    'street',
    'house',
    'room',
  };

  static const Set<String> _gardenSteleCostTerms = {
    'risk',
    'lose',
    'loss',
    'cost',
    'hurt',
    'forgive',
    'fear',
    'ashamed',
    'wait',
    'remain',
    'return',
    'apologize',
    'apologise',
  };

  static const Map<String, Map<String, String>> exitGates = {
    'garden_cypress': {'north': 'leaves_arranged'},
    'garden_fountain': {'north': 'fountain_waited'},
    'garden_stelae': {'north': 'stele_inscribed'},
  };

  static const Map<String, String> gateHints = {
    'leaves_arranged':
        'The fallen leaves bar your way. Their disorder is the lock.\n\n'
            'Hint: read columns and leaves, then arrange leaves.',
    'fountain_waited':
        'The passage north is not yet open. Something is still arriving.\n\n'
            'Hint: wait, but not mechanically. Attend to fountain and dust between turnings.',
    'stele_inscribed':
        'The grove will not receive you. The blank stele stands in judgement.\n\n'
            'Hint: the missing maxim is friendship. Try: inscribe friendship.',
  };

  static const Map<String, NodeDef> roomDefinitions = {
    'garden_portico': NodeDef(
      title: 'The Garden of Epicurus — Portico',
      description: 'The amber door opens onto stillness.\n\n'
          'A portico of worn stone columns. Inscriptions run along each shaft. '
          'A path of pale stone leads north through cypress trees '
          'so tall their crowns disappear.',
      exits: {
        'north': 'garden_cypress',
        'south': 'la_soglia',
        'back': 'la_soglia'
      },
      examines: {
        'columns': 'Each column bears a single word:\n'
            'ataraxia — aponia — philia — phronesis.\n'
            'The order is not alphabetical.',
        'path': 'Cypress trees stand like sentinels.',
      },
    ),
    'garden_cypress': NodeDef(
      title: 'Cypress Avenue',
      description: 'A long avenue of cypress trees.\n\n'
          'Leaves have fallen across the stone path, each perfectly preserved, '
          'each bearing a single word in faded ink. They are not arranged in '
          'any obvious order.\n\n'
          'To the north, the avenue opens onto a dry fountain.',
      exits: {'north': 'garden_fountain', 'south': 'garden_portico'},
      examines: {
        'leaves': 'You crouch and read the words:\n'
            'pleasure — friendship — prudence — tranquillity — '
            'memory — simplicity — absence.\n\n'
            'They belong to an order. You sense it, but cannot yet name it.',
        'trees':
            'Impossibly tall. Their roots disappear into ground with no depth.',
        'words': 'Seven words. One leaf is slightly darker than the rest.',
      },
    ),
    'garden_fountain': NodeDef(
      title: 'Dry Fountain',
      description: 'A stone fountain, long dry.\n\n'
          'Its basin holds only fine grey dust. '
          'Carved along the rim: "That which satisfies the body is sufficient '
          'for happiness." The stone is worn smooth by many hands.\n\n'
          'To the north: a circle of standing stones.',
      exits: {'north': 'garden_stelae', 'south': 'garden_cypress'},
      examines: {
        'fountain': 'Empty. Worn smooth by many hands before yours.',
        'dust': 'Fine as ash. Breathed on, it forms brief illegible shapes.',
        'inscription':
            '"That which satisfies the body is sufficient for happiness."',
      },
    ),
    'garden_stelae': NodeDef(
      title: 'Circle of Stelae',
      description:
          'A circle of standing stones, each inscribed with a maxim.\n\n'
          'You count eleven. The twelfth stele is blank — its surface '
          'smooth and waiting. A stylus lies at its base.\n\n'
          'To the south, the dry fountain. To the north, the grove.',
      exits: {'north': 'garden_grove', 'south': 'garden_fountain'},
      examines: {
        'stelae': 'Eleven maxims. The eleventh: "Death is nothing to us." '
            'The twelfth is blank.',
        'blank stele': 'Smooth stone. A stylus at its base. '
            'The missing maxim belongs to those who have understood the others.',
        'stylus': 'A simple instrument. It waits.',
        'maxims': 'Pleasure. Death. The gods. Pain. Virtue. '
            'The soul. Justice. Friendship. Wisdom. Society. The self. '
            'The twelfth stands empty.',
      },
      takeable: {'stylus'},
    ),
    'garden_grove': NodeDef(
      title: "Central Grove — Epicurus' Statue",
      description: 'A clearing of ancient trees.\n\n'
          'At the centre: a marble statue of a seated figure. '
          'Hands open on its knees, palms upward, holding nothing. '
          'The expression is one of complete, undemonstrative peace.\n\n'
          'To the east and west: two alcoves in the treeline.\n'
          'To the south: the circle of stelae.',
      exits: {
        'east': 'garden_alcove_pleasures',
        'west': 'garden_alcove_pains',
        'south': 'garden_stelae',
      },
      examines: {
        'statue': 'The hands hold nothing. The face asks nothing. '
            'It has been waiting for you specifically.',
        'trees': 'Ancient. Still. Their roots break the stone path.',
        'clearing': 'No wind. Sound arrives slightly after it should.',
      },
    ),
    'garden_alcove_pleasures': NodeDef(
      title: 'Alcove of Pleasures',
      description: 'A small alcove off the grove.\n\n'
          'Objects on low shelves: a coin worn smooth, '
          'a leather-bound book with gilded edges, a brass compass, '
          'a small oil lamp. Each is beautiful. Each gives you the '
          'faint sense that acquiring it would be a mistake.\n\n'
          'A linden tree grows in the corner. Its flowers are open.',
      exits: {'west': 'garden_grove', 'back': 'garden_grove'},
      examines: {
        'coin':
            'A coin from no era you recognise. Heads: a face. Tails: the same face, older.',
        'book': 'The gilded title has worn away. Inside, handwriting '
            'you almost recognise as your own.',
        'compass':
            'The needle points in a direction that changes every time you look away.',
        'lamp': 'The flame is lit. You do not remember lighting it.',
        'linden':
            'A linden tree in full flower. The scent is very faint — then overwhelming.',
        'flowers':
            'Not just flowers. Something older. A door, half-open. A specific afternoon.',
      },
      takeable: {'coin', 'book', 'compass', 'lamp'},
    ),
    'garden_alcove_pains': NodeDef(
      title: 'Alcove of Pains',
      description: 'A small alcove off the grove.\n\n'
          'Objects: a rusted key, a torn page, '
          'a cracked mirror shard, a handful of dried earth.\n\n'
          'They are less beautiful than those across the grove. '
          'That, somehow, makes them harder to leave.',
      exits: {'east': 'garden_grove', 'back': 'garden_grove'},
      examines: {
        'key': 'Rusted. You do not know what it opens. '
            'You suspect the lock no longer exists.',
        'page': 'A single torn page. One word you understand: remember.',
        'mirror shard': 'Your reflection is correct. '
            'That is somehow the most unsettling thing about this place.',
        'earth': 'Dry. Dark. The smell of the end of summer.',
      },
      takeable: {'key', 'page', 'mirror shard', 'earth'},
    ),
  };

  static bool isGardenNode(String nodeId) => nodeId.startsWith('garden_');

  static bool _containsToken(String text, String token) =>
      RegExp('\\b${RegExp.escape(token)}\\b').hasMatch(text);

  static bool _matchesCategoryToken(String item, String token) =>
      item == token || _containsToken(item, token);

  static bool _inventoryHasCategoryItem(
    Iterable<String> inventory,
    Set<String> category,
  ) {
    for (final item in inventory) {
      final lower = item.toLowerCase();
      for (final token in category) {
        if (_matchesCategoryToken(lower, token)) return true;
      }
    }
    return false;
  }

  static bool steleInscriptionLooksSpecific(String inscription) {
    final text = inscription.toLowerCase().trim();
    if (text.isEmpty) return false;
    final words =
        text.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();
    if (words.length < 4) return false;

    if (_gardenSteleGenericPhrases.contains(text)) return false;
    final hasBondTerm = _gardenSteleBondTerms.any((term) {
      return term.contains(' ')
          ? text.contains(term)
          : _containsToken(text, term);
    });
    if (!hasBondTerm) return false;

    final hasConcrete = _gardenSteleConcreteTerms.any(text.contains);
    final hasCost = _gardenSteleCostTerms.any(text.contains);
    final hasFirstPerson = _containsToken(text, 'i') ||
        _containsToken(text, 'me') ||
        _containsToken(text, 'my') ||
        _containsToken(text, 'mine');

    return (hasConcrete && (hasCost || hasFirstPerson)) ||
        (hasCost && hasFirstPerson);
  }

  static Map<String, bool> relinquishmentCoverage(Iterable<String> inventory) {
    return {
      'useful': _inventoryHasCategoryItem(inventory, _gardenUsefulItems),
      'identity': _inventoryHasCategoryItem(inventory, _gardenIdentityItems),
      'pain': _inventoryHasCategoryItem(inventory, _gardenPainItems),
    };
  }

  static bool isSurfaceComplete(Set<String> puzzles) =>
      puzzles.contains(surfacePuzzle);

  static bool isDeepComplete({
    required Set<String> puzzles,
    required Map<String, int> counters,
  }) {
    final depth = counters['depth_garden'] ?? 0;
    return isSurfaceComplete(puzzles) &&
        puzzles.contains('garden_revisited') &&
        puzzles.contains('garden_cross_sector_hint') &&
        depth >= 7;
  }

  static Set<String> completionMarkers({
    required Set<String> puzzles,
    required Map<String, int> counters,
  }) {
    final adds = <String>{};
    if (isSurfaceComplete(puzzles) && !puzzles.contains(surfaceMarkerPuzzle)) {
      adds.add(surfaceMarkerPuzzle);
    }
    if (isDeepComplete(puzzles: puzzles, counters: counters) &&
        !puzzles.contains(deepMarkerPuzzle)) {
      adds.add(deepMarkerPuzzle);
      adds.add('sys_deep_garden');
    }
    return adds;
  }

  static EngineResponse? onEnterNode({
    required String fromNode,
    required String destNode,
    required GardenStateView state,
  }) {
    if (destNode == 'garden_portico' &&
        fromNode == 'la_soglia' &&
        !state.completedPuzzles.contains(arrivalPuzzle)) {
      return const EngineResponse(
        narrativeText: 'The Garden of Epicurus — Portico\n\n'
            'The eastern door yields to a quieter air.\n\n'
            'Stone, cypress, distance. The place does not welcome you with beauty first, but with measure.\n\n'
            'Ahead, the path waits without urging. Behind you, the Soglia has already receded.',
        newNode: 'garden_portico',
        needsDemiurge: true,
        completePuzzle: arrivalPuzzle,
        revealMode: TextRevealMode.slow,
      );
    }
    if (destNode == 'garden_portico' &&
        state.completedPuzzles.contains(surfacePuzzle) &&
        !state.completedPuzzles.contains('garden_revisited')) {
      return const EngineResponse(
        narrativeText: 'Portico (returned)\n\n'
            'The same columns, but a different silence.\n\n'
            'The words no longer read like doctrine. They read like memory.\n\n'
            'In the distance, from the eastern wing, a measured metallic tone answers your step.',
        newNode: 'garden_portico',
        needsDemiurge: true,
        completePuzzle: 'garden_revisited',
      );
    }
    return null;
  }

  static EngineResponse? handleExamine({
    required String nodeId,
    required String target,
    required GardenStateView state,
  }) {
    if (nodeId == 'garden_portico' && target.contains('column')) {
      return const EngineResponse(
        narrativeText: 'Each column bears one word:\n'
            'ataraxia — aponia — philia — phronesis.\n\n'
            'The sequence feels like instruction, not decoration.',
        completePuzzle: 'garden_columns_read',
        needsDemiurge: true,
      );
    }
    if (nodeId == 'garden_cypress' && target.contains('leaves')) {
      return const EngineResponse(
        narrativeText: 'You kneel among the leaves and read them slowly:\n'
            'pleasure — friendship — prudence — tranquillity — memory — simplicity — absence.\n\n'
            'It is not a random list. It is a philosophy waiting for order.',
        completePuzzle: 'garden_leaves_read',
        needsDemiurge: true,
      );
    }
    if (nodeId == 'garden_fountain' &&
        (target.contains('fountain') ||
            target.contains('dust') ||
            target.contains('inscription'))) {
      final waits = state.puzzleCounters['fountain_waits'] ?? 0;
      if (waits >= 2 &&
          !state.completedPuzzles.contains('fountain_reflection_2')) {
        return const EngineResponse(
          narrativeText: 'You trace the rim with your fingertips.\n\n'
              'The dust is no longer inert. It answers pressure with a line that vanishes at once.\n\n'
              'The room asks for waiting with attention, not repetition.',
          completePuzzle: 'fountain_reflection_2',
          needsDemiurge: true,
        );
      }
      if (waits >= 1 &&
          !state.completedPuzzles.contains('fountain_reflection_1')) {
        return const EngineResponse(
          narrativeText:
              'Looking closely, you notice the dust drift against no wind.\n\n'
              'Patience here is not passivity. It is participation.',
          completePuzzle: 'fountain_reflection_1',
          needsDemiurge: true,
        );
      }
    }

    if (nodeId == 'garden_alcove_pains' &&
        target.contains('mirror') &&
        target.contains('shard')) {
      if (state.psychoWeight > 0) {
        return const EngineResponse(
          narrativeText:
              'You look into the shard, but what you are still carrying crowds the surface.\n\n'
              'Set things down first. Pain is clearer when it is not mixed with grasping.',
        );
      }
      if (state.completedPuzzles.contains('alcove_pains_walked')) {
        return const EngineResponse(
          narrativeText:
              'You have already met the shard without claiming it. The alcove has nothing more to demand.',
        );
      }
      return const EngineResponse(
        narrativeText:
            'You lift the shard just enough to catch your face and then set it back.\n\n'
            'The reflection is exact, and because it is exact it does not accuse you. It only remains.\n\n'
            'You leave the shard where it is. That is the whole action.\n\n'
            'Something in the alcove releases.',
        needsDemiurge: true,
        lucidityDelta: 7,
        completePuzzle: 'alcove_pains_walked',
      );
    }

    if (nodeId == 'la_soglia' &&
        target.contains('pedestal') &&
        state.completedPuzzles.contains(surfacePuzzle) &&
        !state.completedPuzzles.contains('garden_cross_sector_hint')) {
      return const EngineResponse(
        narrativeText:
            'Ataraxia rests in your hand, and the eastern door answers with a colder hum.\n\n'
            'Stillness has altered measure somewhere else in the Archive.',
        completePuzzle: 'garden_cross_sector_hint',
        needsDemiurge: true,
      );
    }
    return null;
  }

  static EngineResponse? handleArrange({
    required ParsedCommand cmd,
    required GardenStateView state,
  }) {
    if (state.nodeId != 'garden_cypress') {
      return null;
    }
    if (state.completedPuzzles.contains('leaves_arranged')) {
      return const EngineResponse(
        narrativeText:
            'The leaves are already in their correct order. The path north is open.',
      );
    }
    if (cmd.args.isEmpty) {
      return const EngineResponse(
        narrativeText: 'The leaves wait for a single decisive gesture.\n\n'
            'Hint: arrange leaves.',
      );
    }
    final prepared = state.completedPuzzles.contains('garden_columns_read') &&
        state.completedPuzzles.contains('garden_leaves_read');
    if (!prepared) {
      return const EngineResponse(
        narrativeText:
            'You begin to order the leaves, but the sequence refuses to hold.\n\n'
            'The path asks for two memories at once: what the columns taught and what the leaves repeat.\n\n'
            'Read both before arranging.',
      );
    }

    final targetsLeaves =
        cmd.args.contains('leaf') || cmd.args.contains('leaves');
    if (targetsLeaves) {
      return const EngineResponse(
        narrativeText: 'You gather the leaves into one patient motion.\n\n'
            'The darker leaf finds its place first; the others follow as though they had been waiting to remember.\n\n'
            'prudence — friendship — pleasure — simplicity — absence — tranquillity — memory.\n\n'
            'The path north opens.',
        needsDemiurge: true,
        lucidityDelta: 10,
        completePuzzle: 'leaves_arranged',
        audioTrigger: 'calm',
      );
    }

    return const EngineResponse(
      narrativeText: 'The avenue does not answer that gesture.\n\n'
          'It is the leaves themselves that must be brought into order.\n\n'
          'Try: arrange leaves.',
    );
  }

  static EngineResponse? handleWait({required GardenStateView state}) {
    if (state.nodeId != 'garden_fountain') return null;

    if (state.completedPuzzles.contains('fountain_waited')) {
      return const EngineResponse(
        narrativeText:
            'The fountain has already given what it had. The path north is open.',
      );
    }
    final waits = (state.puzzleCounters['fountain_waits'] ?? 0) + 1;
    if (waits == 2 &&
        !state.completedPuzzles.contains('fountain_reflection_1')) {
      return const EngineResponse(
        narrativeText:
            'You wait again, but the fountain remains perfectly mute.\n\n'
            'It does not reward repetition alone.\n\n'
            'Study the dust or the inscription, then return to stillness.',
      );
    }
    if (waits >= 3 &&
        !state.completedPuzzles.contains('fountain_reflection_2')) {
      return const EngineResponse(
        narrativeText:
            'Your patience hardens into routine, and the room closes around it.\n\n'
            'Attend once more to what the fountain is showing before you wait again.',
      );
    }
    if (waits < 3) {
      return EngineResponse(
        narrativeText: waits == 1
            ? 'You wait.\n\nNothing comes. The dust settles back into itself.'
            : 'You wait again.\n\nA faint condensation forms at the lip of the fountain.',
        incrementCounter: 'fountain_waits',
      );
    }
    return const EngineResponse(
      narrativeText:
          'A third time — and in the silence, a single drop of condensation '
          'slides down the stone and disappears into the dust.\n\n'
          'You have learned something. You are not sure what.\n\n'
          'The path north opens.',
      needsDemiurge: true,
      incrementCounter: 'fountain_waits',
      completePuzzle: 'fountain_waited',
      lucidityDelta: 3,
    );
  }

  static EngineResponse? handleWalk({
    required ParsedCommand cmd,
    required GardenStateView state,
  }) {
    final mode = cmd.args.join(' ');
    if (state.nodeId == 'garden_alcove_pleasures' && mode == 'through') {
      return const EngineResponse(
        narrativeText: 'Walking is not enough here.\n\n'
            'The alcove wants one act of attention without possession.\n\n'
            'Try: smell linden.',
      );
    }
    if (state.nodeId == 'garden_alcove_pains' && mode == 'through') {
      return const EngineResponse(
        narrativeText: 'Walking is not enough here either.\n\n'
            'This alcove wants recognition, not avoidance.\n\n'
            'Try: examine mirror shard.',
      );
    }
    return null;
  }

  static EngineResponse? handleWrite({
    required ParsedCommand cmd,
    required GardenStateView state,
  }) {
    if (state.nodeId != 'garden_stelae') return null;

    if (state.psychoWeight > 0) {
      return const EngineResponse(
        narrativeText: 'The blank stele\'s surface is illegible to you.\n\n'
            'The burden you carry clouds your perception. '
            'The maxim cannot be inscribed by one who has grasped at things.',
      );
    }
    if (state.completedPuzzles.contains('stele_inscribed')) {
      return const EngineResponse(
          narrativeText: 'The stele is already inscribed.');
    }
    if (cmd.args.isEmpty) {
      return const EngineResponse(
        narrativeText:
            'Inscribe what? The stylus is ready, but the maxim must be supplied.\n\n'
            'The blank stele is waiting for the principle the others lead toward.\n\n'
            'Try: inscribe friendship.',
      );
    }
    final inscription = cmd.args.join(' ').toLowerCase();
    final simpleFriendshipCommand = cmd.args.length == 1 &&
        (inscription == 'friendship' || inscription == 'philia');

    if (simpleFriendshipCommand) {
      return const EngineResponse(
        narrativeText: 'You inscribe only one word: friendship.\n\n'
            'The stylus stops there, but the stone does not. The rest of the maxim arrives as if it had merely been waiting for permission.\n\n'
            '"Of all wisdom\'s gifts to a happy life, the greatest is the possession of friendship."\n\n'
            'The twelfth stele is complete. The grove opens.',
        needsDemiurge: true,
        lucidityDelta: 12,
        completePuzzle: 'stele_inscribed',
        audioTrigger: 'calm',
      );
    }
    if (_gardenSteleGenericPhrases.contains(inscription) ||
        inscription.split(RegExp(r'\s+')).length < 4) {
      return const EngineResponse(
        narrativeText: 'The stylus scratches, then stalls.\n\n'
            'The stele is not asking for ornament. It is asking for the missing principle.\n\n'
            'Try: inscribe friendship.',
      );
    }
    if (steleInscriptionLooksSpecific(inscription)) {
      return const EngineResponse(
        narrativeText: 'The stylus moves. The words appear:\n\n'
            '"Of all wisdom\'s gifts to a happy life, '
            'the greatest is the possession of friendship."\n\n'
            'The twelfth stele is complete. The grove opens.',
        needsDemiurge: true,
        lucidityDelta: 12,
        completePuzzle: 'stele_inscribed',
        audioTrigger: 'calm',
      );
    }
    return const EngineResponse(
      narrativeText: 'The marks fade before they settle.\n\n'
          'The stone is asking for a specific and costly truth about friendship, not an abstract praise.\n\n'
          'If you want the shortest path, name the missing principle directly.\n\n'
          'Try: inscribe friendship.',
    );
  }

  static EngineResponse? handleOffer({
    required ParsedCommand cmd,
    required GardenStateView state,
  }) {
    if (state.nodeId != 'garden_grove') return null;
    final normalizedArgs = cmd.args.map((part) => part.toLowerCase()).toList();
    final joinedArgs = normalizedArgs.join(' ');
    final isFinalOfferingAlias = joinedArgs == 'relics' ||
        joinedArgs == 'all relics' ||
        joinedArgs == 'everything' ||
        joinedArgs == 'all';
    if (isFinalOfferingAlias) {
      return handleDeposit(state: state);
    }

    if (cmd.args.isEmpty) {
      return const EngineResponse(
        narrativeText:
            'Offer what? The statue receives things, not declarations.\n\n'
            'Offer one useful object, one identity-bound object, and one pain-bound object from the alcoves.',
      );
    }
    final target = cmd.args.join(' ');
    final match = state.inventory
        .where((i) => i.contains(target) || target.contains(i))
        .firstOrNull;
    if (match == null) {
      return const EngineResponse(
        narrativeText: 'You are not carrying that.',
      );
    }
    final lower = match.toLowerCase();
    final isUseful =
        _gardenUsefulItems.any((token) => _matchesCategoryToken(lower, token));
    final isIdentity = _gardenIdentityItems
        .any((token) => _matchesCategoryToken(lower, token));
    final isPain =
        _gardenPainItems.any((token) => _matchesCategoryToken(lower, token));
    if (!isUseful && !isIdentity && !isPain) {
      return const EngineResponse(
        narrativeText:
            'The statue does not answer. This is not one of the things it asks to be relinquished.',
      );
    }

    String? categoryLabel;
    String? completePuzzle;
    if (isUseful && !state.completedPuzzles.contains('garden_offer_useful')) {
      categoryLabel = 'useful';
      completePuzzle = 'garden_offer_useful';
    } else if (isIdentity &&
        !state.completedPuzzles.contains('garden_offer_identity')) {
      categoryLabel = 'identity-bound';
      completePuzzle = 'garden_offer_identity';
    } else if (isPain &&
        !state.completedPuzzles.contains('garden_offer_pain')) {
      categoryLabel = 'pain-bound';
      completePuzzle = 'garden_offer_pain';
    }
    if (categoryLabel == null) {
      return const EngineResponse(
        narrativeText:
            'The statue inclines by a fraction. It has already counted this kind of relinquishment.\n\n'
            'Offer what is still missing, or deposit what you have chosen to set down.',
      );
    }
    final remainingKinds = <String>[];
    final willHaveUseful =
        isUseful || state.completedPuzzles.contains('garden_offer_useful');
    final willHaveIdentity =
        isIdentity || state.completedPuzzles.contains('garden_offer_identity');
    final willHavePain =
        isPain || state.completedPuzzles.contains('garden_offer_pain');
    if (!willHaveUseful) remainingKinds.add('something useful');
    if (!willHaveIdentity) remainingKinds.add('something tied to who you are');
    if (!willHavePain) remainingKinds.add('something tied to pain');

    final remainingLine = switch (remainingKinds.length) {
      0 => 'Nothing essential remains withheld.',
      1 => 'One relinquishment remains: ${remainingKinds.single}.',
      _ => 'Still required: ${remainingKinds.join(', ')}.',
    };

    return EngineResponse(
      narrativeText: 'You place the $match on the stone.\n\n'
          'The open palms do not close, but the air around them changes.\n\n'
          'The Archive marks this as $categoryLabel.\n\n'
          '$remainingLine',
      completePuzzle: completePuzzle,
      needsDemiurge: true,
    );
  }

  static EngineResponse? handleDeposit({required GardenStateView state}) {
    if (state.nodeId != 'garden_grove') return null;

    if (!state.completedPuzzles.contains('alcove_pleasures_walked') ||
        !state.completedPuzzles.contains('alcove_pains_walked')) {
      return const EngineResponse(
        narrativeText: 'Something holds you back.\n\n'
            'You have not yet passed through both alcoves. '
            'The statue accepts only those who have faced pleasure and pain '
            'and chosen to walk through each without grasping.',
      );
    }

    final simulacra = {
      'ataraxia',
      'the constant',
      'the proportion',
      'the catalyst'
    };
    if (state.inventory.every(simulacra.contains)) {
      return const EngineResponse(
        narrativeText: 'You carry only what you cannot deposit.\n\n'
            'The statue\'s open hands seem to already know this.',
        needsDemiurge: true,
      );
    }

    final mundaneInventory =
        state.inventory.where((i) => !simulacra.contains(i));
    final hasUseful =
        _inventoryHasCategoryItem(mundaneInventory, _gardenUsefulItems);
    final hasIdentity =
        _inventoryHasCategoryItem(mundaneInventory, _gardenIdentityItems);
    final hasPain =
        _inventoryHasCategoryItem(mundaneInventory, _gardenPainItems);
    final offeredUseful =
        state.completedPuzzles.contains('garden_offer_useful');
    final offeredIdentity =
        state.completedPuzzles.contains('garden_offer_identity');
    final offeredPain = state.completedPuzzles.contains('garden_offer_pain');

    final missingKinds = <String>[];
    if (!(hasUseful || offeredUseful)) missingKinds.add('something useful');
    if (!(hasIdentity || offeredIdentity)) {
      missingKinds.add('something tied to who you are');
    }
    if (!(hasPain || offeredPain)) {
      missingKinds.add('something tied to pain');
    }

    if (missingKinds.isNotEmpty) {
      final missingLine = switch (missingKinds.length) {
        1 => 'Only one relinquishment remains: ${missingKinds.single}.',
        2 =>
          'Two relinquishments are still absent: ${missingKinds.join(', ')}.',
        _ => 'You are still carrying the whole shape of yourself.\n\n'
            'Three relinquishments are required: one useful thing, one identity-bound thing, one pain-bound thing.',
      };
      return EngineResponse(
        narrativeText:
            'The statue does not refuse you, but neither does it receive.\n\n'
            '$missingLine',
      );
    }

    return const EngineResponse(
      narrativeText: 'You offer the relics at the statue\'s feet.\n\n'
          'Nothing resists you. The objects settle into a loose circle, diminished now that they are no longer yours.\n\n'
          'For one long suspended breath, the grove asks nothing of you.\n\n'
          'Then, in one of the open hands: a glass sphere, perfectly empty. Ataraxia.\n\n'
          '✦ You have recovered ataraxia. The Archive marks the moment.\n\n'
          'This threshold of stillness is where the public preview ends.',
      needsDemiurge: true,
      lucidityDelta: 10,
      anxietyDelta: -20,
      audioTrigger: 'preview_closure',
      grantItem: 'ataraxia',
      completePuzzle: 'garden_complete',
      clearInventoryOnDeposit: true,
      newNode: 'preview_epilogue',
      feedbackKind: FeedbackKind.majorRevelation,
      revealMode: TextRevealMode.wordByWord,
      preDisplayPause: Duration(seconds: 3),
    );
  }
}
