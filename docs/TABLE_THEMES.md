# Pinball Table Roadmap — shared engine

## Table 01: Vector Siege (v0.4.0 art preview)
Use the user-supplied neon-green vector tank battlefield artwork as the **static lower playfield art**, separate from dynamic rails, bumpers, target banks, flippers and pinball. No ball-physics modifications in this iteration.

### Art import
1. Save the supplied PNG on the Mac.
2. Run the game and press **B**.
3. Select the PNG in the native file picker.
4. The game copies it to `~/Library/Application Support/VectorPinball/vector_siege_playfield.png`, remembers it, and loads it on future launches.
5. Press **B** again to replace the art.

The overlay remains original mechanical SpriteKit geometry, and the game works without imported art. The background is aspect-filled and clipped to the playfield.

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
- Imported art survives app restarts.
- Background preserves aspect ratio and remains clipped within playfield.
- Ball has no collision interactions with the image itself.
- Gameplay without image remains functional.
- Flippers remain distinct with no overlap.
- No change to fixed-step ball engine in this graphics iteration.
- A local Xcode compilation and manual gameplay test is still required before this can be called validated.
