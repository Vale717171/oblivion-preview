import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/audio/audio_track_catalog.dart';
import 'package:archive_of_oblivion/features/ui/background_service.dart';

void main() {
  group('AudioTrackCatalog', () {
    test('returns explicit overrides for special nodes', () {
      expect(AudioTrackCatalog.trackForNode('quinto_landing'), 'siciliano');
      expect(
          AudioTrackCatalog.trackForNode('finale_acceptance'), 'aria_goldberg');
      expect(AudioTrackCatalog.trackForNode('finale_oblivion'), 'silence');
      expect(
          AudioTrackCatalog.trackForNode('preview_epilogue'), 'aria_goldberg');
      expect(AudioTrackCatalog.trackForNode('la_zona'), 'zona');
    });

    test('falls back to sector base tracks when no node override exists', () {
      expect(AudioTrackCatalog.trackForNode('garden_cypress'), 'garden');
      expect(AudioTrackCatalog.trackForNode('obs_library'), 'osservatorio');
      expect(AudioTrackCatalog.trackForNode('lab_substances'), 'laboratorio');
      expect(AudioTrackCatalog.trackForNode('unknown_node'), 'threshold');
    });

    test('recognises explicit track keys', () {
      expect(AudioTrackCatalog.isExplicitTrack('siciliano'), isTrue);
      expect(AudioTrackCatalog.isExplicitTrack('aria_goldberg'), isTrue);
      expect(AudioTrackCatalog.isExplicitTrack('silence'), isTrue);
      expect(AudioTrackCatalog.isExplicitTrack('nonexistent_track'), isFalse);
      expect(
        AudioTrackCatalog.assetForKey('siciliano'),
        'assets/audio/bach_siciliano_bwv1017.ogg',
      );
      expect(AudioTrackCatalog.assetForKey('silence'), isNull);
      expect(
        AudioTrackCatalog.assetForKey('title_threshold'),
        'assets/audio/bach_aria_goldberg.ogg',
      );
    });

    test('keeps ambient beds available for gameplay sectors', () {
      expect(AudioTrackCatalog.ambientKeyForSector('threshold'),
          'ambient_threshold');
      expect(AudioTrackCatalog.ambientKeyForSector('garden'), 'ambient_garden');
      expect(AudioTrackCatalog.ambientKeyForSector('osservatorio'),
          'ambient_osservatorio');
      expect(AudioTrackCatalog.ambientKeyForSector('galleria'),
          'universal_ambient');
      expect(AudioTrackCatalog.ambientKeyForSector('memoria'), isNull);
    });

    test('exposes per-track mix bias only for calibrated outliers', () {
      expect(AudioTrackCatalog.mixVolumeBiasForKey('threshold'), 0.10);
      expect(AudioTrackCatalog.mixVolumeBiasForKey('aria_goldberg'), 0.08);
      expect(AudioTrackCatalog.mixVolumeBiasForKey('galleria_dark'), -0.07);
      expect(AudioTrackCatalog.mixVolumeBiasForKey('garden_fountain'), 0.0);
      expect(AudioTrackCatalog.mixVolumeBiasForKey('nonexistent_track'), 0.0);
    });

    test('exposes node-specific mix nudges for cinematic rooms', () {
      expect(AudioTrackCatalog.mixVolumeBiasForNode('garden_fountain'), 0.04);
      expect(AudioTrackCatalog.mixVolumeBiasForNode('gallery_central'), 0.04);
      expect(AudioTrackCatalog.mixVolumeBiasForNode('preview_epilogue'), 0.05);
      expect(AudioTrackCatalog.mixVolumeBiasForNode('unknown_node'), 0.0);
      expect(AudioTrackCatalog.mixVolumeBiasForNode(null), 0.0);
    });

    test('maps representative nodes to expected sectors', () {
      expect(AudioTrackCatalog.sectorForNode('intro_void'), 'threshold');
      expect(AudioTrackCatalog.sectorForNode('preview_epilogue'), 'threshold');
      expect(AudioTrackCatalog.sectorForNode('gallery_light'), 'galleria');
      expect(
          AudioTrackCatalog.sectorForNode('quinto_ritual_chamber'), 'memoria');
      expect(AudioTrackCatalog.sectorForNode('finale_oblivion'), 'memoria');
      expect(AudioTrackCatalog.sectorForNode('unknown_node'), 'threshold');
    });

    test(
        'keeps audio and background sector families aligned for representative nodes',
        () {
      expect(AudioTrackCatalog.sectorForNode('garden_fountain'), 'garden');
      expect(
        BackgroundService.getBackgroundForNode('garden_fountain'),
        'assets/images/garden_bg.jpg',
      );

      expect(AudioTrackCatalog.sectorForNode('preview_epilogue'), 'threshold');
      expect(
        BackgroundService.getBackgroundForNode('preview_epilogue'),
        'assets/images/threshold_bg.jpg',
      );

      expect(AudioTrackCatalog.sectorForNode('quinto_landing'), 'memoria');
      expect(
        BackgroundService.getBackgroundForNode('quinto_landing'),
        'assets/images/bg_memoria.jpg',
      );

      expect(AudioTrackCatalog.sectorForNode('la_zona'), 'la_zona');
      expect(
        BackgroundService.getBackgroundForNode('la_zona'),
        'assets/images/bg_zona.jpg',
      );
    });
  });
}
