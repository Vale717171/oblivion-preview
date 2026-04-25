// lib/features/ui/game_screen.dart
// Author: GitHub Copilot — 2026-04-02
// Main text UI for L'Archivio dell'Oblio.
// Features:
//   - Scrollable message history (player input + narrative responses)
//   - Text input at the bottom
//   - Typewriter effect for incoming narrative messages
//   - Colour palette that shifts subtly with PsychoProfile
//   - Subtle sector background image (opacity 0.15) behind the text

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' show min, pi, sin;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_engine_provider.dart';
import '../parser/parser_state.dart';
import '../settings/app_settings_provider.dart';
import '../state/game_state_provider.dart';
import '../state/psycho_provider.dart';
import 'archive_panels.dart';
import '../audio/audio_service.dart';
import 'background_service.dart';
import 'ritual_style.dart';

// PsychoProfile thresholds that drive the UI colour palette (mirror GDD section 6)
const int _panicAnxietyThreshold = 70; // anxiety > this → reddish text
const int _lowLucidityThreshold = 30; // lucidity < this → grey text
const int _highOblivionThreshold = 60; // oblivionLevel > this → blue-grey text
const double _backgroundImageOpacity = 0.35;
const double _minimumReadableTextScale = 1.08;
const Duration _backgroundFlashHoldDuration = Duration(milliseconds: 180);
const Duration _successBloomHoldDuration = Duration(milliseconds: 540);
const Duration _backgroundFadeDuration = Duration(milliseconds: 900);
const Duration _puzzleCueHoldDuration = Duration(milliseconds: 1300);
const Duration _simulacrumBannerDuration = Duration(milliseconds: 2200);
const Duration _epiphanyPopupDuration = Duration(milliseconds: 2000);
// Secret command that activates walkthrough mode (QA only, never persisted).
const String _walkthroughUnlockCommand = 'Stalker4598!TarkoS?';

// ── Finale helpers ────────────────────────────────────────────────────────────
enum _FinaleType { acceptance, oblivion, eternalZone, testimony }

_FinaleType? _finaleTypeFor(String nodeId) {
  switch (nodeId) {
    case 'finale_acceptance':
      return _FinaleType.acceptance;
    case 'finale_oblivion':
      return _FinaleType.oblivion;
    case 'finale_eternal_zone':
      return _FinaleType.eternalZone;
    case 'finale_testimony':
      return _FinaleType.testimony;
    default:
      return null;
  }
}

class _ProgressMilestone {
  final String key;
  final String label;
  final String trackTitle;

  const _ProgressMilestone({
    required this.key,
    required this.label,
    required this.trackTitle,
  });
}

class _EpiphanyLine {
  final String title;
  final String subtitle;

  const _EpiphanyLine({
    required this.title,
    required this.subtitle,
  });
}

class _PuzzleCueCopy {
  final String title;
  final String subtitle;

  const _PuzzleCueCopy({
    required this.title,
    required this.subtitle,
  });
}

const List<_ProgressMilestone> _progressMilestones = [
  _ProgressMilestone(
    key: 'progress_surface_garden',
    label: 'Garden',
    trackTitle: 'Bach BWV 846 — Garden Threshold',
  ),
  _ProgressMilestone(
    key: 'progress_surface_observatory',
    label: 'Observatory',
    trackTitle: 'Contrapunctus — Observatory',
  ),
  _ProgressMilestone(
    key: 'progress_surface_gallery',
    label: 'Gallery',
    trackTitle: 'Bach BWV 846 — Gallery Mirror',
  ),
  _ProgressMilestone(
    key: 'progress_surface_laboratory',
    label: 'Laboratory',
    trackTitle: 'Bach BWV 1008 — Laboratory',
  ),
  _ProgressMilestone(
    key: 'progress_surface_memory',
    label: 'Memory',
    trackTitle: 'Aria delle Goldberg — Memory Trace',
  ),
];

const List<_EpiphanyLine> _epiphanyLines = [
  _EpiphanyLine(
    title: 'Aperture',
    subtitle: 'A narrow light opens inside the Archive.',
  ),
  _EpiphanyLine(
    title: 'Resonance',
    subtitle: 'The room answers before words can.',
  ),
  _EpiphanyLine(
    title: 'Threshold',
    subtitle: 'A silent hinge turns somewhere near.',
  ),
  _EpiphanyLine(
    title: 'Trace',
    subtitle: 'A living mark remains in the dust.',
  ),
  _EpiphanyLine(
    title: 'Alignment',
    subtitle: 'For one breath, everything is in tune.',
  ),
  _EpiphanyLine(
    title: 'Revelation',
    subtitle: 'A hidden contour steps into view.',
  ),
];

// 5×4 color matrix: +18% RGB gain plus a small +18 luminance lift keeps the
// mandated 0.15-opacity artwork readable on dimmer screens without making it loud.
const List<double> _backgroundImageBrightnessMatrix = [
  1.18,
  0,
  0,
  0,
  18,
  0,
  1.18,
  0,
  0,
  18,
  0,
  0,
  1.18,
  0,
  18,
  0,
  0,
  0,
  1,
  0,
];

final FocusNode gameCommandFocusNode = FocusNode(
  debugLabel: 'game-command-input',
);

