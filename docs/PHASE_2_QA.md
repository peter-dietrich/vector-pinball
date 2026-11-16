# Classic '82 — Phase 2 acceptance tests

Run the application from Xcode, press Return, and check:

1. The shooter starts with one ball and three total balls.
2. Hold/release Space to launch. Ball must rise then fall under stronger simulated gravity.
3. Both flippers respond independently to A/D and left/right Shift. Check at the lower half of the table.
4. Each target scores 250 and adds 100 pending bonus. First hits illuminate target progress.
5. Complete all five targets to earn 2,000 and increase the end-of-ball bonus multiplier (max x5).
6. Each of four rollover circles scores 500 once per set and adds 250 bonus. Complete all four for 2,500 and reset the lamps.
7. Every bumper collision scores 100 and adds 25 bonus. Collision bursts fade out.
8. After each drain, apply accumulated end-of-ball bonus times multiplier unless tilted; carry multiplier across balls, but reset target/rollover progress.
9. Four nudges on a single ball cause TILT and disable manual flipper kicks and bonus scoring.
10. After ball 3, show game over and permit Return to restart.
11. Close and reopen: high score persists.
12. Toggle T to show physics telemetry; P pauses and resumes.

Important limitations:
- Not yet build-verified on macOS CI.
- Still using SpriteKit static-body rotations rather than a fully physical flipper hinge; playtest before adding advanced ramps/multiball.
- Original programmatic artwork, not a reproduction of a commercial pinball table.
