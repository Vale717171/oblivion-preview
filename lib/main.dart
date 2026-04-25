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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Global error handlers — catch unhandled exceptions that would otherwise
  // silently crash the app and trigger Android's crash-restart loop.
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

  // Avoid runtime network font fetches on restricted/offline devices.
  GoogleFonts.config.allowRuntimeFetching = kIsWeb;

  // ProviderContainer necessario per inizializzare AudioService
  // prima di runApp (audio_service usa container.listen, non WidgetRef)
  final container = ProviderContainer();

  // Inizializza audio + sessione Android
  final audioService = AudioService();
  bool audioFailed = false;
  try {
    await audioService.initialize(container);
  } catch (e) {
    // Audio failure must not prevent the game from starting (GDD: text-only is valid)
    audioFailed = true;
    AppLogger.log('Archive', 'AudioService init failed: $e');
  }

  // Pre-load Demiurge citation bundles (deterministic narrator — GDD §5).
  try {
    if (kIsPreviewBuild) {
      await DemiurgeService.instance.loadPreviewBundles();
    } else {
      await DemiurgeService.instance.loadAll();
    }
  } catch (e) {
    // Bundle failure must not prevent the game from starting; fallback text is used.
    AppLogger.log('Archive', 'DemiurgeService preload failed: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MyApp(audioFailed: audioFailed),
    ),
  );
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
