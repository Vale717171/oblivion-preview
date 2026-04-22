# Release Audit — 2026-04-21

## 1. Current Build State

Repository baseline:

- Branch: `main`
- HEAD: `1d2afaf`
- Project root: `/Users/valentinoricco/Development/archive-of-oblivion`

The game already has a strong structural base:

- sector modules extracted and playable
- persistence and progression systems in place
- home screen with save summary and stronger presentation
- game screen with typewriter narrative, psycho bars, fragment progress dots
- ambient pilot pass in three spaces: Threshold, Garden, Observatory
- Bach reward cue logic implemented in the audio service

This means the project is not blocked by missing foundations.
The problem is not "there is no game".
The problem is "the game does not yet feel magnetic enough".

## 2. What Exists In The Build

### Visual/UI

- Splash screen with cinematic title reveal in `lib/features/ui/splash_screen.dart`
- Home screen with current-run card in `lib/features/ui/home_screen.dart`
- In-game layered visual system in `lib/features/ui/game_screen.dart`
- Psycho bars + fragment constellation in `lib/features/ui/game_screen.dart`
- Epiphany popup system in `lib/features/ui/game_screen.dart`

### Audio

- Reward-first Bach logic in `lib/features/audio/audio_service.dart`
- Ambient routing by sector in `lib/features/audio/audio_track_catalog.dart`
- Repository-generated ambient files:
  - `assets/audio/ambient_soglia_air.ogg`
  - `assets/audio/ambient_giardino_water.ogg`
  - `assets/audio/ambient_osservatorio_metal.ogg`

### Progression/Feedback

- Milestone fragments are visible and clickable in `lib/features/ui/game_screen.dart`
- Puzzle solved cue exists
- Simulacrum banner exists
- Psycho shift cue exists

## 3. What Is Not Working Yet

### A. The game still does not create enough desire to continue

The central issue is not content quantity.
It is motivational rhythm.

Right now the player still spends too much time in a single mode:

- read text
- type command
- receive more text

Even when rewards exist, they do not yet dominate the emotional memory of play.

### B. Typewriter is still the default experience

The typewriter remains the main pacing device of the entire game.
That makes every room feel more similar than it should.

Result:

- the sectors differ conceptually
- but the moment-to-moment feeling still tends to flatten

### C. Audio direction is only partially unified

The new sound direction exists only in pilots.

Current state:

- Threshold: new ambient pilot
- Garden: new ambient pilot
- Observatory: new ambient pilot
- other sectors: still not fully translated into the same world-sound language

Result:

- the game does not yet sound like one authored whole
- it sounds like a project transitioning between two audio philosophies

### D. Visual upgrades are present, but not forceful enough

There are visual improvements in the codebase.
But they are not landing as a clear experiential jump.

If the player says "I don't really see the graphic improvements", then for release purposes the improvements are not doing enough.

This usually means one of three things:

- they are too subtle
- they are too localized
- they are fighting a stronger monotony in the flow itself

### E. Feedback layers are additive, not yet compositional

There are several good ideas in the build:

- popup epiphanies
- fragment dots
- haptics
- reward Bach
- simulacrum banners

But they do not yet feel orchestrated under one clear directorial rule.

## 4. Core Diagnosis

The project currently has:

- good architecture
- good thematic identity
- good ambition
- insufficient release coherence

The missing piece is not another feature.
The missing piece is a unified experiential rule set.

## 5. Release Vision

### One-sentence target

The Archive of Oblivion should feel like a ritual journey through distinct emotional chambers, where the world is carried by silence, material sound, and minimal atmosphere, and Bach appears only as a hard-won spiritual revelation.

### Design consequences

#### Sound

- the world should sound present even when "nothing happens"
- ambient should be concrete and tactile: air, water, metal, paper, resonance
- minimal music should support, not announce itself
- Bach must never become furniture

#### Rhythm

- reading cannot remain the only dominant mode
- the game must alternate:
  - waiting
  - revelation
  - friction
  - reward
  - curiosity

#### Visual identity

- each sector must feel like a different chamber of the same ritual world
- differences must be readable quickly, not only conceptually
- visual shifts should support anticipation and mystery

#### Reward logic

- not every success deserves the same response
- small success, medium revelation, sector breakthrough, and spiritual unveiling must feel different

## 6. What The Game Needs Most

### Priority 1

Reduce monotony in the main loop.

This is the highest priority because it directly controls appeal.

### Priority 2

Unify the audio grammar across the whole run.

Without this, the player cannot feel one intentional journey from title to finale.

### Priority 3

Make visual change more legible across sectors and moments of progress.

The player must feel advancement, not only understand it intellectually.

## 7. Five Priority Interventions

### 1. Define one feedback hierarchy for the whole game

Create a single rule table for:

- minor response
- solved puzzle
- simulacrum recovery
- fragment reveal
- sector transition
- major revelation
- finale threshold

Without this, rewards remain inconsistent.

### 2. Expand the pilot sound grammar to the entire run

Do not add random new sounds.
Translate the whole game into the same structure:

- world sound
- minimal ambient support
- Bach only as revelation

### 3. Reduce typewriter dominance

Keep it, but stop letting it define every moment.
Some text should land differently:

- immediate appearance
- weighted line reveal
- epiphany emphasis
- silence before response

### 4. Re-author sector identity at the experience level

For each sector, define:

- dominant material sound
- visual atmosphere
- rhythm of command/reward
- emotional role in the run

If this is not explicit, sectors collapse into one another.

### 5. Build a release slice and judge only that slice

Choose one representative slice:

- title
- threshold
- garden
- observatory
- one true reward moment

Treat that as the release prototype.
Do not continue broad expansion until that slice feels genuinely compelling.

## 8. Immediate Conclusion

The game is structurally alive but emotionally underpowered.

The next phase should not be "more additions".
It should be:

- consolidation
- hierarchy
- authorship
- selective intensification

The release target is not "complete content".
It is "coherent seduction".
