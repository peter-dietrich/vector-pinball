# Vector Pinball 2.0 — Fun City Arcade

**Status:** New Unity physics laboratory source committed. **Not yet build-verified or gameplay-accepted.**

## Foundation

- Unity 6.3 LTS **6000.3.28f1**, pinned in `ProjectSettings/ProjectVersion.txt`.
- macOS standalone application target.
- A real Rigidbody steel ball, motor-driven HingeJoint flippers, distinct collision materials, and a 120 Hz physics timestep.
- Reproducible lab-scene generator in `Assets/Editor/PhysicsLabSceneBuilder.cs`.
- EditMode unit tests for fundamental dimensions and gap geometry.
- All authored code and configuration tracked in Git. No SpriteKit physics reused.

## Mac setup

Install Unity Hub and Unity Editor **6000.3.28f1**. Open the existing repository using Unity Hub's **Add project from disk** option.

```bash
cd ~/Documents/GitHub/vector-pinball
git switch main
git pull --ff-only origin main
```

In Unity, choose **Fun City → Pinball → Build Physics Lab Scene**. Then press **Play**.

Controls: **Return** reset; **Space** launch; **A / Left Shift** left flipper; **D / Right Shift** right flipper.

For a native Mac test application choose **Fun City → Pinball → Build macOS Physics Lab**.

Run geometry tests using **Window → General → Test Runner → EditMode → Run All**.

## Important Git workflow

The scene generator creates `Assets/Scenes/PhysicsLab.unity` and `Assets/PhysicsMaterials/` in the Unity Editor. These generated files and their Unity `.meta` files **must be checked into Git** after the first successful generation. Until that happens, the repository contains the canonical generator source, but not a pre-generated runnable scene.

After the first successful scene generation, run `zsh scripts/sync-generated-lab.sh` from the repository root. This commits the new scene, material assets and Unity metadata directly to `main`, ensuring Git remains the source of truth.\n\nUnity-generated `Library/`, `Temp/`, and `Builds/` remain excluded from Git.

## Physics acceptance gate

Before themed table art:
- Confirm motorized flippers rotate and reliably return when released.
- Confirm steel ball rolling, collisions, spin, and material restitution.
- Confirm ball cannot tunnel through raised flipper at tested gameplay velocities.
- Confirm an unattended ball can drain naturally through the measured resting gap, approximately 1.15 times the ball diameter.
- Verify ball, rubber, rails, and bumpers through repeatable tests and diagnostics.
- Run 100 unattended gameplay trials with no persistent contact loops.

**These tests have not yet been executed.** The initial Unity scripts still require a macOS compilation and manual playtesting.

## Roadmap

1. Physics laboratory verification and collision tests.
2. Complete playable mechanical table.
3. Premium 3D Vector Siege table.
4. Vector Barrage and Vector Drift themed tables.
5. Fun City Arcade installation and update integration.

## Archived prototype

Old SpriteKit code and images remain on `archive/pre-unity-restart-2026-11-17`.
