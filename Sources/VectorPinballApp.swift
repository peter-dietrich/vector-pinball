import AppKit
import SpriteKit
import SwiftUI

@main
struct VectorPinballApp: App {
    var body: some Scene {
        WindowGroup("Vector Pinball — Classic '82") {
            PinballView()
                .frame(minWidth: 600, minHeight: 820)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 690, height: 910)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}

struct PinballView: NSViewRepresentable {
    func makeNSView(context: Context) -> PinballSKView {
        let view = PinballSKView()
        view.ignoresSiblingOrder = true
        let scene = Classic82Scene(size: CGSize(width: 420, height: 720))
        scene.scaleMode = .aspectFit
        view.presentScene(scene)
        DispatchQueue.main.async { view.window?.makeFirstResponder(view) }
        return view
    }
    func updateNSView(_ view: PinballSKView, context: Context) {}
}

final class PinballSKView: SKView {
    override var acceptsFirstResponder: Bool { true }
    override func keyDown(with event: NSEvent) {
        guard let scene = scene as? Classic82Scene else { return }
        if !event.isARepeat { scene.handleKey(event.keyCode, pressed: true) }
    }
    override func keyUp(with event: NSEvent) {
        (scene as? Classic82Scene)?.handleKey(event.keyCode, pressed: false)
    }
    override func flagsChanged(with event: NSEvent) {
        let left = event.modifierFlags.contains(.shift) && event.keyCode == 56
        if event.keyCode == 56 { (scene as? Classic82Scene)?.setFlipper(left: true, active: left) }
        let right = event.modifierFlags.contains(.shift) && event.keyCode == 60
        if event.keyCode == 60 { (scene as? Classic82Scene)?.setFlipper(left: false, active: right) }
    }
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }
}

private enum Collision {
    static let ball: UInt32 = 1 << 0
    static let bumper: UInt32 = 1 << 1
    static let target: UInt32 = 1 << 2
    static let flipper: UInt32 = 1 << 3
    static let lane: UInt32 = 1 << 4
}

