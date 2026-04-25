# Universal Session Prompt

You are contributing to *L'Archivio dell'Oblio*, a Flutter Web text adventure preview for Itch.io.

The project is web-only. Keep build, test, and release work focused on the browser preview.

## Current Preview

Splash -> Home -> La Soglia -> Il Giardino -> first Bach revelation -> preview ending.

Keep all work inside this public slice unless explicitly asked to expand it.

## Product Intent

The game should feel like an oneiric archive that teaches through both success and failure. Wrong commands are not dead ends: they are a core learning and atmosphere system.

## Engineering Intent

- Prefer deterministic, testable behavior.
- Keep the parser fair.
- Preserve the Demiurge citation system.
- Keep audio transitions smooth.
- Build and verify for browser release.

## Standard Checks

```bash
flutter test
flutter build web
```
