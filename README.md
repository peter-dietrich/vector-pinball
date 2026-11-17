# Vector Pinball — Classic '82

An original hybrid-physical pinball game for macOS and the Fun City arcade.

## v0.4.0 — Vector Siege art preview

- The first themed pinball playfield is a **Vector Siege tribute**.
- Press **B** in-game to import the supplied portrait PNG background. It is stored in Application Support and reused on future launches.
- Dynamic ball, bumpers, flippers, targets and scoring remain independent overlay objects.
- The background fills and clips within the playfield without distorting the source art.
- Vector Barrage and Vector Drift themes are planned next; see [table roadmap](docs/TABLE_THEMES.md).
- Version identifier: `VECTOR SIEGE TABLE v0.4.0`.

**Mac test required:** Source is committed, but importing and rendering have not yet been verified through an actual macOS Xcode build.

## v0.3.0 — ball engine rebuild (Mac playtest required)

The ball now uses a fixed-step 120 Hz simulation with explicit table boundaries, target and bumper collisions, scoring, drain handling, and controlled flipper contact. The previous SpriteKit dynamic ball body and multiple competing impulse paths have been removed. The shooter lane still uses a scripted entry, but gameplay afterward is handled by one solver. A green `NEW BALL ENGINE v0.3.0` build identifier is visible on the playfield.

**Important:** This engine has been committed but has not yet been compiled or playtested on macOS. Do not assume gameplay quality or release readiness until local testing passes. This is a stabilization pass, not the promised full table art rebuild.

## v0.1.0 — playable prototype
- Native SwiftUI + SpriteKit macOS application.
- Classic '82 table: ball, two independently controlled flippers, spring plunger, pop bumpers, side walls, slingshot shapes and outlanes.
- Three-ball game, score, ball counter, high score with local storage, game over and restart.
- Native keyboard input, collision impulse feedback and optional debug HUD.
- Independent application bundle ID: `io.vectorpinball.game`.

## Run on Mac
Requires macOS 13+ and Xcode 16+.

```bash
cd ~/Documents/GitHub
git clone https://github.com/peter-dietrich/vector-pinball.git
cd vector-pinball
open VectorPinball.xcodeproj
```

In Xcode select **VectorPinball > My Mac** and press **Command-R**. If already cloned, use `git pull --ff-only origin main` instead.

Command-line verification:

```bash
xcodebuild -project VectorPinball.xcodeproj -scheme VectorPinball -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

## Controls
| Key | Action |
| --- | --- |
| Return | Start / restart game |
| B | Import/replace table background art |
| A or Left Shift | Left flipper (press and hold) |
| D or Right Shift | Right flipper (press and hold) |
| Space | Hold to charge plunger, release to launch |
| Left/Right/Up arrows | Nudge (limited, tilt penalty) |
| P | Pause |
| T | Toggle debug indicators |

## Scope and technical honesty
This is a first gameplay prototype, not a finished simulation of a mechanical machine. The playfield is procedural SpriteKit artwork; flippers use tuned collision responses, with more advanced angular impulse treatment planned. Tune the physics with Mac playtesting. The game is not signed or notarized, nor has a Mac build been verified by CI yet. Never claim release readiness until an Xcode build and manual playtest pass.

## Fun City integration
The game remains independent. To add it to Fun City's built-in cabinets, update `ArcadeGame.featured` with ID `pinball`, title `VECTOR PINBALL`, bundle ID `io.vectorpinball.game`, and the new cabinet art. Until that integration is merged, use Fun City's **ADD GAME** option to locate the built app.

All game graphics are original programmatic primitives. No third-party images, audio or game marks.
