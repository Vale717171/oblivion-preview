# Implementation Status

## Target

The project targets a Flutter Web preview for Itch.io.

The active slice is:

Splash -> Home -> Threshold -> Garden -> first Bach revelation -> preview ending.

## Implemented

- Flutter Web app shell.
- Deterministic game engine for the preview slice.
- Parser and command handling.
- Demiurge citation responses for wrong commands.
- Local persistence through the configured SQLite web backend.
- Audio service with Bach, ambient, reward, and UI channels.
- Preview build flag and preview-only Demiurge bundle loading.

## Current Focus

- Keep the public slice narrow.
- Make command inference fair but not obvious.
- Preserve cultural wrong-command responses.
- Keep Bach and ambient audio emotionally coherent.
- Keep the repository documentation web-only.

## Verification

Use:

```bash
flutter test
flutter build web
```

Then run [web_playtest_checklist.md](web_playtest_checklist.md).
