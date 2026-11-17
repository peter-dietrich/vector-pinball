# v0.5.0 Vector Siege — Mac acceptance checklist

## Reproducibility
- Pull main and build with Xcode, with no manually imported artwork.
- Verify green playfield version label reads `ARMORED TABLE v0.5.0`.
- Verify `Sources/VectorSiegeMechanicalArt.swift` is compiled into the application.
- Verify `Resources/VectorSiege_Pinball_Background.png` is committed; CI checksum check must pass.

## Mechanical visuals
- Reactor bumpers are luminous green armored circular mechanisms, not orange placeholder circles.
- Five upper targets are enemy sentry graphics, not rectangles.
- Slingshots are metallic defensive shields rather than solid pink triangles.
- Both flippers have dark metallic tapered skins with green/orange accents and separated center gap.
- Green crosshair lane inserts and detailed metal mounting posts overlay the existing art.
- Playfield background is not stretched and mechanical graphics stay on top of it.

## Playability
1. Press Return, launch Space; ball enters the table.
2. Hold the left flipper, the right flipper, and both together. The bats must not cross.
3. Drop ball onto powered flipper from above: it separates and rebounds strongly.
4. Drop onto released flipper: passive rubber bounce, not a dead contact.
5. Hold a bat and keep ball near its edge: it must not remain embedded in the bat.
6. If ball settles in lower flipper/post pocket for roughly a third of a second, it gets a limited rescue impulse.
7. Pop bumpers kick the ball outward, slingshots actively fire it into the table.
8. Three balls, target bank, bonuses, scores and replay still work.

This is a developer source change verified in GitHub, **not** a confirmed Xcode compile or completed manual gameplay test. Capture any build errors or screenshot differences before future styling work.
