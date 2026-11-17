# Vector Pinball — Classic '82

An original hybrid-physical pinball game for macOS and the Fun City arcade.

## v0.5.2 — Player control and drain fix

- Resting flipper tip gap: 18.69 table units, about **117% of the 16-unit ball diameter** (designer requested approximately 115%).
- Flipper skins and collision endpoints now share the corrected 70-unit length and widened pivot spacing.
- Removed all autonomous lower-playfield ball rescues and unpowered flipper launch impulses: the ball should drain if not played.
- Active left/right flippers remain powered only by the corresponding controls; `R` is a manual rescue, never automatic.
- Gameplay speed, scorekeeping and Git-tracked Vector Siege art are unchanged.
- [Mac test checklist](docs/V0_5_2_PLAYER_CONTROL_QA.md).

**Verification:** GitHub source reviewed, macOS Xcode build and manual playtest pending.

## v0.5.1 — Gameplay stability

- Release stuck A/D and Shift flipper states on window focus loss, ball drain, game restart, and tilt.
- Avoid repeated flipper collision reactions after a ball is already moving upward.
- Watch for stationary balls **and** balls stuck cycling within a small region; recover automatically.
- Press **R** to rescue an active ball into the playfield without restarting.
- Keep all code and image resources Git-tracked; no new external assets are required.
- See [stability acceptance tests](docs/V0_5_1_STABILITY_QA.md).

**Build status:** Source changes verified in GitHub; macOS compile and gameplay testing pending.

## v0.5.0 — Armored Vector Siege table

- Procedurally rendered, original high-detail mechanical components in `Sources/VectorSiegeMechanicalArt.swift`; all design data and rendering code live in Git.
- Sentry-style target banks, luminous reactor bumpers, armored shield slingshots, metal-and-neon tapered flippers, mechanical mounting posts, and indicator inserts.
- A stronger powered flipper rebound and controlled passive bounce, revised contact separation, low-speed pocket rescue, and active slingshot kicks.
- Existing table background `Resources/VectorSiege_Pinball_Background.png` remains bundled in Xcode.
- No changes to the user's installed per-player score/preferences.
- Test instructions: [v0.5.0 acceptance checklist](docs/V0_5_0_ACCEPTANCE.md).

**Verification:** GitHub source and Xcode project references checked. Build and gameplay are not yet verified on Mac.

## v0.4.1 — all source and assets in Git

**Git is the only source of truth for game code, table artwork, sound, rules and Xcode resources.** No user-local artwork importer or Application Support art dependency remains.

The first table artwork is `Resources/VectorSiege_Pinball_Background.png`. It is copied into the game executable bundle by `VectorPinball.xcodeproj` and loaded automatically.

**One-time binary asset check-in required:** The GitHub text-file connector cannot upload this PNG itself. Download the supplied PNG from the chat into `~/Downloads/VectorSiege_Pinball_Background.png`, then:

```zsh
cd ~/Documents/GitHub/vector-pinball
git pull --ff-only origin main
zsh scripts/commit-vector-siege-art.sh
open VectorPinball.xcodeproj
```

The script verifies the original image's SHA-256 before committing and pushing it to `main`. After that, every clone and Fun City release build carries identical bundled artwork. The build expects the PNG to exist in Git, and should be treated as incomplete until the asset is pushed.

Never introduce new runtime-specific game assets into Application Support. Local saved scores, settings, and preferences may remain user-specific; those are not source assets.

Vector Siege is table 01. Vector Barrage and Vector Drift will each have independent versioned resources and table definitions.

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
| B | Reload bundled Git-tracked artwork |
| R | Rescue stuck active ball |
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
