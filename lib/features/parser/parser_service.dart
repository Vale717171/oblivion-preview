// lib/features/parser/parser_service.dart
// Author: GitHub Copilot — 2026-04-02
// Pure stateless parser — converts raw text input into a ParsedCommand.
// No side effects, no state. Safe to call from any context.

import 'parser_state.dart';

class ParserService {
  static const _directions = {
    'n',
    'north',
    's',
    'south',
    'e',
    'east',
    'w',
    'west'
  };
  static const List<String> _stopWords = [
    'the',
    'a',
    'an',
    'at',
    'to',
    'into',
    'on',
    'up',
    'with',
    'from',
    'by',
    'for',
    'in',
    'of',
    'toward',
    'towards',
    'through',
    'under',
    'against',
    'between',
    'among',
  ];

  static const Map<String, CommandVerb> _verbAliases = {
    'go': CommandVerb.go,
    'move': CommandVerb.go,
    'head': CommandVerb.go,
    'travel': CommandVerb.go,
    'walk': CommandVerb.walk,
    'examine': CommandVerb.examine,
    'look': CommandVerb.examine,
    'look at': CommandVerb.examine,
    'inspect': CommandVerb.examine,
    'read': CommandVerb.examine,
    'take': CommandVerb.take,
    'get': CommandVerb.take,
    'grab': CommandVerb.take,
    'pick': CommandVerb.take,
    'pick up': CommandVerb.take,
    'collect': CommandVerb.collect,
    'drop': CommandVerb.drop,
    'put': CommandVerb.drop,
    'leave': CommandVerb.drop,
    'place': CommandVerb.drop,
    'discard': CommandVerb.drop,
    'release': CommandVerb.drop,
    'set down': CommandVerb.drop,
    'use': CommandVerb.use,
    'deposit': CommandVerb.deposit,
    'wait': CommandVerb.wait,
    'smell': CommandVerb.smell,
    'sniff': CommandVerb.smell,
    'taste': CommandVerb.taste,
    'lick': CommandVerb.taste,
    'arrange': CommandVerb.arrange,
    'order': CommandVerb.arrange,
    'combine': CommandVerb.combine,
    'merge': CommandVerb.combine,
    'press': CommandVerb.press,
    'push': CommandVerb.press,
    'offer': CommandVerb.offer,
    'give': CommandVerb.offer,
    'relinquish': CommandVerb.offer,
    'surrender': CommandVerb.offer,
    'write': CommandVerb.write,
    'inscribe': CommandVerb.write,
    'describe': CommandVerb.write,
    'paint': CommandVerb.write,
    'draw': CommandVerb.write,
    'construct': CommandVerb.write,
    'measure': CommandVerb.measure,
    'calibrate': CommandVerb.calibrate,
    'invert': CommandVerb.invert,
    'reverse': CommandVerb.invert,
    'confirm': CommandVerb.confirm,
    'yes': CommandVerb.confirm,
    'break': CommandVerb.breakObj,
    'shatter': CommandVerb.breakObj,
    'smash': CommandVerb.breakObj,
    'blow': CommandVerb.blow,
    'set': CommandVerb.setParam,
    'adjust': CommandVerb.setParam,
    'drink': CommandVerb.drink,
    'sip': CommandVerb.drink,
    'stir': CommandVerb.stir,
    'mix': CommandVerb.stir,
    'observe': CommandVerb.observe,
    'watch': CommandVerb.observe,
    'enter': CommandVerb.enterValue,
    'gather': CommandVerb.collect,
    'decipher': CommandVerb.decipher,
    'decode': CommandVerb.decipher,
    'translate': CommandVerb.decipher,
    'say': CommandVerb.say,
    'answer': CommandVerb.say,
    'tell': CommandVerb.say,
    'speak': CommandVerb.say,
    'hint': CommandVerb.hint,
    'clue': CommandVerb.hint,
    'nudge': CommandVerb.hint,
    'help': CommandVerb.help,
  };

