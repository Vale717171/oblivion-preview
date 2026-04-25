# Development Guide

This repository now targets one product: the Flutter Web preview of *L'Archivio dell'Oblio* for Itch.io.

All implementation, testing, and documentation should serve the browser preview.

## Current Slice

The public preview is:

Splash -> Home -> Threshold -> Garden -> first Bach revelation -> preview ending.

Keep new work inside this boundary unless the task explicitly expands the web preview.

## Architecture

- Flutter Web UI in `lib/`
- Riverpod for state
- `sqflite_common` plus the web FFI backend for local persistence
- `just_audio` for browser playback
- deterministic Demiurge citation bundles for wrong-command responses
- local image and audio assets bundled with the web build

## Build And Test

```bash
flutter pub get
flutter test
flutter build web
```

The Itch.io artifact is `build/web/`.

## Development Rules

- Preserve the preview contract.
- Keep code paths deterministic and testable.
- Treat wrong commands as part of the game: they should teach, unsettle, or deepen the atmosphere.
- Audio is central to the reveal: Bach starts with the title experience, fades when play begins, and gives way to ambient sound.
- Keep the repository focused on the Itch.io web preview.