enum TypewriterTextSpeed { slow, normal, instant }

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = gameCommandFocusNode;

  // Typewriter state for the last narrative message.
  bool _typewriterRunning = false;
  String? _typewriterTarget;
  TextRevealMode _activeRevealMode = TextRevealMode.typewriter;
  bool _revealAllTypewriterText = false;
  final _inputShakeKey = GlobalKey<_InputShakeWrapperState>();
  Timer? _backgroundFlashTimer;
  Timer? _successBloomTimer;
  Timer? _briefDimTimer;
  Timer? _sectorFadeTimer;
  Timer? _puzzleCueTimer;
  Timer? _simulacrumBannerTimer;
  Timer? _epiphanyPopupTimer;
  bool _backgroundFlashActive = false;
  bool _successBloomActive = false;
  bool _briefDimActive = false;
  bool _sectorFadeActive = false;
  bool _puzzleCueActive = false;
  String _puzzleCueTitle = 'Puzzle resolved';
  String _puzzleCueSubtitle = 'A hidden hinge yields.';
  String? _simulacrumBannerText;
  String? _epiphanyTitle;
  String? _epiphanySubtitle;
  bool _lastObservedPuzzleSolved = false;
  String? _lastObservedSimulacrum;
  Set<String> _lastObservedCompletedPuzzles = const {};
  int _lastObservedPsychoShiftCount = 0;
  int _lastObservedMessageCount = 0;
  int _lastObservedUnlockedMilestones = 0;
  int _epiphanyLineCursor = 0;
  String _lastObservedSectorLabel = '';
  // -1 = "not yet observed" so the very first build never fires a threshold haptic.
  int _lastObservedOblivionLevel = -1;
  String? _lastSubmittedCommand;

  // Assist tray (quick commands + reuse) — hidden by default so the text
  // area gets maximum space; toggled by the lightbulb icon in the input row.

  // Finale state — white-screen fade triggered by "— FINE —" in acceptance.
  bool _wakeUpFading = false;

  // Walkthrough mode — activated by the secret unlock command.
  // Never persisted; resets to false on every app restart.
  bool _walkthroughUnlocked = false;
  int _walkthroughStep = 0;
  List<Map<String, dynamic>>? _walkthroughSteps;

  // Command history — up/down arrow navigation (classic text-adventure UX).
  final List<String> _commandHistory = [];
  int _historyIndex = -1; // -1 = not browsing history
  String _historyDraft = ''; // text typed before entering history mode
  int _processedScreenResetCount = 0;
  int _queuedScreenResetCount = 0;
  bool _gameAudioStartedFromInput = false;
  // The engine emits monotonically increasing reset counts, so queue order
  // preserves the order of successful commands when several land in one frame.
  final Queue<int> _pendingScreenResetCounts = Queue<int>();
  bool _screenResetCallbackScheduled = false;
  bool _resumeRecapArmed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.onKeyEvent = (_, event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
        return KeyEventResult.ignored;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _navigateHistory(-1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _navigateHistory(1);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
    // Request input focus after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      final currentNode =
          ref.read(gameStateProvider).valueOrNull?.currentNode ?? 'intro_void';
      AudioService().syncForNode(currentNode, force: true);
      for (final assetPath in BackgroundService.allBackgroundAssets) {
        precacheImage(AssetImage(assetPath), context);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundFlashTimer?.cancel();
    _successBloomTimer?.cancel();
    _briefDimTimer?.cancel();
    _sectorFadeTimer?.cancel();
    _puzzleCueTimer?.cancel();
    _simulacrumBannerTimer?.cancel();
    _epiphanyPopupTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _resumeRecapArmed = true;
      return;
    }
    if (state == AppLifecycleState.resumed && _resumeRecapArmed) {
      _resumeRecapArmed = false;
      // ignore: discarded_futures
      ref.read(gameEngineProvider.notifier).appendSessionRecap();
    }
  }

  // ── Palette ─────────────────────────────────────────────────────────────

  /// Text colour for narrative messages — shifts with psychological state.
  Color _narrativeColor(
    PsychoProfile? profile, {
    required String nodeId,
    required bool highContrast,
  }) {
    Color base = Colors.white;
    if (profile != null) {
      if (profile.anxiety > _panicAnxietyThreshold) {
        base = const Color(0xFFFFD8D8);
      } else if (profile.lucidity < _lowLucidityThreshold) {
        base = const Color(0xFFCCCCCC);
      } else if (profile.oblivionLevel > _highOblivionThreshold) {
        base = const Color(0xFFCCDDEE);
      }
    }

    final sector = gameSectorLabel(nodeId);
    final tint = switch (sector) {
      'Threshold' => const Color(0xFFF4EBD8),
      'Garden' => const Color(0xFFE9F4DF),
      'Observatory' => const Color(0xFFE5F0FF),
      'Gallery' => const Color(0xFFF3E8D7),
      'Laboratory' => const Color(0xFFE9F1E1),
      'Memory' => const Color(0xFFF2E6D8),
      'Finale' => const Color(0xFFF6EFE2),
      'Zone' => const Color(0xFFE3F5FF),
      _ => const Color(0xFFF2EEE4),
    };
    final blend = highContrast ? 0.06 : 0.18;
    return Color.lerp(base, tint, blend) ?? base;
  }

  /// Subtle background tint — deepens as oblivion rises.
  Color _backgroundColor(PsychoProfile? profile) {
    const baseColor = Color(0xFF080A0F);
    const deepColor = Color(0xFF101726);
    if (profile == null) return baseColor;
    final t = (profile.oblivionLevel / 100).clamp(0.0, 0.35);
    return Color.lerp(baseColor, deepColor, t)!;
  }

  double _backgroundOpacityForNode(String nodeId, {required bool isFinale}) {
    if (isFinale) return 0.52;
    switch (nodeId) {
      case 'intro_void':
      case 'threshold':
        return 0.34;
      case 'garden_fountain':
        return 0.38;
      case 'garden_stelae':
        return 0.36;
      case 'garden_grove':
        return 0.37;
      case 'gallery_hall':
        return 0.33;
      case 'gallery_corridor':
      case 'gallery_proportions':
        return 0.35;
      case 'gallery_dark':
      case 'gallery_light':
      case 'gallery_central':
        return 0.39;
      case 'quinto_landing':
      case 'quinto_maturity':
      case 'quinto_ritual_chamber':
        return 0.36;
      case 'preview_epilogue':
        return 0.44;
      case 'la_zona':
        return 0.40;
      default:
        return _backgroundImageOpacity;
    }
  }

  // ── Typewriter ──────────────────────────────────────────────────────────

  void _triggerBriefDim() {
    _briefDimTimer?.cancel();
    setState(() => _briefDimActive = true);
    _briefDimTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _briefDimActive = false);
    });
  }

  void _triggerSectorTransitionFade() {
    _sectorFadeTimer?.cancel();
    setState(() => _sectorFadeActive = true);
    _sectorFadeTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _sectorFadeActive = false);
    });
  }

  void _startReveal(GameMessage message) {
    final text = message.text;
    final mode = message.revealMode;
    final settings = ref.read(appSettingsProvider).valueOrNull;
    if (message.feedbackKind == FeedbackKind.sectorTransition) {
      _triggerSectorTransitionFade();
    } else if (message.feedbackKind == FeedbackKind.demiurgeError) {
      _triggerBriefDim();
    }
    if (settings?.instantText ?? false || mode == TextRevealMode.instant) {
      setState(() {
        _typewriterTarget = text;
        _typewriterRunning = false;
        _activeRevealMode = TextRevealMode.instant;
        _revealAllTypewriterText = true;
      });
      return;
    }
    if (_typewriterTarget == text &&
        _typewriterRunning &&
        _activeRevealMode == mode) {
      return;
    }
    setState(() {
      _typewriterTarget = text;
      _activeRevealMode = mode;
      _typewriterRunning = true;
      _revealAllTypewriterText = false;
    });
  }

  void _skipTypewriter() {
    if (_typewriterRunning && _typewriterTarget != null) {
      setState(() {
        _typewriterRunning = false;
        _revealAllTypewriterText = true;
      });
      _scrollToBottom();
    }
  }

  TypewriterTextSpeed _typewriterSpeedForMessage(GameMessage message) {
    if (message.role != MessageRole.narrative) {
      return TypewriterTextSpeed.instant;
    }
    if (message.revealMode == TextRevealMode.instant) {
      return TypewriterTextSpeed.instant;
    }
    if (message.feedbackKind == FeedbackKind.demiurgeError ||
        message.feedbackKind == FeedbackKind.demiurgeInterruption ||
        message.isDemiurge ||
        message.revealMode == TextRevealMode.slow ||
        message.revealMode == TextRevealMode.wordByWord) {
      return TypewriterTextSpeed.slow;
    }
    return TypewriterTextSpeed.normal;
  }

  double _oblivionOpacityForMessage({
    required int index,
    required int total,
  }) {
    final ageFromBottom = (total - 1) - index;
    if (ageFromBottom <= 3) return 1.0;
    final fadeSpan = (total - 4).clamp(1, 18).toDouble();
    final faded = (ageFromBottom - 3).clamp(0, fadeSpan).toDouble() / fadeSpan;
    return (1.0 - faded * 0.8).clamp(0.2, 1.0);
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToTop() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  bool _hapticsOn() {
    final s = ref.read(appSettingsProvider).valueOrNull;
    return (s?.enableHaptics ?? true) && !(s?.reduceMotion ?? false);
  }

  void _triggerSuccessVisualCue() {
    _backgroundFlashTimer?.cancel();
    _successBloomTimer?.cancel();
    // "Confirmed" — heavier than the submit tap so the player feels the command land.
    if (_hapticsOn()) HapticFeedback.heavyImpact();
    final settings = ref.read(appSettingsProvider).valueOrNull;
    if (settings?.reduceMotion ?? false) {
      _scrollToTop();
      return;
    }
    setState(() {
      _backgroundFlashActive = true;
      _successBloomActive = true;
    });
    _scrollToTop();
    _backgroundFlashTimer = Timer(_backgroundFlashHoldDuration, () {
      if (!mounted) return;
      setState(() => _backgroundFlashActive = false);
    });
    _successBloomTimer = Timer(_successBloomHoldDuration, () {
      if (!mounted) return;
      setState(() => _successBloomActive = false);
    });
  }

  /// Double light-tap haptic for parser errors — two short pulses 80 ms apart
  /// feel like a dry "no" without being jarring.
  void _triggerErrorHaptic() {
    if (!_hapticsOn()) return;
    HapticFeedback.lightImpact();
    Timer(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      HapticFeedback.lightImpact();
    });
  }

  /// Double medium-impact haptic 50 ms apart — a distinct "threshold crossed"
  /// signature, heavier than the error double-tap (light/80ms) and different
  /// from the single heavy used for scene changes.
  void _triggerSectorChangeHaptic() {
    if (!_hapticsOn()) return;
    HapticFeedback.mediumImpact();
    Timer(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
    });
  }

  /// Fires haptic cues when oblivionLevel crosses key thresholds upward.
  ///
  /// Fires only on threshold crossings — not on every profile update —
  /// so the sensation marks narrative milestones rather than routine updates.
  ///
  ///   ≥ 70 → single heavyImpact   ("something is wrong")
  ///   ≥ 90 → double heavyImpact 120 ms apart   ("the Archive is consuming you")
  void _consumeOblivionHaptic(int oblivionLevel) {
    if (_lastObservedOblivionLevel == -1) {
      // First build: just record the baseline, never fire.
      _lastObservedOblivionLevel = oblivionLevel;
      return;
    }
    final prev = _lastObservedOblivionLevel;
    _lastObservedOblivionLevel = oblivionLevel;

    final crossed90 = oblivionLevel >= 90 && prev < 90;
    final crossed70 = oblivionLevel >= 70 && prev < 70;

    if (crossed90) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_hapticsOn()) return;
        HapticFeedback.heavyImpact();
        Timer(const Duration(milliseconds: 120), () {
          if (!mounted) return;
          HapticFeedback.heavyImpact();
        });
      });
    } else if (crossed70) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _hapticsOn()) HapticFeedback.heavyImpact();
      });
    }
  }

  /// Detects sector changes between builds and schedules the haptic cue.
  /// [currentNode] is the node ID already resolved in the build() frame.
  void _consumeSectorChange(String currentNode) {
    final sector = gameSectorLabel(currentNode);
    if (_lastObservedSectorLabel.isNotEmpty &&
        sector != _lastObservedSectorLabel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _triggerSectorChangeHaptic();
      });
    }
    _lastObservedSectorLabel = sector;
  }

  void _triggerPuzzleSolvedCue({
    required String currentNode,
    required String? solvedPuzzleId,
  }) {
    _puzzleCueTimer?.cancel();
    if (_hapticsOn()) HapticFeedback.mediumImpact();
    // ignore: discarded_futures
    AudioService().handleTrigger('reward_bach_soft');
    final line = _nextEpiphanyLine();
    final puzzleCueCopy = _puzzleCueCopyFor(
      currentNode: currentNode,
      puzzleId: solvedPuzzleId,
    );
    _showEpiphanyPopup(title: line.title, subtitle: line.subtitle);
    setState(() {
      _puzzleCueTitle = puzzleCueCopy.title;
      _puzzleCueSubtitle = puzzleCueCopy.subtitle;
      _puzzleCueActive = true;
    });
    _puzzleCueTimer = Timer(_puzzleCueHoldDuration, () {
      if (!mounted) return;
      setState(() => _puzzleCueActive = false);
    });
  }

  void _showSimulacrumBanner(String itemName) {
    final words = <String>[];
    for (final part in itemName.split(' ')) {
      if (part.isEmpty) continue;
      words.add('${part[0].toUpperCase()}${part.substring(1)}');
    }
    final label = words.join(' ');
    _simulacrumBannerTimer?.cancel();
    if (_hapticsOn()) HapticFeedback.mediumImpact();
    // ignore: discarded_futures
    AudioService().handleTrigger('reward_bach');
    setState(() => _simulacrumBannerText = '✦ $label recovered');
    final line = _nextEpiphanyLine();
    _showEpiphanyPopup(
      title: '$label Recovered',
      subtitle: line.subtitle,
    );
    _simulacrumBannerTimer = Timer(_simulacrumBannerDuration, () {
      if (!mounted) return;
      setState(() => _simulacrumBannerText = null);
    });
  }

  void _triggerPsychoShiftCue({required bool phaseChanged}) {
    if (_hapticsOn()) {
      HapticFeedback.mediumImpact();
      if (phaseChanged) {
        Timer(const Duration(milliseconds: 70), () {
          if (!mounted) return;
          HapticFeedback.mediumImpact();
        });
      }
    }
  }

  void _showEpiphanyPopup({
    required String title,
    required String subtitle,
  }) {
    _epiphanyPopupTimer?.cancel();
    setState(() {
      _epiphanyTitle = title;
      _epiphanySubtitle = subtitle;
    });
    _epiphanyPopupTimer = Timer(_epiphanyPopupDuration, () {
      if (!mounted) return;
      setState(() {
        _epiphanyTitle = null;
        _epiphanySubtitle = null;
      });
    });
  }

  _EpiphanyLine _nextEpiphanyLine() {
    final line = _epiphanyLines[_epiphanyLineCursor % _epiphanyLines.length];
    _epiphanyLineCursor++;
    return line;
  }

  int _unlockedMilestonesCount(Set<String> completedPuzzles) =>
      _progressMilestones.where((m) => completedPuzzles.contains(m.key)).length;

  void _consumeMilestoneReveal(Set<String> completedPuzzles) {
    final unlocked = _unlockedMilestonesCount(completedPuzzles);
    if (unlocked > _lastObservedUnlockedMilestones &&
        unlocked <= _progressMilestones.length) {
      final unlockedMilestone = _progressMilestones[unlocked - 1];
      final line = _nextEpiphanyLine();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showEpiphanyPopup(
          title: '${unlockedMilestone.label} Revealed',
          subtitle: '${line.subtitle} · ${unlockedMilestone.trackTitle}',
        );
      });
    }
    _lastObservedUnlockedMilestones = unlocked;
  }

  _PuzzleCueCopy _puzzleCueCopyFor({
    required String currentNode,
    required String? puzzleId,
  }) {
    const byPuzzleId = <String, _PuzzleCueCopy>{
      'garden_columns_read': _PuzzleCueCopy(
        title: 'Columns Read',
        subtitle: 'The avenue names its first order.',
      ),
      'leaves_arranged': _PuzzleCueCopy(
        title: 'Leaves Aligned',
        subtitle: 'The cypress breath falls into lucid order.',
      ),
      'fountain_waited': _PuzzleCueCopy(
        title: 'Water Answered',
        subtitle: 'Stillness begins to reveal what haste concealed.',
      ),
      'fountain_reflection_1': _PuzzleCueCopy(
        title: 'First Reflection',
        subtitle: 'The basin yields its first held image.',
      ),
      'fountain_reflection_2': _PuzzleCueCopy(
        title: 'Second Reflection',
        subtitle: 'A deeper contour appears beneath the surface.',
      ),
      'stele_inscribed': _PuzzleCueCopy(
        title: 'Cost Inscribed',
        subtitle: 'The stone accepts a true and human line.',
      ),
      'alcove_pleasures_walked': _PuzzleCueCopy(
        title: 'Pleasure Released',
        subtitle: 'Fragrance is met without trying to possess it.',
      ),
      'alcove_pains_walked': _PuzzleCueCopy(
        title: 'Pain Faced',
        subtitle: 'The shard is seen clearly and left where it is.',
      ),
      'garden_offer_useful': _PuzzleCueCopy(
        title: 'First Offering',
        subtitle: 'Utility yields before the statue.',
      ),
      'garden_offer_identity': _PuzzleCueCopy(
        title: 'Second Offering',
        subtitle: 'The self loosens its grip on its old emblem.',
      ),
      'garden_offer_pain': _PuzzleCueCopy(
        title: 'Third Offering',
        subtitle: 'What hurt is placed down without display.',
      ),
    };

    final exactMatch = puzzleId == null ? null : byPuzzleId[puzzleId];
    if (exactMatch != null) return exactMatch;
    if (currentNode.startsWith('garden')) {
      return const _PuzzleCueCopy(
        title: 'Garden Yielded',
        subtitle: 'Something living in the path gives way.',
      );
    }
    if (currentNode.startsWith('obs_')) {
      return const _PuzzleCueCopy(
        title: 'Observatory Aligned',
        subtitle: 'The mechanism admits a sharper relation.',
      );
    }
    if (currentNode.startsWith('gal_') || currentNode.startsWith('gallery_')) {
      return const _PuzzleCueCopy(
        title: 'Mirror Shifted',
        subtitle: 'A false image slips and leaves a seam exposed.',
      );
    }
    if (currentNode.startsWith('lab_')) {
      return const _PuzzleCueCopy(
        title: 'Work Advanced',
        subtitle: 'The vessel answers with a steadier glow.',
      );
    }
    if (currentNode.startsWith('memory_') ||
        currentNode.startsWith('quinto_')) {
      return const _PuzzleCueCopy(
        title: 'Memory Stirred',
        subtitle: 'A room long sealed opens by one quiet degree.',
      );
    }
    return const _PuzzleCueCopy(
      title: 'Threshold Crossed',
      subtitle: 'The Archive acknowledges the command.',
    );
  }

  void _consumeFeedbackSignals(GameEngineState engine, String currentNode) {
    final isPreviewClosureMoment =
        engine.completedPuzzles.contains('garden_complete') &&
            engine.latestSimulacrum == 'ataraxia';
    final solvedPuzzleId = engine.completedPuzzles
        .where((puzzle) => !_lastObservedCompletedPuzzles.contains(puzzle))
        .lastOrNull;

    if (!isPreviewClosureMoment &&
        engine.isPuzzleSolved &&
        !_lastObservedPuzzleSolved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _triggerPuzzleSolvedCue(
            currentNode: currentNode,
            solvedPuzzleId: solvedPuzzleId,
          );
        }
      });
    }
    _lastObservedPuzzleSolved = engine.isPuzzleSolved;
    _lastObservedCompletedPuzzles = {...engine.completedPuzzles};

    final latestSimulacrum = engine.latestSimulacrum;
    if (latestSimulacrum != null &&
        _lastObservedSimulacrum != latestSimulacrum &&
        !isPreviewClosureMoment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showSimulacrumBanner(latestSimulacrum);
      });
    }
    _lastObservedSimulacrum = latestSimulacrum;

    if (engine.psychoShiftCount > _lastObservedPsychoShiftCount) {
      final phaseChanged = engine.latestPsychoShiftIsPhase;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _triggerPsychoShiftCue(phaseChanged: phaseChanged);
        }
      });
    }
    _lastObservedPsychoShiftCount = engine.psychoShiftCount;

    // Detect new error messages and play pitched-down rejection SFX.
    final msgCount = engine.messages.length;
    if (msgCount > _lastObservedMessageCount) {
      final lastMsg = engine.messages.lastOrNull;
      final rejected = lastMsg?.role == MessageRole.error ||
          lastMsg?.feedbackKind == FeedbackKind.demiurgeError;
      if (rejected) {
        // ignore: discarded_futures
        AudioService().playCommandRejected();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _triggerErrorHaptic();
          _inputShakeKey.currentState?.triggerShake();
        });
      }
    }
    _lastObservedMessageCount = msgCount;
  }

  void _scheduleScreenResetCue(int screenResetCount) {
    // Preserve the reset counts so rapid successive successes can still be
    // flashed in order instead of collapsing into a single generic flag.
    // Counts are monotonic and only increase inside the engine.
    if (screenResetCount <= _queuedScreenResetCount) return;
    _pendingScreenResetCounts.addLast(screenResetCount);
    _queuedScreenResetCount = screenResetCount;
    if (_screenResetCallbackScheduled) return;
    _screenResetCallbackScheduled = true;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _consumeScreenResetCue());
  }

  void _clearScheduledScreenResetCue() {
    _screenResetCallbackScheduled = false;
  }

  void _consumeScreenResetCue() {
    if (!mounted) {
      _pendingScreenResetCounts.clear();
      _clearScheduledScreenResetCue();
      return;
    }
    if (_pendingScreenResetCounts.isEmpty) {
      _clearScheduledScreenResetCue();
      return;
    }
    _processedScreenResetCount = _pendingScreenResetCounts.removeFirst();
    _triggerSuccessVisualCue();
    if (_pendingScreenResetCounts.isEmpty) {
      _clearScheduledScreenResetCue();
      return;
    }
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _consumeScreenResetCue());
  }

  // ── Input ────────────────────────────────────────────────────────────────

  /// Navigate command history. [direction] = -1 (older) or +1 (newer).
  void _navigateHistory(int direction) {
    if (_commandHistory.isEmpty) return;
    if (_historyIndex == -1 && direction == 1) return; // nothing newer

    if (_historyIndex == -1) {
      // Entering history: save whatever the user was typing
      _historyDraft = _controller.text;
      _historyIndex = _commandHistory.length - 1;
    } else if (direction == -1 && _historyIndex > 0) {
      _historyIndex--;
    } else if (direction == 1 && _historyIndex < _commandHistory.length - 1) {
      _historyIndex++;
    } else if (direction == 1 && _historyIndex == _commandHistory.length - 1) {
      // Past the end → restore draft
      _historyIndex = -1;
      _controller
        ..text = _historyDraft
        ..selection = TextSelection.collapsed(offset: _historyDraft.length);
      return;
    }

    final entry = _commandHistory[_historyIndex];
    _controller
      ..text = entry
      ..selection = TextSelection.collapsed(offset: entry.length);
  }

  void _refocusCommandInput() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  void _submit() {
    try {
      final text = _controller.text.trim();
      if (_typewriterRunning) {
        _skipTypewriter();
        if (text.isEmpty) return;
      }
      if (text.isEmpty) return;
      _startGameplayAudioFromInput();
      // Secret walkthrough unlock command — consumed here, never forwarded to engine.
      if (text == _walkthroughUnlockCommand) {
        _controller.clear();
        setState(() => _walkthroughUnlocked = true);
        return;
      }
      // Immediate "key press" feedback — fires before the engine processes the command.
      if (_hapticsOn()) HapticFeedback.mediumImpact();
      _controller.clear();
      _lastSubmittedCommand = text;
      // Add to history (skip duplicates of the most recent entry; cap at 30).
      if (_commandHistory.isEmpty || _commandHistory.last != text) {
        _commandHistory.add(text);
        if (_commandHistory.length > 30) _commandHistory.removeAt(0);
      }
      _historyIndex = -1;
      _historyDraft = '';
      ref.read(gameEngineProvider.notifier).processInput(text);
    } finally {
      _refocusCommandInput();
    }
  }

  void _startGameplayAudioFromInput() {
    if (_gameAudioStartedFromInput) return;
    _gameAudioStartedFromInput = true;
    final settings = ref.read(appSettingsProvider).valueOrNull;
    if (!(settings?.musicEnabled ?? true) ||
        (settings?.musicVolume ?? 0) <= 0) {
      return;
    }
    final currentNode =
        ref.read(gameStateProvider).valueOrNull?.currentNode ?? 'intro_void';
    // Let the title Aria recede as soon as the player begins interacting with
    // the command line, then bring in the node score and ambient bed.
    // ignore: discarded_futures
    AudioService().transitionTitleCueToGameplay(currentNode);
  }

  void _queueQuickCommand(String command, {bool submit = true}) {
    if (_typewriterRunning) {
      _skipTypewriter();
    }
    _controller
      ..text = command
      ..selection = TextSelection.collapsed(offset: command.length);
    if (submit) {
      _submit();
    } else {
      _focusNode.requestFocus();
    }
  }

  Future<void> _walkthroughNext() async {
    if (_walkthroughSteps == null) {
      try {
        final raw =
            await rootBundle.loadString('assets/texts/walkthrough.json');
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _walkthroughSteps =
            (decoded['steps'] as List).cast<Map<String, dynamic>>();
      } catch (e) {
        // Fail silently in production; print in debug for QA diagnostics.
        assert(() {
          // ignore: avoid_print
          print('[Walkthrough] Failed to load walkthrough.json: $e');
          return true;
        }());
        return;
      }
    }
    final steps = _walkthroughSteps!;
    if (_walkthroughStep >= steps.length) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Walkthrough complete')),
        );
      }
      return;
    }
    final command = steps[_walkthroughStep]['command'] as String;
    setState(() => _walkthroughStep++);
    _queueQuickCommand(command);
  }

  Future<void> _startNewGame() async {
    _skipTypewriter();
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('New game'),
        content: const Text(
          'Start over from the beginning? Your current progress will be replaced.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start over'),
          ),
        ],
      ),
    );

    if (shouldReset != true || !mounted) return;

    FocusScope.of(context).unfocus();
    await ref.read(gameEngineProvider.notifier).startNewGame();
    if (!mounted) return;
    _focusNode.requestFocus();
  }

  Future<void> _handleMenuAction(
    _GameMenuAction action,
    GameEngineState? engine,
  ) async {
    switch (action) {
      case _GameMenuAction.newGame:
        return _startNewGame();
      case _GameMenuAction.archiveStatus:
        if (engine != null) {
          return ArchivePanels.showArchiveStatus(context, engine);
        }
        return;
      case _GameMenuAction.saveLoad:
        return ArchivePanels.showSaveLoad(context);
      case _GameMenuAction.memories:
        return ArchivePanels.showPlayerMemories(context);
      case _GameMenuAction.howToPlay:
        return ArchivePanels.showHowToPlay(context);
      case _GameMenuAction.settings:
        return ArchivePanels.showSettings(context);
      case _GameMenuAction.credits:
        return ArchivePanels.showCredits(context);
      case _GameMenuAction.title:
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        return;
    }
  }

  String? _findLastPlayerCommand(List<GameMessage> messages) {
    for (final message in messages.reversed) {
      if (message.role == MessageRole.player) {
        return message.text.replaceFirst(RegExp(r'^>\s*'), '');
      }
    }
    return _lastSubmittedCommand;
  }

  String _inputHintForNode(String nodeId) => 'enter a command';

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final engineAsync = ref.watch(gameEngineProvider);
    final psychoAsync = ref.watch(psychoProfileProvider);
    final gameStateAsync = ref.watch(gameStateProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final profile = psychoAsync.valueOrNull;
    final settings = settingsAsync.valueOrNull;
    final textScale =
        (settings?.textScale ?? 1.0).clamp(_minimumReadableTextScale, 1.8);
    final highContrast = settings?.highContrast ?? false;
    final currentNode = gameStateAsync.valueOrNull?.currentNode ?? 'intro_void';

    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final bgColor = _backgroundColor(profile);
    final narrativeColor = highContrast
        ? const Color(0xFFF6F2E8)
        : _narrativeColor(
            profile,
            nodeId: currentNode,
            highContrast: highContrast,
          );
    final visualProfile = visualProfileForNode(currentNode);

    // Resolve background image from current node
    final backgroundPath = BackgroundService.getBackgroundForNodeOrDefault(
      currentNode,
    );

    // Finale state
    final finaleType = _finaleTypeFor(currentNode);
    final isFinale = finaleType != null;

    // Oblivion threshold haptic — fires once when crossing 70 and again at 90.
    _consumeOblivionHaptic(profile?.oblivionLevel ?? 0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            _BackgroundLayer(
              backgroundPath: backgroundPath,
              flashActive: _backgroundFlashActive,
              opacity: _backgroundOpacityForNode(
                currentNode,
                isFinale: isFinale,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: _SuccessBloomLayer(
                  active: _successBloomActive,
                  visualProfile: visualProfile,
                  reduceMotion: settings?.reduceMotion ?? false,
                ),
              ),
            ),
            IgnorePointer(
              child: _SectorAtmosphereLayer(
                profile: visualProfile,
                reduceMotion: settings?.reduceMotion ?? false,
              ),
            ),
            // Vignette: radial gradient that darkens toward the edges.
            // Intensity scales with oblivionLevel (0→100) so the world
            // grows cinematically darker as the player sinks into oblivion.
            _VignetteLayer(oblivionLevel: profile?.oblivionLevel ?? 0),
            // Finale atmospheric backdrop — tint/darkening per ending type.
            if (isFinale)
              _FinaleBackdrop(
                type: finaleType,
                reduceMotion: settings?.reduceMotion ?? false,
              ),
            if (_briefDimActive)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.24),
                    ),
                  ),
                ),
              ),
            if (_sectorFadeActive)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.62),
                    ),
                  ),
                ),
              ),
            // Game content on top — unchanged
            engineAsync.when(
              loading: () => Center(
                child: Text(
                  '…',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 24,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'The Archive is inaccessible.\n$e',
                  style: const TextStyle(
                      color: Colors.red, fontFamily: 'monospace'),
                  textAlign: TextAlign.center,
                ),
              ),
              data: (engine) {
                _consumeFeedbackSignals(engine, currentNode);
                _consumeMilestoneReveal(engine.completedPuzzles);
                _consumeSectorChange(currentNode);
                // Detect the WAKE UP epilogue text to trigger white-screen fade.
                final lastMsg = engine.messages.lastOrNull;
                if (lastMsg != null &&
                    lastMsg.role == MessageRole.narrative &&
                    lastMsg.text.contains('— FINE —') &&
                    !_wakeUpFading) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _wakeUpFading = true);
                  });
                }
                if (engine.screenResetCount != _processedScreenResetCount) {
                  _scheduleScreenResetCue(engine.screenResetCount);
                }
                const showSessionAssist = false;
                final lastCommand = _findLastPlayerCommand(engine.messages);

                // Start typewriter for the latest narrative message when it arrives
                final lastNarrative = engine.messages.lastOrNull;
                if (lastNarrative != null &&
                    lastNarrative.role == MessageRole.narrative &&
                    (_typewriterTarget != lastNarrative.text ||
                        _activeRevealMode != lastNarrative.revealMode)) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _startReveal(lastNarrative),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _TopHud(
                        sectorLabel: gameSectorLabel(currentNode),
                        nodeTitle: gameNodeTitle(currentNode),
                        narrativeColor: narrativeColor,
                        visualProfile: visualProfile,
                        textScale: textScale,
                        onMenuSelected: (action) =>
                            _handleMenuAction(action, engine),
                        canReturnToTitle: Navigator.of(context).canPop(),
                      ),
                    ),
                    if (!keyboardOpen && !isFinale)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _SessionCard(
                          sectorLabel: gameSectorLabel(currentNode),
                          nodeTitle: gameNodeTitle(currentNode),
                          itemCount: engine.inventory.length,
                          weight: engine.psychoWeight,
                          narrativeColor: narrativeColor,
                          visualProfile: visualProfile,
                          textScale: textScale,
                          showAssist: showSessionAssist,
                          typewriterRunning: _typewriterRunning,
                        ),
                      ),
                    // ── Message history ──────────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.26),
                            border: Border.all(
                              color:
                                  visualProfile.frame.withValues(alpha: 0.72),
                              width: 1.1,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    visualProfile.glow.withValues(alpha: 0.10),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: GestureDetector(
                              onTap: _skipTypewriter,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding:
                                    const EdgeInsets.fromLTRB(22, 28, 22, 12),
                                itemCount: engine.messages.length,
                                itemBuilder: (context, index) {
                                  final msg = engine.messages[index];
                                  final isLast =
                                      index == engine.messages.length - 1;
                                  final isLastNarrative = isLast &&
                                      msg.role == MessageRole.narrative;

                                  final opacity = _oblivionOpacityForMessage(
                                    index: index,
                                    total: engine.messages.length,
                                  );

                                  return Opacity(
                                    opacity: opacity,
                                    child: _MessageTile(
                                      text: msg.text,
                                      role: msg.role,
                                      narrativeColor: narrativeColor,
                                      visualProfile: visualProfile,
                                      showCursor:
                                          isLastNarrative && _typewriterRunning,
                                      textScale: textScale,
                                      typewriterSpeed: isLastNarrative
                                          ? _typewriterSpeedForMessage(msg)
                                          : TypewriterTextSpeed.instant,
                                      revealAll: isLastNarrative
                                          ? _revealAllTypewriterText
                                          : true,
                                      onRevealComplete: isLastNarrative
                                          ? () {
                                              if (mounted &&
                                                  _typewriterRunning) {
                                                setState(() {
                                                  _typewriterRunning = false;
                                                  _revealAllTypewriterText =
                                                      true;
                                                });
                                              }
                                              _scrollToBottom();
                                            }
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Status bar ───────────────────────────────────────────
                    _StatusBar(
                      weight: engine.psychoWeight,
                      itemCount: engine.inventory.length,
                      completedPuzzles: engine.completedPuzzles,
                      profile: profile,
                      color: narrativeColor.withValues(alpha: 0.72),
                      visualProfile: visualProfile,
                      textScale: textScale,
                      lastCommand: _lastSubmittedCommand,
                    ),

                    // ── Input field ──────────────────────────────────────────
                    _InputShakeWrapper(
                      key: _inputShakeKey,
                      child: _InputRow(
                        controller: _controller,
                        focusNode: _focusNode,
                        onSubmit: _submit,
                        onTextChanged: (value) {
                          if (value.trim().isNotEmpty) {
                            _startGameplayAudioFromInput();
                          }
                        },
                        enabled: engine.phase == ParserPhase.idle,
                        narrativeColor: narrativeColor,
                        visualProfile: visualProfile,
                        textScale: textScale,
                        hintText: _inputHintForNode(currentNode),
                        onRecallLast: lastCommand == null
                            ? null
                            : () =>
                                _queueQuickCommand(lastCommand, submit: false),
                        onWalkthroughNext:
                            _walkthroughUnlocked ? _walkthroughNext : null,
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: _PuzzleSolvedOverlay(
                  active: _puzzleCueActive,
                  title: _puzzleCueTitle,
                  subtitle: _puzzleCueSubtitle,
                  visualProfile: visualProfile,
                  reduceMotion: settings?.reduceMotion ?? false,
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: 20,
              right: 20,
              child: IgnorePointer(
                child: _SimulacrumBanner(
                  text: _simulacrumBannerText,
                  visualProfile: visualProfile,
                  reduceMotion: settings?.reduceMotion ?? false,
                ),
              ),
            ),
            Positioned(
              top: 74,
              left: 20,
              right: 20,
              child: IgnorePointer(
                child: _EpiphanyPopup(
                  title: _epiphanyTitle,
                  subtitle: _epiphanySubtitle,
                  visualProfile: visualProfile,
                  reduceMotion: settings?.reduceMotion ?? false,
                ),
              ),
            ),
            // White-screen fade that plays after "WAKE UP" in finale_acceptance.
            _WakeUpFade(
              active: _wakeUpFading,
              reduceMotion: settings?.reduceMotion ?? false,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _BackgroundLayer extends StatelessWidget {
  final String backgroundPath;
  final bool flashActive;

  /// Override opacity — defaults to [_backgroundImageOpacity] (0.15).
  final double? opacity;

  const _BackgroundLayer({
    required this.backgroundPath,
    required this.flashActive,
    this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      backgroundPath,
      fit: BoxFit.cover,
      gaplessPlayback: true,
    );
    final child = flashActive
        ? image
        : ColorFiltered(
            colorFilter: const ColorFilter.matrix(
              _backgroundImageBrightnessMatrix,
            ),
            child: image,
          );

    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: flashActive ? 1.0 : (opacity ?? _backgroundImageOpacity),
        duration: flashActive ? Duration.zero : _backgroundFadeDuration,
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }
}

class _SuccessBloomLayer extends StatelessWidget {
  final bool active;
  final SectorVisualProfile visualProfile;
  final bool reduceMotion;

  const _SuccessBloomLayer({
    required this.active,
    required this.visualProfile,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 260);
    return AnimatedOpacity(
      opacity: active ? 1 : 0,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedScale(
        scale: active ? 1 : 0.975,
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.06),
              radius: 0.9,
              colors: [
                visualProfile.glow.withValues(alpha: 0.24),
                visualProfile.accent.withValues(alpha: 0.08),
                Colors.transparent,
              ],
              stops: const [0.0, 0.34, 1.0],
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: visualProfile.accent.withValues(alpha: 0.18),
                width: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VignetteLayer extends StatelessWidget {
  final int oblivionLevel; // 0–100

  const _VignetteLayer({required this.oblivionLevel});

  @override
  Widget build(BuildContext context) {
    // Base alpha 0.55, rises to 0.82 at full oblivion.
    final alpha = 0.55 + (oblivionLevel / 100) * 0.27;
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.6,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: alpha),
              ],
              stops: const [0.35, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectorAtmosphereLayer extends StatefulWidget {
  final SectorVisualProfile profile;
  final bool reduceMotion;

  const _SectorAtmosphereLayer({
    required this.profile,
    required this.reduceMotion,
  });

  @override
  State<_SectorAtmosphereLayer> createState() => _SectorAtmosphereLayerState();
}

class _SectorAtmosphereLayerState extends State<_SectorAtmosphereLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    if (!widget.reduceMotion) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl.value = 0.5;
    }
  }

  @override
  void didUpdateWidget(covariant _SectorAtmosphereLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion != oldWidget.reduceMotion) {
      if (widget.reduceMotion) {
        _ctrl.stop();
        _ctrl.value = 0.5;
      } else {
        _ctrl.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final drift = widget.reduceMotion ? 0.0 : (_ctrl.value - 0.5) * 0.08;
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.profile.veilGradient,
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, drift * 20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.45 + drift),
                    radius: 1.15,
                    colors: [
                      widget.profile.glow.withValues(alpha: 0.18),
                      widget.profile.glow.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.26, 0.7],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _GameMenuAction {
  newGame,
  saveLoad,
  archiveStatus,
  memories,
  howToPlay,
  settings,
  credits,
  title,
}

class _TopHud extends StatelessWidget {
  final String sectorLabel;
  final String nodeTitle;
  final Color narrativeColor;
  final SectorVisualProfile visualProfile;
  final double textScale;
  final ValueChanged<_GameMenuAction> onMenuSelected;
  final bool canReturnToTitle;

  const _TopHud({
    required this.sectorLabel,
    required this.nodeTitle,
    required this.narrativeColor,
    required this.visualProfile,
    required this.textScale,
    required this.onMenuSelected,
    required this.canReturnToTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sectorLabel.toUpperCase(),
                style: RitualTypography.command(
                  11 * textScale,
                  color: visualProfile.accent.withValues(alpha: 0.92),
                ).copyWith(letterSpacing: 1.5),
              ),
              const SizedBox(height: 4),
              Text(
                nodeTitle,
                style: RitualTypography.display(
                  24 * textScale,
                  color: narrativeColor,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<_GameMenuAction>(
          tooltip: 'Game menu',
          color: const Color(0xFF111216),
          onSelected: onMenuSelected,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: _GameMenuAction.newGame,
              child: Text('New game'),
            ),
            const PopupMenuItem(
              value: _GameMenuAction.saveLoad,
              child: Text('Save / Load'),
            ),
            const PopupMenuItem(
              value: _GameMenuAction.archiveStatus,
              child: Text('Archive status'),
            ),
            const PopupMenuItem(
              value: _GameMenuAction.memories,
              child: Text('Your memories'),
            ),
            const PopupMenuItem(
              value: _GameMenuAction.howToPlay,
              child: Text('How to play'),
            ),
            const PopupMenuItem(
              value: _GameMenuAction.settings,
              child: Text('Settings'),
            ),
            const PopupMenuItem(
              value: _GameMenuAction.credits,
              child: Text('Credits'),
            ),
            if (canReturnToTitle)
              const PopupMenuItem(
                value: _GameMenuAction.title,
                child: Text('Return to title'),
              ),
          ],
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: visualProfile.frame.withValues(alpha: 0.78),
              ),
            ),
            child: Icon(
              Icons.more_horiz,
              color: visualProfile.accent.withValues(alpha: 0.95),
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String sectorLabel;
  final String nodeTitle;
  final int itemCount;
  final int weight;
  final Color narrativeColor;
  final SectorVisualProfile visualProfile;
  final double textScale;
  final bool showAssist;
  final bool typewriterRunning;

  const _SessionCard({
    required this.sectorLabel,
    required this.nodeTitle,
    required this.itemCount,
    required this.weight,
    required this.narrativeColor,
    required this.visualProfile,
    required this.textScale,
    required this.showAssist,
    required this.typewriterRunning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.23),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: visualProfile.frame.withValues(alpha: 0.72)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$sectorLabel · $nodeTitle',
            style: RitualTypography.command(
              11.5 * textScale,
              color: visualProfile.accent.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$itemCount carried  ·  weight $weight  ·  autosave active',
            style: RitualTypography.ritualSans(
              13.2 * textScale,
              color: narrativeColor.withValues(alpha: 0.80),
            ),
          ),
          if (showAssist) ...[
            const SizedBox(height: 8),
            Text(
              typewriterRunning
                  ? 'Tap the narrative to reveal the full line instantly.'
                  : 'Short commands work best. Some mistakes still change the atmosphere; others pass without opening anything yet.',
              style: TextStyle(
                color: narrativeColor.withValues(alpha: 0.68),
                fontSize: 12.2 * textScale,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final String text;
  final MessageRole role;
  final Color narrativeColor;
  final SectorVisualProfile visualProfile;
  final bool showCursor;
  final double textScale;
  final TypewriterTextSpeed typewriterSpeed;
  final bool revealAll;
  final VoidCallback? onRevealComplete;

  const _MessageTile({
    required this.text,
    required this.role,
    required this.narrativeColor,
    required this.visualProfile,
    this.showCursor = false,
    required this.textScale,
    this.typewriterSpeed = TypewriterTextSpeed.instant,
    this.revealAll = true,
    this.onRevealComplete,
  });

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case MessageRole.player:
        // Split `> command` so the prompt glyph stays muted and the
        // command itself is rendered in the archive gold.
        final promptMatch = RegExp(r'^(>\s*)(.*)$').firstMatch(text);
        final promptGlyph = promptMatch?.group(1) ?? '';
        final commandText = promptMatch?.group(2) ?? text;
        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: promptGlyph,
                  style: RitualTypography.command(
                    14 * textScale,
                    color: Colors.white.withValues(alpha: 0.42),
                  ),
                ),
                TextSpan(
                  text: commandText,
                  style: RitualTypography.command(
                    14 * textScale,
                    color: visualProfile.accent,
                  ),
                ),
              ],
            ),
          ),
        );

      case MessageRole.narrative:
        return Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 12),
          child: TypewriterTextWidget(
            text: text,
            speed: typewriterSpeed,
            revealAll: revealAll,
            showCursor: showCursor,
            onComplete: onRevealComplete,
            style: RitualTypography.narrative(
              17 * textScale,
              color: narrativeColor,
            ),
          ),
        );

      case MessageRole.error:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.red.shade300,
              fontFamily: RitualTypography.command(12).fontFamily,
              fontSize: 13 * textScale,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
    }
  }
}

class TypewriterTextWidget extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TypewriterTextSpeed speed;
  final bool revealAll;
  final bool showCursor;
  final VoidCallback? onComplete;

  const TypewriterTextWidget({
    super.key,
    required this.text,
    required this.style,
    this.speed = TypewriterTextSpeed.normal,
    this.revealAll = false,
    this.showCursor = false,
    this.onComplete,
  });

  @override
  State<TypewriterTextWidget> createState() => _TypewriterTextWidgetState();
}

class _TypewriterTextWidgetState extends State<TypewriterTextWidget> {
  Timer? _timer;
  int _visibleCharacters = 0;
  bool _completionReported = false;

  @override
  void initState() {
    super.initState();
    _resetReveal();
  }

  @override
  void didUpdateWidget(covariant TypewriterTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.speed != widget.speed ||
        oldWidget.revealAll != widget.revealAll) {
      _resetReveal();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetReveal() {
    _timer?.cancel();
    _completionReported = false;

    if (widget.revealAll || widget.speed == TypewriterTextSpeed.instant) {
      _visibleCharacters = widget.text.length;
      _reportComplete();
      return;
    }

    _visibleCharacters = 0;
    _scheduleNextCharacter();
  }

  void _scheduleNextCharacter() {
    if (_visibleCharacters >= widget.text.length) {
      _reportComplete();
      return;
    }

    _timer = Timer(_delayForNextCharacter(), () {
      if (!mounted) return;
      setState(() {
        _visibleCharacters = min(widget.text.length, _visibleCharacters + 1);
      });
      _scheduleNextCharacter();
    });
  }

  Duration _delayForNextCharacter() {
    final char = widget.text[_visibleCharacters];
    final baseMilliseconds = switch (widget.speed) {
      TypewriterTextSpeed.slow => 72,
      TypewriterTextSpeed.normal => 26,
      TypewriterTextSpeed.instant => 0,
    };
    final multiplier = (char == ' ' || char == '\n') ? 0.45 : 1.0;
    return Duration(milliseconds: (baseMilliseconds * multiplier).round());
  }

  void _reportComplete() {
    if (_completionReported) return;
    _completionReported = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onComplete?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleText = widget.text.substring(
      0,
      min(_visibleCharacters, widget.text.length),
    );
    return RichText(
      text: TextSpan(
        text: visibleText,
        style: widget.style,
        children: widget.showCursor
            ? [
                TextSpan(
                  text: '▌',
                  style: widget.style.copyWith(
                    color: widget.style.color?.withValues(alpha: 0.7),
                    fontSize: (widget.style.fontSize ?? 14) * 0.82,
                  ),
                ),
              ]
            : null,
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final int weight;
  final int itemCount;
  final Set<String> completedPuzzles;
  final PsychoProfile? profile;
  final Color color;
  final SectorVisualProfile visualProfile;
  final double textScale;
  final String? lastCommand;

  const _StatusBar({
    required this.weight,
    required this.itemCount,
    required this.completedPuzzles,
    required this.profile,
    required this.color,
    required this.visualProfile,
    required this.textScale,
    this.lastCommand,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Tooltip(
        message:
            'Lucidity · Anxiety · Oblivion — these shape the Archive’s response.',
        preferBelow: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lastCommand == null
                        ? 'Carrying: $itemCount  ·  Weight: $weight'
                        : 'Carrying: $itemCount  ·  Weight: $weight  ·  Last: $lastCommand',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontFamily: RitualTypography.command(11).fontFamily,
                      fontSize: 11.3 * textScale,
                      letterSpacing: 0.58,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _PsycheMiniBar(
              label: 'Lucidity',
              value: profile?.lucidity ?? 50,
              color: const Color(0xFFDCC58A),
              visualProfile: visualProfile,
            ),
            const SizedBox(height: 4),
            _PsycheMiniBar(
              label: 'Anxiety',
              value: profile?.anxiety ?? 10,
              color: const Color(0xFFC97C7C),
              visualProfile: visualProfile,
            ),
            const SizedBox(height: 4),
            _PsycheMiniBar(
              label: 'Oblivion',
              value: profile?.oblivionLevel ?? 0,
              color: const Color(0xFF879EC4),
              visualProfile: visualProfile,
            ),
            const SizedBox(height: 8),
            _ProgressConstellation(
              milestones: _progressMilestones,
              completedPuzzles: completedPuzzles,
              visualProfile: visualProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressConstellation extends StatelessWidget {
  final List<_ProgressMilestone> milestones;
  final Set<String> completedPuzzles;
  final SectorVisualProfile visualProfile;

  const _ProgressConstellation({
    required this.milestones,
    required this.completedPuzzles,
    required this.visualProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Fragments',
          style: TextStyle(
            color: visualProfile.accent.withValues(alpha: 0.72),
            fontSize: 10.6,
            letterSpacing: 0.45,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              for (int i = 0; i < milestones.length; i++)
                _ProgressDot(
                  index: i + 1,
                  milestone: milestones[i],
                  unlocked: completedPuzzles.contains(milestones[i].key),
                  visualProfile: visualProfile,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressDot extends StatelessWidget {
  final int index;
  final _ProgressMilestone milestone;
  final bool unlocked;
  final SectorVisualProfile visualProfile;

  const _ProgressDot({
    required this.index,
    required this.milestone,
    required this.unlocked,
    required this.visualProfile,
  });

  @override
  Widget build(BuildContext context) {
    final fill = unlocked
        ? visualProfile.accent.withValues(alpha: 0.92)
        : Colors.transparent;
    final border = unlocked
        ? visualProfile.accent.withValues(alpha: 0.95)
        : visualProfile.frame.withValues(alpha: 0.55);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        if (!unlocked) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Fragment $index not revealed yet.'),
              duration: const Duration(milliseconds: 1200),
            ),
          );
          return;
        }
        // ignore: discarded_futures
        AudioService().handleTrigger('reward_bach');
        messenger.showSnackBar(
          SnackBar(
            content: Text('${milestone.label}: ${milestone.trackTitle}'),
            duration: const Duration(milliseconds: 1700),
          ),
        );
      },
      child: Tooltip(
        message: unlocked
            ? '${milestone.label} · ${milestone.trackTitle}'
            : '${milestone.label} · locked',
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(color: border, width: 1.2),
            boxShadow: unlocked
                ? [
                    BoxShadow(
                      color: visualProfile.glow.withValues(alpha: 0.32),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

class _PsycheMiniBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final SectorVisualProfile visualProfile;

  const _PsycheMiniBar({
    required this.label,
    required this.value,
    required this.color,
    required this.visualProfile,
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0, 100).toDouble();
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.82),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.55,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: clampedValue / 100,
              minHeight: 6,
              backgroundColor: visualProfile.frame.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}

class _PuzzleSolvedOverlay extends StatelessWidget {
  final bool active;
  final String title;
  final String subtitle;
  final SectorVisualProfile visualProfile;
  final bool reduceMotion;

  const _PuzzleSolvedOverlay({
    required this.active,
    required this.title,
    required this.subtitle,
    required this.visualProfile,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1 : 0,
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
      child: AnimatedScale(
        scale: active ? 1 : 0.96,
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      visualProfile.glow.withValues(alpha: 0.26),
                      visualProfile.accent.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.34, 1.0],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.56),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: visualProfile.accent.withValues(alpha: 0.9),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: visualProfile.glow.withValues(alpha: 0.22),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '✦',
                      style: TextStyle(
                        color: visualProfile.accent,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFF3E8CF),
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.62,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFD6CCB2),
                        fontSize: 12.3,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimulacrumBanner extends StatelessWidget {
  final String? text;
  final SectorVisualProfile visualProfile;
  final bool reduceMotion;

  const _SimulacrumBanner({
    required this.text,
    required this.visualProfile,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
      offset: text == null ? const Offset(0, -1.1) : Offset.zero,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: text == null ? 0 : 1,
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF17120A).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: visualProfile.accent),
              boxShadow: [
                BoxShadow(
                  color: visualProfile.glow.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              text ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFF1E5C9),
                fontWeight: FontWeight.w600,
                fontFamily: RitualTypography.ritualSans(12).fontFamily,
                letterSpacing: 0.45,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EpiphanyPopup extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final SectorVisualProfile visualProfile;
  final bool reduceMotion;

  const _EpiphanyPopup({
    required this.title,
    required this.subtitle,
    required this.visualProfile,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    final active = title != null && subtitle != null;
    return AnimatedSlide(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
      offset: active ? Offset.zero : const Offset(0, -0.9),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: active ? 1 : 0,
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1114).withValues(alpha: 0.93),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: visualProfile.accent.withValues(alpha: 0.9),
              ),
              boxShadow: [
                BoxShadow(
                  color: visualProfile.glow.withValues(alpha: 0.26),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFF4E8CC),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.55,
                    fontSize: 12.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD6CCB2),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.32,
                    fontSize: 11.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InputShakeWrapper extends StatefulWidget {
  final Widget child;

  const _InputShakeWrapper({super.key, required this.child});

  @override
  State<_InputShakeWrapper> createState() => _InputShakeWrapperState();
}

class _InputShakeWrapperState extends State<_InputShakeWrapper> {
  int _shakeTick = 0;

  void triggerShake() {
    setState(() => _shakeTick++);
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(_shakeTick),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final offset = sin(value * pi * 6) * (1 - value) * 7;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _InputRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final ValueChanged<String> onTextChanged;
  final bool enabled;
  final Color narrativeColor;
  final SectorVisualProfile visualProfile;
  final double textScale;
  final String hintText;
  final VoidCallback? onRecallLast;
  final VoidCallback? onWalkthroughNext;

  const _InputRow({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.onTextChanged,
    required this.enabled,
    required this.narrativeColor,
    required this.visualProfile,
    required this.textScale,
    required this.hintText,
    this.onRecallLast,
    this.onWalkthroughNext,
  });

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder lets the border glow react to focus without a
    // StatefulWidget — FocusNode already extends ChangeNotifier.
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final hasFocus = focusNode.hasFocus && enabled;
        final borderColor = hasFocus
            ? visualProfile.accent.withValues(alpha: 0.82)
            : visualProfile.frame.withValues(alpha: 0.62);

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: hasFocus
                          ? visualProfile.glow.withValues(alpha: 0.18)
                          : Colors.black.withValues(alpha: 0.06),
                      blurRadius: 22,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Row(
                  children: [
                    if (onRecallLast != null)
                      IconButton(
                        tooltip: 'Reuse last command',
                        onPressed: onRecallLast,
                        icon: Icon(
                          Icons.history,
                          color: narrativeColor.withValues(
                              alpha: enabled ? 0.65 : 0.25),
                        ),
                      ),
                    if (onWalkthroughNext != null)
                      IconButton(
                        tooltip: 'Next walkthrough step',
                        onPressed: onWalkthroughNext,
                        icon: Icon(
                          Icons.arrow_forward,
                          color: narrativeColor.withValues(
                              alpha: enabled ? 0.65 : 0.25),
                        ),
                      ),
                    Text(
                      '>',
                      style: TextStyle(
                        color: narrativeColor.withValues(
                            alpha: enabled ? 0.8 : 0.3),
                        fontFamily: RitualTypography.command(16).fontFamily,
                        fontSize: 16 * textScale,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        enabled: enabled,
                        autofocus: true,
                        textInputAction: TextInputAction.send,
                        onChanged: onTextChanged,
                        onSubmitted: (_) => onSubmit(),
                        style: TextStyle(
                          color: narrativeColor,
                          fontFamily: RitualTypography.command(15).fontFamily,
                          fontSize: 15.8 * textScale,
                        ),
                        cursorColor: narrativeColor,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: enabled ? hintText : '…',
                          hintStyle: TextStyle(
                            color: narrativeColor.withValues(alpha: 0.25),
                            fontFamily: RitualTypography.command(14).fontFamily,
                            fontSize: 14 * textScale,
                          ),
                          suffixIcon: IconButton(
                            tooltip: 'Send',
                            onPressed: enabled ? onSubmit : null,
                            icon: Icon(
                              Icons.send_rounded,
                              size: 20,
                              color: enabled
                                  ? visualProfile.accent
                                  : Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                        textCapitalization: TextCapitalization.none,
                        autocorrect: false,
                        enableSuggestions: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Finale widgets ────────────────────────────────────────────────────────────

/// Atmospheric backdrop overlay shown when the player is in a finale node.
/// - Acceptance  : warm, faint golden wash — the Archive grows luminous.
/// - Oblivion    : progressive black overlay that darkens over 8 seconds.
/// - Eternal Zone: cold blue-grey tint — the Zone has claimed you.
class _FinaleBackdrop extends StatefulWidget {
  final _FinaleType type;
  final bool reduceMotion;

  const _FinaleBackdrop({required this.type, this.reduceMotion = false});

  @override
  State<_FinaleBackdrop> createState() => _FinaleBackdropState();
}

class _FinaleBackdropState extends State<_FinaleBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (widget.type == _FinaleType.oblivion) {
      if (widget.reduceMotion) {
        _ctrl.value = 1.0;
      } else {
        _ctrl.forward();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: switch (widget.type) {
          _FinaleType.acceptance => Container(
              color: const Color(0xFFD4A017).withValues(alpha: 0.07),
            ),
          _FinaleType.oblivion => AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Container(
                color: Colors.black.withValues(alpha: _ctrl.value * 0.68),
              ),
            ),
          _FinaleType.eternalZone => Container(
              color: const Color(0xFF1A3A5C).withValues(alpha: 0.14),
            ),
          _FinaleType.testimony => Container(
              color: const Color(0xFF8B6A3F).withValues(alpha: 0.11),
            ),
        },
      ),
    );
  }
}

/// White-screen fade triggered by the "WAKE UP" epilogue in finale_acceptance.
/// Fades from transparent to fully white over 4 seconds.
class _WakeUpFade extends StatelessWidget {
  final bool active;
  final bool reduceMotion;

  const _WakeUpFade({required this.active, this.reduceMotion = false});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: active ? 1.0 : 0.0,
          duration: reduceMotion ? Duration.zero : const Duration(seconds: 4),
          curve: Curves.easeInOut,
          child: Container(color: Colors.white),
        ),
      ),
    );
  }
}