  /// Parse [raw] input and return the best matching [ParsedCommand].
  static ParsedCommand parse(String raw) {
    final rawShortcut = raw.trim().toLowerCase();
    if (rawShortcut == '?') {
      return ParsedCommand(
          verb: CommandVerb.help, args: const [], rawInput: raw);
    }
    final input = _normalizeInput(raw);

    if (input.isEmpty) {
      return ParsedCommand(
          verb: CommandVerb.unknown, args: const [], rawInput: raw);
    }

    // ── Single-word shortcuts ──────────────────────────────────────────────
    if (input == 'i' || input == 'inv' || input == 'inventory') {
      return ParsedCommand(
          verb: CommandVerb.inventory, args: const [], rawInput: raw);
    }
    if (input == 'l' || input == 'look') {
      return ParsedCommand(
          verb: CommandVerb.examine, args: const [], rawInput: raw);
    }
    if (input == 'wait' || input == 'z') {
      return ParsedCommand(
          verb: CommandVerb.wait, args: const [], rawInput: raw);
    }
    if (input == 'help' || input == '?') {
      return ParsedCommand(
          verb: CommandVerb.help, args: const [], rawInput: raw);
    }
    if (input == 'hint' || input == 'clue' || input == 'nudge') {
      return ParsedCommand(
          verb: CommandVerb.hint, args: const [], rawInput: raw);
    }
    if (input == 'confirm' || input == 'yes') {
      return ParsedCommand(
          verb: CommandVerb.confirm, args: const [], rawInput: raw);
    }
    // Bare direction shortcut
    if (_directions.contains(input)) {
      return ParsedCommand(
        verb: CommandVerb.go,
        args: [_normalizeDir(input)],
        rawInput: raw,
      );
    }

    // ── Multi-word commands ────────────────────────────────────────────────
    final tokens = input.split(RegExp(r'\s+'));
    final alias = _matchVerbAlias(tokens);
    final verb = alias?.verb ?? CommandVerb.unknown;
    final restStart = alias?.tokenCount ?? 1;
    final rest = _stripStopWords(tokens.skip(restStart).toList());

    switch (verb) {
      case CommandVerb.go:
        if (rest.isNotEmpty && _directions.contains(rest.first)) {
          return ParsedCommand(
            verb: CommandVerb.go,
            args: [_normalizeDir(rest.first), ...rest.skip(1)],
            rawInput: raw,
          );
        }
        return ParsedCommand(verb: CommandVerb.go, args: rest, rawInput: raw);

      case CommandVerb.walk:
        // "walk north" = go north; "walk through" / "walk blindfolded" = walk verb
        if (rest.isNotEmpty && _directions.contains(rest.first)) {
          return ParsedCommand(
            verb: CommandVerb.go,
            args: [_normalizeDir(rest.first), ...rest.skip(1)],
            rawInput: raw,
          );
        }
        return ParsedCommand(verb: CommandVerb.walk, args: rest, rawInput: raw);

      case CommandVerb.examine:
        return ParsedCommand(
            verb: CommandVerb.examine, args: rest, rawInput: raw);

      case CommandVerb.take:
        return ParsedCommand(verb: CommandVerb.take, args: rest, rawInput: raw);

      case CommandVerb.drop:
        return ParsedCommand(verb: CommandVerb.drop, args: rest, rawInput: raw);

      case CommandVerb.use:
        return ParsedCommand(verb: CommandVerb.use, args: rest, rawInput: raw);

      case CommandVerb.deposit:
        return ParsedCommand(
            verb: CommandVerb.deposit, args: rest, rawInput: raw);

      case CommandVerb.wait:
        return ParsedCommand(verb: CommandVerb.wait, args: rest, rawInput: raw);

      case CommandVerb.smell:
        return ParsedCommand(
            verb: CommandVerb.smell, args: rest, rawInput: raw);

      case CommandVerb.taste:
        return ParsedCommand(
            verb: CommandVerb.taste, args: rest, rawInput: raw);

      case CommandVerb.arrange:
        return ParsedCommand(
            verb: CommandVerb.arrange, args: rest, rawInput: raw);

      case CommandVerb.combine:
        return ParsedCommand(
            verb: CommandVerb.combine, args: rest, rawInput: raw);

      case CommandVerb.press:
        return ParsedCommand(
            verb: CommandVerb.press, args: rest, rawInput: raw);

      case CommandVerb.offer:
        return ParsedCommand(
            verb: CommandVerb.offer, args: rest, rawInput: raw);

      case CommandVerb.write:
        return ParsedCommand(
            verb: CommandVerb.write, args: rest, rawInput: raw);

      case CommandVerb.measure:
        return ParsedCommand(
            verb: CommandVerb.measure, args: rest, rawInput: raw);

      case CommandVerb.calibrate:
        return ParsedCommand(
            verb: CommandVerb.calibrate, args: rest, rawInput: raw);

      case CommandVerb.invert:
        return ParsedCommand(
            verb: CommandVerb.invert, args: rest, rawInput: raw);

      case CommandVerb.confirm:
        return ParsedCommand(
            verb: CommandVerb.confirm, args: rest, rawInput: raw);

      case CommandVerb.breakObj:
        return ParsedCommand(
            verb: CommandVerb.breakObj, args: rest, rawInput: raw);

      case CommandVerb.blow:
        return ParsedCommand(verb: CommandVerb.blow, args: rest, rawInput: raw);

      case CommandVerb.setParam:
        return ParsedCommand(
            verb: CommandVerb.setParam, args: rest, rawInput: raw);

      case CommandVerb.drink:
        return ParsedCommand(
            verb: CommandVerb.drink, args: rest, rawInput: raw);

      case CommandVerb.stir:
        return ParsedCommand(verb: CommandVerb.stir, args: rest, rawInput: raw);

      case CommandVerb.observe:
        return ParsedCommand(
            verb: CommandVerb.observe, args: rest, rawInput: raw);

      case CommandVerb.enterValue:
        return ParsedCommand(
            verb: CommandVerb.enterValue, args: rest, rawInput: raw);

      case CommandVerb.collect:
        return ParsedCommand(
            verb: CommandVerb.collect, args: rest, rawInput: raw);

      case CommandVerb.decipher:
        return ParsedCommand(
            verb: CommandVerb.decipher, args: rest, rawInput: raw);

      case CommandVerb.say:
        return ParsedCommand(verb: CommandVerb.say, args: rest, rawInput: raw);

      case CommandVerb.hint:
        return ParsedCommand(verb: CommandVerb.hint, args: rest, rawInput: raw);

      case CommandVerb.help:
        return ParsedCommand(
            verb: CommandVerb.help, args: const [], rawInput: raw);

      case CommandVerb.inventory:
      case CommandVerb.unknown:
        return ParsedCommand(
            verb: CommandVerb.unknown,
            args: _stripStopWords(tokens.skip(1).toList()),
            rawInput: raw);
    }
  }

  static String _normalizeInput(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[’'`]"), '')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static _VerbAliasMatch? _matchVerbAlias(List<String> tokens) {
    for (var size = 3; size >= 1; size--) {
      if (tokens.length < size) continue;
      final phrase = tokens.take(size).join(' ');
      final verb = _verbAliases[phrase];
      if (verb != null) {
        return _VerbAliasMatch(verb: verb, tokenCount: size);
      }
    }
    return null;
  }

  static String _normalizeDir(String d) {
    switch (d) {
      case 'n':
        return 'north';
      case 's':
        return 'south';
      case 'e':
        return 'east';
      case 'w':
        return 'west';
      default:
        return d;
    }
  }

  static List<String> _stripStopWords(List<String> tokens) =>
      tokens.where((t) => !_stopWords.contains(t)).toList();
}

class _VerbAliasMatch {
  final CommandVerb verb;
  final int tokenCount;

  const _VerbAliasMatch({required this.verb, required this.tokenCount});
}
