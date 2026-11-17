# v0.5.3 — Swept collision QA

Designer-reported regressions: falling ball passes through a raised flipper, repeatedly predictable ball travel, and left-side rebound cycles.

## Changes
- Swept ball trajectory intersects the true activated bat segment rather than testing only final-frame proximity.
- Launch enters the upper table with small randomized lateral velocity, while preserving the controlled shooter animation.
- Flipper shots vary slightly with hit position and small lateral variation. Ball trajectory remains physics-driven.
- Slingshot kick only triggers on an incoming collision; separation no longer awards a new kick.
- Target banks only rebound upon incoming contact, not on subsequent overlap while exiting.
- Lower left/right inlanes open into real outlanes and permit drains rather than treating the whole lower section as a closed wall.
- Existing 16-diameter ball and approximately 18.7-unit resting flipper gap remain unchanged.
- Vector Siege art and assets remain committed in Git; gameplay speed remains unchanged.

## Tests on macOS
1. Confirm top label **SWEPT COLLISIONS v0.5.3**.
2. Hold A: drop ball onto left flipper at the base, middle and tip; check visibly powered rebounds.
3. Hold D: repeat for right flipper. Test both flippers pressed simultaneously.
4. With neither flipper pressed, the ball must drain through center or an outlane; no self-play.
5. Play at least ten balls; verify launch paths are similar in overall speed but not identical.
6. Observe lower-left side for several balls; the ball should leave via the outlane or return normally, not bounce indefinitely.
7. Verify targets and slingshots score or kick once for a new hit, rather than repeatedly while overlapped.
8. Press R only if a true physical trap occurs, to rescue manually.
9. Make sure no table artwork goes missing; clean clone must continue to build with only Git-tracked assets.

GitHub source verified, Xcode macOS compile and manual gameplay verification remain pending.
