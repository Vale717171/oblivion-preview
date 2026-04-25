# Audio Asset Pipeline

This pipeline supports the Flutter Web preview for Itch.io.

## Goals

- Bach starts with the title/title reveal.
- Bach fades when the player begins interacting.
- Ambient loops and sparse noises remain during exploration.
- Revelation cues are intentional and never triggered as accidental duplicate music.
- All audio is bundled with the web build.

## Asset Locations

- Source and generated audio: `assets/audio/`
- Flutter asset registration: `pubspec.yaml`
- Runtime control: `lib/features/audio/audio_service.dart`

## Recommended Format

- Use compressed web-friendly audio assets.
- Keep loop files short enough for fast loading.
- Add gentle fades to loop heads/tails where needed.
- Normalize perceived loudness across the preview, not just peak level.

## Workflow

1. Add or replace the audio file in `assets/audio/`.
2. Confirm the file is listed under Flutter assets in `pubspec.yaml`.
3. Wire the cue in `AudioService`.
4. Run:

```bash
flutter test
flutter build web
```

5. Play the browser build and check title, first command, ambient continuation, and revelation timing.

## Listening Pass

During each release pass, verify:

- no unexpected second Bach track starts after the title cue
- Bach fades out smoothly after initial interaction
- ambient sound remains audible but restrained
- wrong-command and UI sounds do not mask text pacing
- loop boundaries are not distracting

## Placeholder Audio

`tools/generate_placeholder_audio.py` may be used for lawful local placeholders. Replace placeholders with final assets before publishing when the cue is artistically important.
