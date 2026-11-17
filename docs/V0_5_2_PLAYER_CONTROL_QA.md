# Vector Pinball v0.5.2 — Player control and drain geometry

## Design correction
The previous version was unintentionally self-playing: passive flipper collisions injected upward momentum, and repeated automatic recovery relaunched the ball in the lower playfield. Both behaviors have been removed.

- Ball diameter: 16 table units (radius 8).
- Resting pivots: x=122 and x=277, y=121.
- Resting bat length: 70, angle 0.23 rad downward toward the drain.
- Calculated resting tip-to-tip gap: approx. 18.69 units = **116.8% of ball diameter**, matching designer's ~115% request.
- Rendering sprites shortened to 70 units to align the artwork with the collider; no center sprite overlap.
- Only a held A/D or Shift flipper can generate a powered shot. Released flippers no longer manufacture a rebound.
- Automatic stationary/orbit and anti-stick launching removed. The ball may drain naturally.
- R remains a **manual** rescue only, should a genuine trap occur.
- Existing vector-siege image, renderers and gameplay speed preserved.

## Mac acceptance
1. Verify top tag `PLAYER CONTROL v0.5.2`.
2. Start a game, launch ball, and don't touch flippers. Ball should eventually drain.
3. Hold A and D while ball falls toward each bat; shots should occur only on held flippers.
4. Release both flippers. Verify they're visibly down, spaced to let the ball drain.
5. No autonomous `BALL FREED` or `AUTO BALL RESCUE` events.
6. Press R once during play and verify explicit manual rescue works.
7. Run three full balls to confirm game over and new-game replay.

GitHub source was checked; macOS Xcode build and playtest still required.
