import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/demiurge/demiurge_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DemiurgeEntry', () {
    test('formats an entry for display', () {
      const entry = DemiurgeEntry(
        opening: 'The Archive is listening.',
        citation: 'Know thyself.',
        author: 'Socrates',
        closing: 'All That Is waits.',
      );

      expect(
        entry.format(),
        'The Archive is listening.\n\n"Know thyself."\n— Socrates\n\nAll That Is waits.',
      );
    });
  });

  group('DemiurgeService.sectorForNode', () {
    test('maps known sector prefixes', () {
      expect(DemiurgeService.sectorForNode('garden_cypress'), 'garden');
      expect(DemiurgeService.sectorForNode('threshold'), 'garden');
      expect(DemiurgeService.sectorForNode('obs_dome'), 'osservatorio');
      expect(DemiurgeService.sectorForNode('gal_copies'), 'galleria');
      expect(DemiurgeService.sectorForNode('lab_furnace'), 'laboratorio');
    });

    test('falls back to universale for unmatched nodes', () {
      expect(DemiurgeService.sectorForNode('quinto_landing'), 'universale');
      expect(DemiurgeService.sectorForNode('finale_acceptance'), 'universale');
    });
  });

  group('DemiurgeService phase management', () {
    final service = DemiurgeService.instance;

    setUp(() {
      service.restorePhase(1);
    });

    tearDown(() {
      service.restorePhase(1);
    });

    test('switchPhase only advances forward', () {
      service.restorePhase(3);

      service.switchPhase(2);
      expect(service.currentPhase, 3);

      service.switchPhase(5);
      expect(service.currentPhase, 5);
    });

    test('restorePhase supports save-load and reset rollback', () {
      service.restorePhase(5);
      service.restorePhase(2);

      expect(service.currentPhase, 2);
    });
  });

  group('DemiurgeService preview loading', () {
    test('loads only the public preview citation bundles', () async {
      final service = DemiurgeService.instance;

      await service.loadPreviewBundles();

      expect(
        service.loadedSectorKeys,
        containsAll(DemiurgeService.previewSectorKeys),
      );
      expect(
        service.loadedSectorKeys.difference(
          DemiurgeService.previewSectorKeys.toSet(),
        ),
        isEmpty,
      );
    });
  });
}
