# Web Playtest Checklist

Purpose: verify the public Itch.io preview in a browser before publishing.

## Setup

```bash
flutter pub get
flutter test
flutter build web
```

Serve `build/web/` locally or upload a draft build to Itch.io.

## Browsers

Check at least:

- Chrome
- Safari
- Firefox

## Flow

- Splash appears cleanly.
- Title screen appears with “The Archive of Oblivion”.
- Bach starts with the title/title reveal.
- First typed command causes Bach to fade gradually.
- Ambient sound or evocative noise continues after Bach ends.
- The player can reach La Soglia.
- The player can reach Il Giardino.
- The first Bach revelation triggers only at the intended moment.
- The preview ending appears.
- Later sectors are not reachable from the public slice.

## Parser

- Intended commands work.
- Near-synonyms are accepted where the room text strongly suggests them.
- Wrong commands produce Demiurge/cultural responses.
- Repeated wrong commands do not feel like identical generic errors.
- The player can infer the solution path from nouns, verbs, and motifs in the text.

## UI

- Text remains readable at common desktop and laptop viewport sizes.
- Input remains focused after command submission.
- Typewriter pacing is legible.
- Settings remain usable.
- No important text overlaps the command input.

## Audio

- Browser autoplay restrictions are handled by user interaction.
- Bach does not restart unexpectedly.
- Bach fades rather than stopping abruptly.
- Ambient loops do not click at loop boundaries.
- UI sounds do not overpower the narrative audio.

## Persistence

- A refreshed browser tab restores reasonable local state.
- New game/reset returns to the beginning of the preview.
- Save/load UI, if exposed, does not break the preview boundary.
