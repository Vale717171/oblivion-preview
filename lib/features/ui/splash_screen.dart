// lib/features/ui/splash_screen.dart
//
// Explicit web-entry splash. Navigation only happens from the player's button
// press, which also gives the browser a trusted gesture for audio unlock.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../audio/audio_service.dart';
import '../settings/app_settings_provider.dart';
import 'game_screen.dart';

class SplashScreen extends SplashScreenWidget {
  const SplashScreen({super.key, super.audioFailed});
}

class SplashScreenWidget extends ConsumerStatefulWidget {
  const SplashScreenWidget({super.key, this.audioFailed = false});

  /// Kept for startup diagnostics compatibility.
  final bool audioFailed;

  @override
  ConsumerState<SplashScreenWidget> createState() => _SplashScreenWidgetState();
}

class _SplashScreenWidgetState extends ConsumerState<SplashScreenWidget> {
  bool _entering = false;

  Future<void> _enterArchive() async {
    if (_entering) return;
    setState(() => _entering = true);

    final settings = ref.read(appSettingsProvider).valueOrNull;
    if ((settings?.enableHaptics ?? true) &&
        !(settings?.reduceMotion ?? false)) {
      HapticFeedback.mediumImpact();
    }

    await _enterArchiveAudioWithRetry();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GameScreen(),
        transitionDuration: settings?.reduceMotion ?? false
            ? Duration.zero
            : const Duration(milliseconds: 700),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _enterArchiveAudioWithRetry() async {
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        await AudioService().enterArchiveAt('intro_void');
        return;
      } catch (e, stack) {
        AppLogger.log(
          'Archive',
          'Audio unlock attempt $attempt failed: $e',
          stack,
        );
        if (attempt == 1) {
          await Future<void>.delayed(const Duration(milliseconds: 180));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final reduceMotion = settings?.reduceMotion ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/threshold_bg.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(color: Colors.black.withValues(alpha: 0.48)),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'The Archive of Oblivion',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFE9E3D6),
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Public Preview',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFD4C7AE),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(height: 36),
                  FilledButton(
                    onPressed: _entering ? null : _enterArchive,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE9E3D6),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor:
                          const Color(0xFFE9E3D6).withValues(alpha: 0.45),
                      disabledForegroundColor: Colors.black54,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 34,
                        vertical: 17,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 160),
                      child: Text(
                        _entering ? 'Opening...' : 'Enter the Archive',
                        key: ValueKey(_entering),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Headphones recommended',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFD4C7AE),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
