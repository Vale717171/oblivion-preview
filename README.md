# L'Archivio dell'Oblio

Public web preview of *L'Archivio dell'Oblio*, a psycho-philosophical text adventure built with Flutter Web for Itch.io.

The current release target is deliberately narrow:

1. Splash
2. Home
3. Threshold
4. Garden
5. First Bach revelation
6. Preview ending screen

Everything in this repository should serve that playable browser slice.

## Run Locally

```bash
flutter pub get
flutter run -d chrome
```

For the distributable preview:

```bash
flutter build web
```

The generated files in `build/web/` are the artifact to upload to Itch.io.

## Project Shape

- `lib/`: Flutter webapp source
- `assets/audio/`: Bach, ambient loops, UI sounds, and narrative cues
- `assets/images/`: room backgrounds used by the preview
- `assets/texts/demiurge/`: deterministic citation pools for wrong-command responses
- `docs/`: design, release contract, playtest notes, and implementation status
- `test/`: parser, game flow, garden module, UI, and service tests

## Key Docs

- [docs/preview_scope.md](docs/preview_scope.md): current preview boundary
- [docs/release_slice_contract.md](docs/release_slice_contract.md): what belongs in the public slice
- [docs/web_playtest_checklist.md](docs/web_playtest_checklist.md): browser QA checklist
- [docs/gdd.md](docs/gdd.md): webapp-focused game design document
- [docs/audio_asset_pipeline.md](docs/audio_asset_pipeline.md): audio workflow for the Itch.io build

## Verification

Before publishing a preview build:

```bash
flutter test
flutter build web
```

Then run the browser checklist against `build/web/` or a local web server.