final class Classic82Scene: SKScene, SKPhysicsContactDelegate {
    private let playfield = SKNode()
    private var ball: SKShapeNode?
    private var leftFlipper: SKShapeNode!
    private var rightFlipper: SKShapeNode!
    private var scoreLabel: SKLabelNode!
    private var statusLabel: SKLabelNode!
    private var subtitleLabel: SKLabelNode!
    private var debugLabel: SKLabelNode!
    private var score = 0
    private var highScore = UserDefaults.standard.integer(forKey: "VectorPinball.Classic82.HighScore")
    private var ballNumber = 1
    private var running = false
    private var awaitingServe = false
    private var leftActive = false
    private var rightActive = false
    private var plungerCharging = false
    private var plungerCharge = 0.0
    private var travelingShooterLane = false
    private var shooterElapsed: TimeInterval = 0
    private var shooterDuration: TimeInterval = 0.8
    private let buildTag = "REBOUND ENGINE v0.4.2"
    private var ballVelocity = CGVector.zero
    private var simulationRemainder = 0.0
    private var ballInShooter = true
    private var bumperNodes = [SKShapeNode]()
    private var backgroundArt: SKNode?
    private let artResourceName = "VectorSiege_Pinball_Background"
    private var previousFlipperL = false
    private var previousFlipperR = false
    private var trappedSeconds: TimeInterval = 0
    private var trailTick: TimeInterval = 0
    private var lastBallPoint = CGPoint.zero
    private var lastTime: TimeInterval = 0
    private var nudges = 0
    private var showDebug = false
    private var lastFlipperKick: TimeInterval = 0
    private var lastLeftKick: TimeInterval = -10
    private var lastRightKick: TimeInterval = -10
    private var simTime: TimeInterval = 0
    private var bankHits = Set<Int>()
    private var laneHits = Set<Int>()
    private var bonus = 0
    private var multiplier = 1
    private var tilted = false
    private var lastContactTime = [String: TimeInterval]()
    private var targetNodes = [SKShapeNode]()
    private var laneNodes = [SKShapeNode]()
    private var bonusLabel: SKLabelNode!
    private var tiltLabel: SKLabelNode!


    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.025, green: 0.035, blue: 0.075, alpha: 1)
        physicsWorld.gravity = CGVector(dx: 0, dy: -180)
        physicsWorld.contactDelegate = self
        addChild(playfield)
        buildTable()
        loadTableArt()
        buildHUD()
        showAttract()
    }

    private func wall(_ points: [CGPoint], color: SKColor = .init(red: 0.75, green: 0.62, blue: 0.36, alpha: 1), thickness: CGFloat = 4) {
        guard let first = points.first else { return }
        let path = CGMutablePath()
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        let shape = SKShapeNode(path: path)
        shape.strokeColor = color
        shape.lineWidth = thickness
        shape.glowWidth = 1.5
        shape.physicsBody = SKPhysicsBody(edgeChainFrom: path)
        shape.physicsBody?.isDynamic = false
        shape.physicsBody?.restitution = 0.58
        shape.physicsBody?.friction = 0.1
        playfield.addChild(shape)
    }

    private func label(_ text: String, at p: CGPoint, size: CGFloat, color: SKColor = .white, font: String = "Menlo-Bold") -> SKLabelNode {
        let node = SKLabelNode(fontNamed: font)
        node.text = text
        node.fontSize = size
        node.fontColor = color
        node.position = p
        node.verticalAlignmentMode = .center
        playfield.addChild(node)
        return node
    }

    private func buildTable() {
        let frame = SKShapeNode(rectOf: CGSize(width: 366, height: 670), cornerRadius: 27)
        frame.position = CGPoint(x: 210, y: 355)
        frame.fillColor = SKColor(red: 0.09, green: 0.13, blue: 0.23, alpha: 1)
        frame.strokeColor = SKColor(red: 0.70, green: 0.53, blue: 0.30, alpha: 1)
        frame.lineWidth = 6
        frame.zPosition = -3
        playfield.addChild(frame)
        // Printed starburst rings evoke silkscreened early-eighties playfields.
        let artwork = SKShapeNode(ellipseOf: CGSize(width: 290, height: 330))
        artwork.position = CGPoint(x: 197, y: 421)
        artwork.strokeColor = SKColor(red: 0.95, green: 0.46, blue: 0.28, alpha: 0.36)
        artwork.lineWidth = 2
        artwork.fillColor = .clear
        playfield.addChild(artwork)

        wall([CGPoint(x: 45, y: 115), CGPoint(x: 45, y: 605), CGPoint(x: 70, y: 663), CGPoint(x: 210, y: 682),
              CGPoint(x: 345, y: 663), CGPoint(x: 373, y: 605), CGPoint(x: 373, y: 72)])
        wall([CGPoint(x: 350, y: 70), CGPoint(x: 350, y: 600), CGPoint(x: 340, y: 630)],
             color: .init(red: 0.38, green: 0.78, blue: 0.92, alpha: 1), thickness: 3)
        wall([CGPoint(x: 46, y: 220), CGPoint(x: 75, y: 171), CGPoint(x: 105, y: 129)])
        wall([CGPoint(x: 346, y: 237), CGPoint(x: 329, y: 203), CGPoint(x: 314, y: 168), CGPoint(x: 282, y: 131)])
        wall([CGPoint(x: 68, y: 255), CGPoint(x: 103, y: 290), CGPoint(x: 113, y: 360)],
             color: .cyan, thickness: 3)
        wall([CGPoint(x: 322, y: 255), CGPoint(x: 290, y: 290), CGPoint(x: 282, y: 360)],
             color: .cyan, thickness: 3)
        wall([CGPoint(x: 83, y: 120), CGPoint(x: 106, y: 105)])
        wall([CGPoint(x: 311, y: 120), CGPoint(x: 291, y: 105)])

        label("VECTOR SIEGE", at: CGPoint(x: 197, y: 635), size: 18, color: .init(red: 0.61, green: 1, blue: 0.35, alpha: 1))
        label("FUN CITY PINBALL • TABLE 01", at: CGPoint(x: 197, y: 614), size: 8, color: .init(red: 0.63, green: 1, blue: 0.82, alpha: 1))
        for i in 0..<5 {
            let target = SKShapeNode(rectOf: CGSize(width: 22, height: 31), cornerRadius: 3)
            target.position = CGPoint(x: 105 + 46*i, y: 569 - ((i % 2) * 13))
            target.name = "target_\(i)"
            target.fillColor = i % 2 == 0 ? .systemOrange : .systemTeal
            target.strokeColor = .white
            target.lineWidth = 1.7
            target.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 22, height: 31))
            target.physicsBody?.isDynamic = false
            target.physicsBody?.categoryBitMask = Collision.target
            target.physicsBody?.contactTestBitMask = Collision.ball
            target.physicsBody?.restitution = 0.65
            playfield.addChild(target)
            targetNodes.append(target)
        }

        for p in [CGPoint(x: 146, y: 464), CGPoint(x: 248, y: 464), CGPoint(x: 197, y: 395)] {
            let bumper = SKShapeNode(circleOfRadius: 25)
            bumper.position = p
            bumper.fillColor = SKColor(red: 0.71, green: 0.27, blue: 0.32, alpha: 1)
            bumper.strokeColor = .init(red: 1, green: 0.87, blue: 0.47, alpha: 1)
            bumper.lineWidth = 5
            bumper.glowWidth = 6
            bumper.physicsBody = SKPhysicsBody(circleOfRadius: 25)
            bumper.physicsBody?.isDynamic = false
            bumper.physicsBody?.categoryBitMask = Collision.bumper
            bumper.physicsBody?.contactTestBitMask = Collision.ball
            bumper.physicsBody?.restitution = 0.82
            playfield.addChild(bumper)
            bumperNodes.append(bumper)
            let inset = SKShapeNode(circleOfRadius: 13)
            inset.fillColor = .init(red: 0.99, green: 0.71, blue: 0.29, alpha: 1)
            inset.strokeColor = .white
            inset.lineWidth = 2
            bumper.addChild(inset)
            let highlight = SKShapeNode(circleOfRadius: 5)
            highlight.position = CGPoint(x: -5, y: 5)
            highlight.fillColor = .white.withAlphaComponent(0.6)
            highlight.strokeColor = .clear
            bumper.addChild(highlight)
        }
        for x in [105.0, 164.0, 223.0, 282.0] {
            let light = SKShapeNode(circleOfRadius: 10)
            light.position = CGPoint(x: x, y: 330)
            light.fillColor = .init(red: 0.24, green: 0.70, blue: 0.77, alpha: 1)
            light.strokeColor = .white
            light.name = "lane_\(laneNodes.count)"
            let sensor = SKPhysicsBody(circleOfRadius: 11)
            sensor.isDynamic = false
            sensor.categoryBitMask = Collision.lane
            sensor.contactTestBitMask = Collision.ball
            sensor.collisionBitMask = 0
            light.physicsBody = sensor
            playfield.addChild(light)
            laneNodes.append(light)
        }
        label("BONUS LANES", at: CGPoint(x: 197, y: 306), size: 12, color: .init(red: 0.96, green: 0.72, blue: 0.41, alpha: 1))
        label("COMPLETE TARGET BANK FOR X2", at: CGPoint(x: 197, y: 514), size: 9, color: .systemYellow)
        for (x, mirror) in [(105.0, false), (268.0, true)] {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x - 23, y: 239))
            path.addLine(to: CGPoint(x: x + 23, y: 239))
            path.addLine(to: CGPoint(x: mirror ? x + 16 : x - 16, y: 190))
            path.closeSubpath()
            let slingshot = SKShapeNode(path: path)
            slingshot.fillColor = .init(red: 0.62, green: 0.23, blue: 0.36, alpha: 1)
            slingshot.strokeColor = .init(red: 1, green: 0.71, blue: 0.45, alpha: 1)
            slingshot.lineWidth = 3
            slingshot.physicsBody = SKPhysicsBody(polygonFrom: path)
            slingshot.physicsBody?.isDynamic = false
            slingshot.physicsBody?.restitution = 0.8
            playfield.addChild(slingshot)
        }
        leftFlipper = makeFlipper(at: CGPoint(x: 125, y: 121), left: true)
        rightFlipper = makeFlipper(at: CGPoint(x: 274, y: 121), left: false)
        label("LAUNCH", at: CGPoint(x: 362, y: 48), size: 8, color: .systemOrange)
        label(buildTag, at: CGPoint(x: 210, y: 657), size: 9, color: .systemGreen)
        buildMechanicalArt()
    }

    private func makeFlipper(at position: CGPoint, left: Bool) -> SKShapeNode {
        // Pivot-local, tapered original pinball bat: broad at the hinge,
        // narrower and rounded at the inward-facing tip.
        let sign: CGFloat = left ? 1 : -1
        let length: CGFloat = 70 // pivot-to-tip, not the old centered bat width
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: -11))
        path.addLine(to: CGPoint(x: sign * (length - 8), y: -6.5))
        path.addQuadCurve(to: CGPoint(x: sign * (length - 8), y: 6.5),
                          control: CGPoint(x: sign * (length + 4), y: 0))
        path.addLine(to: CGPoint(x: 0, y: 11))
        path.closeSubpath()
        let shape = SKShapeNode(path: path)
        shape.position = position
        shape.zRotation = left ? -0.23 : 0.23
        shape.fillColor = SKColor(red: 0.79, green: 0.16, blue: 0.13, alpha: 1)
        shape.strokeColor = SKColor(red: 1, green: 0.78, blue: 0.42, alpha: 1)
        shape.lineWidth = 2.5
        // No physics body: the manual flipper solver uses the same endpoints.
        playfield.addChild(shape)

        let rubberPath = CGMutablePath()
        rubberPath.move(to: CGPoint(x: sign * 8, y: 5))
        rubberPath.addLine(to: CGPoint(x: sign * (length - 12), y: 3))
        let rubber = SKShapeNode(path: rubberPath)
        rubber.strokeColor = SKColor(red: 1, green: 0.76, blue: 0.48, alpha: 1)
        rubber.lineWidth = 4
        shape.addChild(rubber)

        let pivot = SKShapeNode(circleOfRadius: 6)
        pivot.fillColor = .darkGray
        pivot.strokeColor = .white
        pivot.lineWidth = 1.3
        shape.addChild(pivot)
        return shape
    }

    private func buildMechanicalArt() {
        let gold = SKColor(red: 1, green: 0.77, blue: 0.43, alpha: 1)
        let blue = SKColor(red: 0.22, green: 0.78, blue: 0.84, alpha: 1)
        for (index, p) in [
            CGPoint(x: 86, y: 492), CGPoint(x: 307, y: 492),
            CGPoint(x: 86, y: 388), CGPoint(x: 305, y: 388),
            CGPoint(x: 115, y: 282), CGPoint(x: 276, y: 282),
            CGPoint(x: 147, y: 362), CGPoint(x: 246, y: 362)
        ].enumerated() {
            let lamp = SKShapeNode(circleOfRadius: 9)
            lamp.position = p
            lamp.fillColor = (index % 2 == 0 ? gold : blue).withAlphaComponent(0.48)
            lamp.strokeColor = gold.withAlphaComponent(0.8)
            lamp.lineWidth = 2
            lamp.glowWidth = 2
            playfield.addChild(lamp)
        }
        for p in [
            CGPoint(x: 77, y: 550), CGPoint(x: 316, y: 550),
            CGPoint(x: 82, y: 307), CGPoint(x: 309, y: 307),
            CGPoint(x: 90, y: 168), CGPoint(x: 306, y: 168),
            CGPoint(x: 95, y: 248), CGPoint(x: 290, y: 248)
        ] {
            let post = SKShapeNode(circleOfRadius: 5)
            post.position = p
            post.fillColor = .darkGray
            post.strokeColor = .white
            post.lineWidth = 1.5
            playfield.addChild(post)
            let screw = SKShapeNode(circleOfRadius: 1.8)
            screw.fillColor = .black
            screw.strokeColor = .clear
            post.addChild(screw)
        }
        for (x,y) in [(94.0, 248.0), (289, 248)] {
            let plastic = SKShapeNode(rectOf: CGSize(width: 42, height: 9), cornerRadius: 4)
            plastic.position = CGPoint(x: x, y: y)
            plastic.fillColor = SKColor(red: 0.9, green: 0.29, blue: 0.25, alpha: 0.6)
            plastic.strokeColor = gold
            plastic.lineWidth = 1
            playfield.addChild(plastic)
        }
        label("VECTOR SIEGE", at: CGPoint(x: 197, y: 365), size: 12, color: .systemGreen)
        label("SPECIAL WHEN LIT", at: CGPoint(x: 197, y: 352), size: 7, color: blue)
        label("DEFEND THE GRID", at: CGPoint(x: 197, y: 184), size: 10, color: .systemGreen)
    }

    private func loadTableArt() {
        backgroundArt?.removeFromParent()
        backgroundArt = nil
        guard let url = Bundle.main.url(forResource: artResourceName, withExtension: "png"),
              let image = NSImage(contentsOf: url) else {
            // Missing checked-in resource should be visible, not silently ignored.
            statusLabel?.text = "MISSING BUNDLED TABLE ART"
            return
        }
        let art = SKSpriteNode(texture: SKTexture(image: image))
        // This is a portrait 2:3 image; the visible playfield is ~350 x 620.
        // Scale the artwork within the machine without warping its proportions.
        let imageSize = image.size
        let width: CGFloat = 346
        let height: CGFloat = 630
        let aspect = imageSize.width / max(imageSize.height, 1)
        // Aspect-fill: the supplied portrait art covers the table, no black bars.
        let filledHeight = max(height, width / max(aspect, 0.01))
        art.size = CGSize(width: filledHeight * aspect, height: filledHeight)
        art.position = .zero
        art.alpha = 0.92
        let mask = SKShapeNode(rectOf: CGSize(width: 346, height: 626), cornerRadius: 15)
        mask.fillColor = .white
        mask.strokeColor = .clear
        let crop = SKCropNode()
        crop.position = CGPoint(x: 210, y: 355)
        crop.zPosition = -2
        crop.maskNode = mask
        crop.addChild(art)
        playfield.addChild(crop)
        backgroundArt = crop
    }

    private func buildHUD() {
        scoreLabel = label("", at: CGPoint(x: 210, y: 702), size: 12, color: .white)
        statusLabel = label("", at: CGPoint(x: 210, y: 28), size: 14, color: .systemYellow)
        subtitleLabel = label("", at: CGPoint(x: 210, y: 13), size: 9, color: .init(red: 0.62, green: 0.82, blue: 0.93, alpha: 1))
        debugLabel = label("", at: CGPoint(x: 208, y: 268), size: 10, color: .systemGreen)
        debugLabel.isHidden = true
        bonusLabel = label("", at: CGPoint(x: 210, y: 686), size: 10, color: .systemOrange)
        tiltLabel = label("", at: CGPoint(x: 210, y: 54), size: 11, color: .systemRed)
        refreshHUD()
    }

    private func showAttract() {
        statusLabel.text = "PRESS RETURN TO START"
        subtitleLabel.text = "A/D FLIPPERS • SPACE LAUNCH • B RELOAD ART"
    }

    private func refreshHUD() {
        scoreLabel.text = "SCORE \(score)      BEST \(highScore)      BALL \(ballNumber)/3"
        bonusLabel.text = "BONUS \(bonus) X\(multiplier)    TARGETS \(bankHits.count)/5    LANES \(laneHits.count)/4"
        tiltLabel.text = tilted ? "TILT — BONUS FORFEITED" : ""
        if running && !awaitingServe {
            statusLabel.text = plungerCharging ? "PLUNGER \(Int(plungerCharge*100))%" : "PLAY BALL"
            subtitleLabel.text = "HOLD SPACE TO CHARGE • RELEASE TO LAUNCH"
        }
    }

    private func beginGame() {
        isPaused = false
        ball?.removeFromParent()
        ball = nil
        score = 0
        ballNumber = 1
        nudges = 0
        running = true
        awaitingServe = false
        plungerCharging = false
        plungerCharge = 0
        travelingShooterLane = false
        shooterElapsed = 0
        trappedSeconds = 0
        bonus = 0
        multiplier = 1
        lastLeftKick = -10
        lastRightKick = -10
        bankHits.removeAll()
        laneHits.removeAll()
        targetNodes.forEach { $0.alpha = 1 }
        laneNodes.forEach { $0.alpha = 1 }
        lastContactTime.removeAll()
        serveBall()
    }

    private func serveBall() {
        guard running else { return }
        let node = SKShapeNode(circleOfRadius: 8)
        node.name = "pinball"
        node.fillColor = .init(red: 0.90, green: 0.94, blue: 0.99, alpha: 1)
        node.strokeColor = .white
        node.lineWidth = 2
        node.glowWidth = 1
        let glint = SKShapeNode(circleOfRadius: 3)
        glint.fillColor = .white
        glint.strokeColor = .clear
        glint.position = CGPoint(x: -2, y: 3)
        node.addChild(glint)
        node.position = CGPoint(x: 362, y: 105)
        // The ball intentionally has no SpriteKit physics body.
        // Its movement and collisions are entirely owned by stepBall(_:).
        ballVelocity = .zero
        ballInShooter = true
        simulationRemainder = 0
        node.zPosition = 10
        playfield.addChild(node)
        ball = node
        awaitingServe = false
        travelingShooterLane = false
        shooterElapsed = 0
        trappedSeconds = 0
        lastBallPoint = node.position
        tilted = false
        refreshHUD()
    }

    private func launchBall() {
        guard running, !travelingShooterLane, let ball,
              ball.position.x > 345, ball.position.y < 180 else { return }
        travelingShooterLane = true
        shooterElapsed = 0
        // The shooter is a deterministic animation. SpriteKit's side-wall
        // collision at launch was producing inconsistent ball trajectories.
        shooterDuration = 1.05 - plungerCharge * 0.30
        ballVelocity = .zero
        plungerCharging = false
        plungerCharge = 0
        statusLabel.text = "SHOOTER LANE"
        subtitleLabel.text = "CONTROLLED LAUNCH • PHYSICS RESET"
    }

    func handleKey(_ key: UInt16, pressed: Bool) {
        switch key {
        case 36: if pressed { beginGame() }
        case 0: setFlipper(left: true, active: pressed)
        case 2: setFlipper(left: false, active: pressed)
        case 49:
            if pressed, running, (ball?.position.x ?? 0) > 345 { plungerCharging = true }
            else if plungerCharging { plungerCharging = false; launchBall() }
        case 123, 124, 126:
            if pressed { nudge(direction: key) }
        case 35:
            if pressed, running { isPaused.toggle(); statusLabel.text = isPaused ? "PAUSED" : "PLAY BALL" }
        case 17:
            if pressed { showDebug.toggle(); debugLabel.isHidden = !showDebug }
        case 11: // B reloads the Git-tracked bundled background.
            if pressed { loadTableArt() }
        default: break
        }
    }

    func setFlipper(left: Bool, active: Bool) {
        if left { leftActive = active } else { rightActive = active }
        let node = left ? leftFlipper : rightFlipper
        let angle: CGFloat = left ? (active ? 0.40 : -0.23) : (active ? -0.40 : 0.23)
        node?.removeAction(forKey: "flip")
        node?.run(SKAction.rotate(toAngle: angle,
                                   duration: active ? 0.045 : 0.085,
                                   shortestUnitArc: true), withKey: "flip")
        // The manual fixed-step solver handles flipper contact. Do not add
        // a separate key-down impulse; that was causing exaggerated shots.
    }

    private func nudge(direction: UInt16) {
        guard running, ball != nil, nudges < 4 else { return }
        nudges += 1
        let impulse: CGVector
        switch direction {
        case 123: impulse = CGVector(dx: -1.8, dy: 1.2)
        case 124: impulse = CGVector(dx: 1.8, dy: 1.2)
        default: impulse = CGVector(dx: 0, dy: 3.2)
        }
        ballVelocity.dx += impulse.dx * 7
        ballVelocity.dy += impulse.dy * 7
        if nudges == 4 {
            tilted = true
            statusLabel.text = "TILT — NUDGE DISABLED"
            subtitleLabel.text = "NUDGE LIMIT RESETS NEXT BALL"
        }
    }

    private func addScore(_ points: Int) {
        guard running, !tilted else { return }
        score += points
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "VectorPinball.Classic82.HighScore")
        }
        refreshHUD()
    }

    func didBegin(_ contact: SKPhysicsContact) {
        guard running, !tilted else { return }
        let bits = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        guard bits & Collision.ball != 0 else { return }
        let other = contact.bodyA.categoryBitMask == Collision.ball ? contact.bodyB : contact.bodyA
        let key = other.node?.name ?? "bumper_\(Int(contact.contactPoint.x))_\(Int(contact.contactPoint.y))"
        guard simTime - (lastContactTime[key] ?? -100) > 0.18 else { return }
        lastContactTime[key] = simTime
        if bits & Collision.bumper != 0 {
            addScore(100)
            bonus += 25
            let pulse = SKShapeNode(circleOfRadius: 20)
            pulse.position = contact.contactPoint
            pulse.strokeColor = .yellow
            pulse.lineWidth = 4
            pulse.zPosition = 9
            playfield.addChild(pulse)
            pulse.run(.sequence([.group([.scale(to: 2.5, duration: 0.18), .fadeOut(withDuration: 0.18)]), .removeFromParent()]))
            if let bumper = other.node {
                bumper.run(.sequence([.scale(to: 1.13, duration: 0.05), .scale(to: 1, duration: 0.14)]))
            }
            impactFlash(at: contact.contactPoint, points: 100)
            if let ball {
                let dx = ball.position.x - contact.contactPoint.x
                ballVelocity.dx += max(-16, min(16, dx * 0.12))
                ballVelocity.dy += 45
            }
        } else if bits & Collision.target != 0 {
            addScore(250)
            impactFlash(at: contact.contactPoint, points: 250)
            bonus += 100
            if let name = other.node?.name, let index = Int(name.replacingOccurrences(of: "target_", with: "")), !bankHits.contains(index) {
                bankHits.insert(index)
                targetNodes[index].alpha = 0.35
                targetNodes[index].run(.sequence([.scale(to: 1.18, duration: 0.06), .scale(to: 1, duration: 0.15)]))
                if bankHits.count == targetNodes.count {
                    multiplier = min(5, multiplier + 1)
                    addScore(2000)
                    bankHits.removeAll()
                    targetNodes.forEach { $0.alpha = 1 }
                    statusLabel.text = "TARGET BANK COMPLETE! X\(multiplier)"
                }
            }
        } else if bits & Collision.lane != 0 {
            if let name = other.node?.name, let index = Int(name.replacingOccurrences(of: "lane_", with: "")), !laneHits.contains(index) {
                laneHits.insert(index)
                addScore(500)
                impactFlash(at: contact.contactPoint, points: 500)
                bonus += 250
                laneNodes[index].alpha = 0.35
                if laneHits.count == laneNodes.count {
                    addScore(2500)
                    laneHits.removeAll()
                    laneNodes.forEach { $0.alpha = 1 }
                    statusLabel.text = "ALL LANES! +2,500"
                }
            }
        }
        bonusLabel.text = "BONUS \(bonus) X\(multiplier)    TARGETS \(bankHits.count)/5    LANES \(laneHits.count)/4"
    }

    private func impactFlash(at point: CGPoint, points: Int) {
        let feedback = SKLabelNode(fontNamed: "Menlo-Bold")
        feedback.text = "+\(points)"
        feedback.fontSize = 13
        feedback.fontColor = .systemYellow
        feedback.position = point
        feedback.zPosition = 40
        playfield.addChild(feedback)
        feedback.run(.sequence([.group([.moveBy(x: 0, y: 28, duration: 0.45), .fadeOut(withDuration: 0.45)]), .removeFromParent()]))
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 0 : max(0, min(currentTime - lastTime, 0.045))
        lastTime = currentTime
        simTime += dt
        guard !isPaused else { return }
        if plungerCharging && running {
            plungerCharge = min(1, plungerCharge + dt / 1.2)
            if plungerCharge >= 1 { launchBall() }
            else { refreshHUD() }
        }
        guard running, let ball, !awaitingServe else { return }
        if travelingShooterLane {
            shooterElapsed += dt
            let t = min(1, shooterElapsed / shooterDuration)
            if t < 0.72 {
                ball.position = CGPoint(x: 362, y: 105 + 510 * (t / 0.72))
            } else {
                let curve = (t - 0.72) / 0.28
                ball.position = CGPoint(x: 362 - 46 * curve, y: 615 - 12 * curve)
            }
            if t >= 1 {
                travelingShooterLane = false
                ballInShooter = false
                ball.position = CGPoint(x: 316, y: 603)
                ballVelocity = CGVector(dx: -48, dy: -50)
                statusLabel.text = "PLAY BALL"
            }
            return
        }
        if ballInShooter { return }
        simulationRemainder += dt * 1.50 // Another 20% over v0.3.1 (1.25 × 1.20); fixed 120 Hz step
        let fixed = 1.0 / 120.0
        var loops = 0
        while simulationRemainder >= fixed && loops < 8 {
            stepBall(fixed)
            simulationRemainder -= fixed
            loops += 1
        }
        if ball.position.y < 60 {
            drainBall()
            return
        }
        let p = ball.position
        let speed = hypot(ballVelocity.dx, ballVelocity.dy)
        trailTick += dt
        if speed > 180 && trailTick > 0.08 {
            trailTick = 0
            let dot = SKShapeNode(circleOfRadius: 2.5)
            dot.position = p
            dot.fillColor = .white.withAlphaComponent(0.25)
            dot.strokeColor = .clear
            dot.zPosition = 3
            playfield.addChild(dot)
            dot.run(.sequence([.fadeOut(withDuration: 0.16), .removeFromParent()]))
        }
        if showDebug {
            debugLabel.text = String(format: "X %.0f  Y %.0f  V %.0f  120Hz", p.x, p.y, speed)
        }
    }

    // Own the ball simulation: no SpriteKit wall/ball solver, no invisible
    // contact impulses, and no teleportation after the shooter has finished.
    private func stepBall(_ dt: Double) {
        guard let ball else { return }
        ballVelocity.dy -= 235 * dt
        let friction = pow(0.997, dt * 120)
        ballVelocity.dx *= friction
        ballVelocity.dy *= friction
        let maxSpeed = 470.0
        let speed = hypot(ballVelocity.dx, ballVelocity.dy)
        if speed > maxSpeed {
            ballVelocity.dx *= maxSpeed / speed
            ballVelocity.dy *= maxSpeed / speed
        }
        let previous = ball.position
        var p = ball.position
        p.x += ballVelocity.dx * dt
        p.y += ballVelocity.dy * dt

        // Outside rails (with ball radius). Bottom stays open for real drains.
        if p.x < 55 && p.y > 110 {
            p.x = 55
            ballVelocity.dx = abs(ballVelocity.dx) * 0.72
        } else if p.x > 334 && p.y > 110 {
            p.x = 334
            ballVelocity.dx = -abs(ballVelocity.dx) * 0.72
        }
        if p.y > 658 {
            p.y = 658
            ballVelocity.dy = -abs(ballVelocity.dy) * 0.67
        }
        // Inlane guides: deflect toward the center, never create flat pockets.
        collideSegment(&p, CGPoint(x: 55, y: 234), CGPoint(x: 128, y: 130), restitution: 0.76)
        collideSegment(&p, CGPoint(x: 334, y: 234), CGPoint(x: 271, y: 130), restitution: 0.76)
        collideSegment(&p, CGPoint(x: 81, y: 248), CGPoint(x: 110, y: 350), restitution: 0.83)
        collideSegment(&p, CGPoint(x: 313, y: 248), CGPoint(x: 283, y: 350), restitution: 0.83)
        // Slingshots are now physical collision surfaces, not just artwork.
        collideSegment(&p, CGPoint(x: 82, y: 239), CGPoint(x: 121, y: 239), restitution: 0.94)
        collideSegment(&p, CGPoint(x: 82, y: 239), CGPoint(x: 89, y: 190), restitution: 0.94)
        collideSegment(&p, CGPoint(x: 245, y: 239), CGPoint(x: 291, y: 239), restitution: 0.94)
        collideSegment(&p, CGPoint(x: 291, y: 239), CGPoint(x: 284, y: 190), restitution: 0.94)

        // Solid rubber bumpers and target banks use real overlap tests.
        for (i, bumper) in bumperNodes.enumerated() {
            let q = bumper.position
            let d = hypot(p.x-q.x, p.y-q.y)
            if d < 33 {
                let nx: CGFloat = d > 0.01 ? (p.x-q.x)/d : 0
                let ny: CGFloat = d > 0.01 ? (p.y-q.y)/d : 1
                p = CGPoint(x: q.x + nx*33.5, y: q.y + ny*33.5)
                let toward = ballVelocity.dx*nx + ballVelocity.dy*ny
                let key = "bumper_\(i)"
                if toward < 0 {
                    reflect(nx: nx, ny: ny, restitution: 0.98)
                    if simTime - (lastContactTime[key] ?? -100) > 0.16 {
                        let along = ballVelocity.dx*nx + ballVelocity.dy*ny
                        let extra = max(0, 300 - along)
                        ballVelocity.dx += nx*extra
                        ballVelocity.dy += ny*extra
                        lastContactTime[key] = simTime
                        addScore(100)
                        bonus += 25
                        impactFlash(at: q, points: 100)
                        bumper.run(.sequence([.scale(to: 1.16, duration: 0.05), .scale(to: 1, duration: 0.14)]))
                    }
                }
            }
        }
        for (i, target) in targetNodes.enumerated() {
            let q = target.position
            if abs(p.x - q.x) < 19 && abs(p.y - q.y) < 24 {
                if p.y < q.y { p.y = q.y-24; ballVelocity.dy = -max(145, abs(ballVelocity.dy) * 0.86) }
                else { p.y = q.y+24; ballVelocity.dy = max(145, abs(ballVelocity.dy) * 0.86) }
                let key = "target_\(i)"
                if simTime - (lastContactTime[key] ?? -100) > 0.25 {
                    lastContactTime[key] = simTime
                    addScore(250)
                    bonus += 100
                    impactFlash(at: q, points: 250)
                    if bankHits.insert(i).inserted {
                        target.alpha = 0.4
                        if bankHits.count == targetNodes.count {
                            bankHits.removeAll()
                            targetNodes.forEach { $0.alpha = 1 }
                            multiplier = min(5, multiplier + 1)
                            addScore(2000)
                        }
                    }
                }
            }
        }
        for (i, lane) in laneNodes.enumerated() {
            let q = lane.position
            if hypot(p.x-q.x, p.y-q.y) < 18 && laneHits.insert(i).inserted {
                addScore(500)
                bonus += 250
                lane.alpha = 0.35
                if laneHits.count == laneNodes.count {
                    laneHits.removeAll()
                    laneNodes.forEach { $0.alpha = 1 }
                    addScore(2500)
                }
            }
        }
        // Swept contact catches a falling ball between fixed steps.
        if (p.y < 190 || previous.y < 190) && p.y > 68 {
            if p.x > 100 && p.x < 215 { collideFlipper(&p, previous: previous, left: true) }
            if p.x > 183 && p.x < 299 { collideFlipper(&p, previous: previous, left: false) }
        }
        ball.position = p
        bonusLabel.text = "BONUS \(bonus) X\(multiplier)    TARGETS \(bankHits.count)/5    LANES \(laneHits.count)/4"
    }

    private func reflect(nx: CGFloat, ny: CGFloat, restitution: CGFloat) {
        let toward = ballVelocity.dx * nx + ballVelocity.dy * ny
        if toward < 0 {
            ballVelocity.dx -= (1 + restitution) * toward * nx
            ballVelocity.dy -= (1 + restitution) * toward * ny
        }
    }

    private func collideSegment(_ p: inout CGPoint, _ a: CGPoint, _ b: CGPoint, restitution: CGFloat) {
        let dx = b.x-a.x, dy = b.y-a.y
        let t = max(0, min(1, ((p.x-a.x)*dx+(p.y-a.y)*dy) / max(0.01, dx*dx+dy*dy)))
        let q = CGPoint(x: a.x+t*dx, y: a.y+t*dy)
        let distance = hypot(p.x-q.x, p.y-q.y)
        guard distance < 9 else { return }
        let nx = (p.x-q.x) / max(0.01, distance)
        let ny = (p.y-q.y) / max(0.01, distance)
        p.x = q.x+nx*9
        p.y = q.y+ny*9
        reflect(nx: nx, ny: ny, restitution: restitution)
    }

    private func collideFlipper(_ p: inout CGPoint, previous: CGPoint, left: Bool) {
        let active = left ? leftActive : rightActive
        let pivot = CGPoint(x: left ? 125.0 : 274.0, y: 121.0)
        let angle: CGFloat = left ? (active ? 0.40 : -0.23) : (active ? -0.40 : 0.23)
        let dir: CGFloat = left ? 1 : -1
        let length: CGFloat = 70
        let tip = CGPoint(x: pivot.x + dir*length*cos(angle),
                          y: pivot.y + dir*length*sin(angle))
        let dx = tip.x-pivot.x, dy = tip.y-pivot.y
        let t = max(0, min(1, ((p.x-pivot.x)*dx + (p.y-pivot.y)*dy)/(dx*dx+dy*dy)))
        let closest = CGPoint(x: pivot.x+dx*t, y: pivot.y+dy*t)
        let distance = hypot(p.x-closest.x, p.y-closest.y)
        let radius: CGFloat = 16.5 - 3*t
        let contactY = closest.y + radius
        let crossed = ballVelocity.dy < 0 && previous.y >= contactY-3 && p.y <= contactY+3
        let overlapping = distance <= radius+2 && p.y >= closest.y-10 && p.y <= contactY+5
        guard crossed || overlapping else { return }
        p.y = max(p.y, contactY+0.5)
        if active && !tilted {
            let lastHit = left ? lastLeftKick : lastRightKick
            if ballVelocity.dy < 60 && simTime-lastHit > 0.10 {
                let incoming = max(0, -ballVelocity.dy)
                let upward = min(445, 345 + incoming*0.35 + 40*t)
                ballVelocity = CGVector(dx: dir*(43+65*t), dy: upward)
                if left { lastLeftKick = simTime } else { lastRightKick = simTime }
                flipperImpact(at: p)
            } else if ballVelocity.dy < 0 {
                ballVelocity.dy = max(125, abs(ballVelocity.dy)*0.65)
            }
        } else if ballVelocity.dy < 0 {
            ballVelocity = CGVector(dx: ballVelocity.dx*0.75 + dir*22,
                                    dy: max(80, abs(ballVelocity.dy)*0.58))
        }
    }
    private func flipperImpact(at point: CGPoint) {
        let flash = SKShapeNode(circleOfRadius: 9)
        flash.position = point
        flash.fillColor = SKColor(red: 1, green: 0.86, blue: 0.40, alpha: 0.55)
        flash.strokeColor = .white
        flash.lineWidth = 1.5
        flash.zPosition = 30
        playfield.addChild(flash)
        flash.run(.sequence([
            .group([.scale(to: 2.6, duration: 0.16), .fadeOut(withDuration: 0.16)]),
            .removeFromParent()
        ]))
    }

    private func drainBall() {
        awaitingServe = true
        ball?.removeFromParent()
        ball = nil
        plungerCharging = false
        travelingShooterLane = false
        shooterElapsed = 0
        trappedSeconds = 0
        nudges = 0
        let earned = tilted ? 0 : bonus * multiplier
        if earned > 0 { addScore(earned) }
        bonus = 0
        bankHits.removeAll()
        laneHits.removeAll()
        targetNodes.forEach { $0.alpha = 1 }
        laneNodes.forEach { $0.alpha = 1 }
        if ballNumber >= 3 {
            running = false
            statusLabel.text = "GAME OVER — RETURN TO REPLAY"
            subtitleLabel.text = "FINAL SCORE \(score) • BEST \(highScore) • BONUS \(earned)"
        } else {
            ballNumber += 1
            statusLabel.text = "BALL DRAINED"
            subtitleLabel.text = "BONUS \(earned) • NEXT BALL READY"
            run(.sequence([.wait(forDuration: 0.95), .run { [weak self] in self?.serveBall() }]))
        }
        refreshHUD()
    }
}
