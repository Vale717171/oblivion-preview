import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'core/config/build_config.dart';
import 'core/utils/app_logger.dart';
import 'features/audio/audio_service.dart';
import 'features/demiurge/demiurge_service.dart';
import 'features/ui/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  } catch (e, stack) {
    AppLogger.log('Bootstrap', 'Database initialization failed: $e', stack);
  }

  // Global error handlers: keep unhandled exceptions visible in debug logs.
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.log(
      'FlutterError',
      details.exceptionAsString(),
      details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    AppLogger.log('PlatformError', error, stack);
    return true; // mark as handled so the app does not terminate
  };

  // Avoid runtime network font fetches in restricted/offline browser sessions.
  GoogleFonts.config.allowRuntimeFetching = kIsWeb;

  // ProviderContainer necessario per inizializzare AudioService
  // (audio_service usa container.listen, non WidgetRef)
  final container = ProviderContainer();

  // Defer potentially blocking initialization tasks (like Audio and Demiurge)
  // until after runApp so the first frame is unblocked and the loading spinner disappears.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _deferredInitialization(container);
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(audioFailed: false),
    ),
  );
}

Future<void> _deferredInitialization(ProviderContainer container) async {
  // Initialize audio and the browser playback session.
  final audioService = AudioService();
  final audioFailed = !await _initializeAudioWithRetry(audioService, container);

  if (audioFailed) {
    AppLogger.log('Archive', 'AudioService deferred initialization failed.');
  }

  // Pre-load Demiurge citation bundles (deterministic narrator — GDD §5).
  try {
    Future<void> loadBundles = kIsPreviewBuild
        ? DemiurgeService.instance.loadPreviewBundles()
        : DemiurgeService.instance.loadAll();

    await loadBundles.timeout(const Duration(seconds: 4));
  } catch (e) {
    // Bundle failure must not prevent the game from starting; fallback text is used.
    AppLogger.log('Archive', 'DemiurgeService preload failed or timed out: $e');
  }
}

Future<bool> _initializeAudioWithRetry(
  AudioService audioService,
  ProviderContainer container,
) async {
  for (var attempt = 1; attempt <= 2; attempt++) {
    try {
      await audioService.initialize(container).timeout(const Duration(seconds: 4));
      return true;
    } catch (e, stack) {
      AppLogger.log(
        'Archive',
        'AudioService init attempt $attempt failed or timed out: $e',
        stack,
      );
      if (attempt == 1) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
  }
  // Audio failure must not prevent the game from starting (GDD: text-only is valid).
  return false;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.audioFailed = false});

  /// True when AudioService.initialize() threw at startup.
  /// Passed down so HomeScreen can show a one-time diagnostic banner.
  final bool audioFailed;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Archive of Oblivion Preview',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Georgia',
      ),
      home: SplashScreen(audioFailed: audioFailed),
    );
  }
}
