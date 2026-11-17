# Vector Pinball — Fun City Arcade

## Clean-room restart

The previous SpriteKit prototype was retired on November 17, 2026.

This `main` branch has been cleared for a new high-fidelity macOS pinball game built around a tested, purpose-designed physics foundation and premium 3D graphics.

The previous implementation—including the Vector Siege table artwork, project files, and commit history—remains available in the archive branch:

`archive/pre-unity-restart-2026-11-17`

## New development rules

- The new pinball project starts from scratch. Do not carry over the previous SpriteKit physics, collision patches, or rendering architecture.
- Keep all source code, artwork, 3D models, audio, shaders, resources, build scripts, and tests in Git, using Git LFS for large binary assets when appropriate.
- First verify the macOS engine and build tooling; then build and test the ball/flipper physics laboratory before table art.
- The first game table will be Vector Siege, followed by Vector Barrage and Vector Drift.
- The game should remain independently buildable before integration into Fun City Arcade.
- Every version needs a visible identifier and documented build/test status.

## Status

Repository reset complete. No new Unity application or physics engine is implemented yet.
