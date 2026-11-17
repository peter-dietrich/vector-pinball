# Vector Pinball v0.5.1 — Gameplay Stability QA

This iteration addresses the Vector Siege playtest where the ball repeated a collision cycle and a flipper remained raised.

## Source-level changes
- Reset A/D and individual Shift-held flipper flags when the game window resigns key or first-responder focus.
- Reset held flippers on game restart, ball drain, and tilt.
- Only flipper-rebound an **incoming falling** ball; do not repeatedly rebound the same ball during upward separation.
- Cap the fixed-step simulation backlog after a frame hitch.
- Track ball movement across rendered frames and automatically attempt recovery if it travels less than 26 points for roughly 2 seconds.
- Manual recovery: press R to move an active, stuck ball to a safe central lane without restarting the score.
- After recurring automatic rescues, move the ball to the safe lane instead of repeating an impulse inside the trap.

## Mac acceptance
1. Build and launch; verify `GAMEPLAY STABILITY v0.5.1` appears.
2. Hold and release A and D separately, then together. Both bats must reliably lower.
3. Hold one flipper, switch to another application, then return. It must be lowered.
4. Run a long ball without touching controls. Repeated contact must not freeze its position.
5. Press R during an active ball; the ball should reenter play at center without changing ball count or score.
6. Repeat a stuck scenario; automatic recovery should break a loop rather than triggering infinitely.
7. Tilt with four nudges; both flippers should return to idle.
8. Drain all three balls and restart; flippers should be down before the next serve.
9. Confirm armored artwork and Git-bundled image are unchanged.

## Limits
This is a stabilization patch, not a fundamentally new rigid-body pinball simulator. Mac compilation and manual playtesting must still pass before calling this verified.
