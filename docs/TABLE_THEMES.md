# Pinball Table Roadmap — shared engine

## Table 01: Vector Siege (v0.4.0 art preview)
Use the user-supplied neon-green vector tank battlefield artwork as the **static lower playfield art**, separate from dynamic rails, bumpers, target banks, flippers and pinball. No ball-physics modifications in this iteration.

### Artwork source of truth

The Vector Siege background is stored in `Resources/VectorSiege_Pinball_Background.png`, tracked directly by Git and embedded in the final .app by Xcode's Resources build phase. The initial binary artwork must be checked in once with `scripts/commit-vector-siege-art.sh`; thereafter, cloning and building retrieves identical artwork. Runtime artwork importing has been removed.

Only personal saved settings and scores live outside Git. Source assets, table definitions, effects, sounds, and project configuration must all be committed and shipped together.

### Next theme-specific gameplay
- Vector tank drop targets, orange enemy indicators and neon laser lanes
- Bumper hits as shield/energy events
- Multiball mission: enemy tank incursion
- Animated score and special effects
- Improved table art readability and calibration

## Table 02: Vector Barrage (planned)
Missile silos, city objectives, defensive interception scoring and bonus modes. Same ball engine, new collision geometry, theme art and mission rules.

## Table 03: Vector Drift (planned)
Asteroid target banks, hyperspace loops, satellite ramps, space-station bonus and multiball. Same core game engine.

## Non-negotiable separation
The background image must never contain dynamic ball interaction pieces. Every flipper, bumper, rail, target and interactive animation is created in the game, layered above static artwork. Each future table must have its own rules/configuration so that the engine is reused without copying one table's mechanics verbatim.

## QA
- Git-tracked PNG exists in repo and its SHA-256 matches the approved source.
- Bundled background preserves aspect ratio and remains clipped within playfield.
- Ball has no collision interactions with the image itself.
- CI rejects missing artwork so distribution never silently ships without it.
- Flippers remain distinct with no overlap.
- No change to fixed-step ball engine in this graphics iteration.
- A local Xcode compilation and manual gameplay test is still required before this can be called validated.
