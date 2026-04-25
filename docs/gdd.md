# Game Design Document

## Product

*L'Archivio dell'Oblio* is a browser-based psycho-philosophical text adventure built with Flutter Web and released as a public preview on Itch.io.

The preview is not a full game release. It is a polished vertical slice designed to establish tone, parser feel, wrong-command learning, ambient sound, and the first Bach revelation.

## Release Slice

The playable path is:

1. Splash
2. Home/title
3. La Soglia
4. Il Giardino
5. First Bach revelation
6. Preview ending

The preview should not expose later sectors as playable content.

## Experience Pillars

- Text as a playable space: commands are verbs of attention, memory, and interpretation.
- Wrong commands matter: failed attempts should produce cultural, philosophical, or poetic fragments, not generic errors.
- Audio carries the threshold: Bach opens the title experience, fades when interaction begins, then leaves an ambient, suspended sound bed.
- The parser should be demanding but fair: solutions should emerge from room text, repeated motifs, and consistent verb families.
- The browser build must feel complete enough to publish, even while clearly ending at a preview boundary.

## Core Loop

1. Read the room.
2. Try a command.
3. Receive either progression or a meaningful response.
4. Notice recurring words, objects, and metaphors.
5. Use those clues to cross the next threshold.

## Narrative Voice

The Demiurge is deterministic. It selects from bundled text pools and acts as the cultural counter-voice of the archive. It should feel intentional even when the player is wrong.

The player should never feel that a wrong command simply failed. The ideal wrong response says: you did not open the door, but you learned how this place thinks.

## Audio Direction

- Title: Bach begins with the initial title presence.
- First commands: Bach fades gradually rather than cutting.
- Exploration: ambient loops, sparse noises, and evocative cues maintain an oneiric atmosphere.
- Revelation: Bach can return as a meaningful event, not as accidental background repetition.

## Technical Direction

- Target: Flutter Web.
- Release artifact: `build/web/`.
- Persistence: local browser storage through the configured SQLite web backend.
- Audio: bundled assets, no runtime downloads.
- Text: bundled deterministic data, no runtime network dependency.

## QA Bar

The preview is ready when:

- The intended path is solvable from context.
- Wrong-command responses remain varied and educational.
- Bach starts at the title, fades on interaction, and does not restart accidentally.
- Ambient sound continues after the opening music.
- The preview ending is reachable and blocks accidental travel into later content.
- `flutter test` and `flutter build web` pass.
