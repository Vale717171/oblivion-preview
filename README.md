# Oblivion Preview

A focused public preview of *L'Archivio dell'Oblio*, built with Flutter for Android and intended as an itch.io vertical slice.

This repository exists to build one compelling, polished slice rather than the full game. Its job is to answer a simple question: does the game create enough desire, atmosphere, and curiosity for players to ask for more?

## Current State

- Scope intentionally reduced to a preview-quality vertical slice.
- Current target slice: Splash -> Home -> Soglia -> Giardino -> first true Bach revelation -> preview ending prompt.
- The full production repo remains separate and is the place where long-form expansion continues.
- Automated verification stays active: `flutter test` and `flutter analyze` remain release gates for this slice.

## Stack

- Flutter
- Riverpod (`AsyncNotifier`-based state)
- sqflite
- just_audio

## Project Structure

- [lib/main.dart](lib/main.dart): app bootstrap, audio init, Demiurge preload
- [lib/features/game/game_engine_provider.dart](lib/features/game/game_engine_provider.dart): main game engine and progression logic
- [lib/features/parser/parser_service.dart](lib/features/parser/parser_service.dart): text parser
- [lib/features/demiurge/demiurge_service.dart](lib/features/demiurge/demiurge_service.dart): deterministic narrator
- [lib/features/ui/home_screen.dart](lib/features/ui/home_screen.dart): title/home experience
- [lib/features/ui/game_screen.dart](lib/features/ui/game_screen.dart): main game interface
- [docs/preview_scope.md](docs/preview_scope.md): exact public-preview scope and success criteria
- [docs/device_playtest_checklist.md](docs/device_playtest_checklist.md): physical-device QA checklist
- [docs/work_log.md](docs/work_log.md): chronological development log
- [docs/release_slice_contract.md](docs/release_slice_contract.md): non-negotiable rhythm/audio/feedback contract for the preview
- [CLAUDE.md](CLAUDE.md): current project briefing and source of truth for agent sessions

## Run And Verify

```bash
flutter pub get
flutter analyze
flutter test
```

## Content Pipeline

Demiurge bundles live in [assets/texts/demiurge](assets/texts/demiurge).

Relevant tools:

- [tools/prepare_demiurge_bundles.py](tools/prepare_demiurge_bundles.py): online generation with balancing and fallback supplementation
- [tools/audit_demiurge_bundles.py](tools/audit_demiurge_bundles.py): schema/count/duplicate/repeated-block validation
- [tools/curate_demiurge_bundles.py](tools/curate_demiurge_bundles.py): local repair of checked-in bundles
- [tools/audit_audio_assets.py](tools/audit_audio_assets.py): verify declared audio assets against the repository

## Preview Direction

- Keep only what serves the preview.
- Cut or ignore anything that weakens rhythm.
- Treat audio, pacing, and revelation as the real product.
- End the slice with a clear message asking for comments and interest.

## Audio Note

The compositions referenced by the project are public-domain works, but recordings are not automatically safe to download and ship. Any real audio assets added to the app should be verified for licensing before inclusion.

See [docs/audio_asset_pipeline.md](docs/audio_asset_pipeline.md) for the recommended import and verification flow.

The current checked-in audio is lawful and redistributable. All 22 runtime music cues now ship with curated `CC0` Bach masters by Kimiko Ishizaka, including the short `proustian_trigger` excerpt derived from the Goldberg Aria. See [assets/audio/ATTRIBUTION.md](assets/audio/ATTRIBUTION.md), [docs/audio_asset_pipeline.md](docs/audio_asset_pipeline.md), and [docs/audio_master_candidates.md](docs/audio_master_candidates.md) for provenance and follow-up polish work.
