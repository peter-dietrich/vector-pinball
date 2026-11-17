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
    private var trappedSeconds: TimeInterval = 0
    private var lastBallPoint = CGPoint.zero
    private var lastTime: TimeInterval = 0
    private var nudges = 0
    private var showDebug = false
    private var lastFlipperKick: TimeInterval = 0
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
        physicsWorld.gravity = CGVector(dx: 0, dy: -520)
        physicsWorld.contactDelegate = self
        addChild(playfield)
        buildTable()
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
        shape.physicsBody?.restitution = 0.70
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

        label("CLASSIC '82", at: CGPoint(x: 197, y: 635), size: 22, color: .init(red: 1, green: 0.81, blue: 0.43, alpha: 1))
        label("THE ORIGINAL ARCADE TABLE", at: CGPoint(x: 197, y: 614), size: 8, color: .init(red: 0.63, green: 0.83, blue: 0.90, alpha: 1))
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
            target.physicsBody?.restitution = 0.9
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
            bumper.physicsBody?.restitution = 1.15
            playfield.addChild(bumper)
            let inset = SKShapeNode(circleOfRadius: 13)
            inset.fillColor = .init(red: 0.99, green: 0.71, blue: 0.29, alpha: 1)
            inset.strokeColor = .white
            inset.lineWidth = 2
            bumper.addChild(inset)
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
            slingshot.physicsBody?.restitution = 1.05
            playfield.addChild(slingshot)
        }
        leftFlipper = makeFlipper(at: CGPoint(x: 139, y: 121), left: true)
        rightFlipper = makeFlipper(at: CGPoint(x: 260, y: 121), left: false)
        label("LAUNCH", at: CGPoint(x: 362, y: 48), size: 8, color: .systemOrange)
    }

    private func makeFlipper(at position: CGPoint, left: Bool) -> SKShapeNode {
        let length: CGFloat = 78
        let shape = SKShapeNode(rectOf: CGSize(width: length, height: 16), cornerRadius: 8)
        shape.position = position
        shape.fillColor = .init(red: 0.96, green: 0.70, blue: 0.30, alpha: 1)
        shape.strokeColor = .white
        shape.lineWidth = 1.5
        shape.zRotation = left ? -0.30 : 0.30
        shape.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: length, height: 16))
        shape.physicsBody?.isDynamic = false
        shape.physicsBody?.categoryBitMask = Collision.flipper
        shape.physicsBody?.restitution = 0.65
        shape.physicsBody?.friction = 0.2
        playfield.addChild(shape)
        return shape
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
        subtitleLabel.text = "A / D FLIPPERS • SPACE PLUNGER • P PAUSE"
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
        trappedSeconds = 0
        bonus = 0
        multiplier = 1
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
        node.fillColor = .init(red: 0.90, green: 0.94, blue: 0.99, alpha: 1)
        node.strokeColor = .white
        node.lineWidth = 2
        node.glowWidth = 1
        node.position = CGPoint(x: 362, y: 105)
        let body = SKPhysicsBody(circleOfRadius: 8)
        body.affectedByGravity = false
        body.restitution = 0.79
        body.friction = 0.055
        body.linearDamping = 0.12
        body.angularDamping = 0.22
        body.mass = 0.075
        body.categoryBitMask = Collision.ball
        body.collisionBitMask = UInt32.max
        body.contactTestBitMask = Collision.bumper | Collision.target | Collision.lane
        body.usesPreciseCollisionDetection = true
        node.physicsBody = body
        node.zPosition = 10
        playfield.addChild(node)
        ball = node
        awaitingServe = false
        travelingShooterLane = false
        trappedSeconds = 0
        lastBallPoint = node.position
        tilted = false
        refreshHUD()
    }

    private func launchBall() {
        guard running, !travelingShooterLane, let ball,
              ball.position.x > 345, ball.position.y < 180 else { return }
        travelingShooterLane = true
        // Keep the ball centered in the dedicated shooter channel until it reaches
        // the upper feed. A leftward impulse here caused it to hit the lane divider.
        ball.physicsBody?.affectedByGravity = false
        ball.physicsBody?.velocity = CGVector(dx: 0, dy: 770 + plungerCharge * 200)
        plungerCharging = false
        plungerCharge = 0
        statusLabel.text = "BALL LAUNCHED"
        subtitleLabel.text = "USE A / D OR SHIFT FOR FLIPPERS"
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
        default: break
        }
    }

    func setFlipper(left: Bool, active: Bool) {
        if left { leftActive = active } else { rightActive = active }
        let node = left ? leftFlipper : rightFlipper
        let angle: CGFloat = left ? (active ? 0.38 : -0.30) : (active ? -0.38 : 0.30)
        node?.removeAction(forKey: "flip")
        node?.run(SKAction.rotate(toAngle: angle, duration: active ? 0.045 : 0.085, shortestUnitArc: true), withKey: "flip")
        guard active, running, !tilted, let ball, simTime-lastFlipperKick > 0.045 else { return }
        // A tuned upward kick supplements SpriteKit's static rotating-shape collision.
        let dx = ball.position.x - (node?.position.x ?? 0)
        let dy = ball.position.y - (node?.position.y ?? 0)
        if abs(dx) < 80 && dy > -10 && dy < 53 {
            let vx = left ? 110.0 : -110.0
            ball.physicsBody?.applyImpulse(CGVector(dx: vx * 0.075, dy: 36))
            lastFlipperKick = simTime
        }
    }

    private func nudge(direction: UInt16) {
        guard running, let ball, nudges < 4 else { return }
        nudges += 1
        let impulse: CGVector
        switch direction {
        case 123: impulse = CGVector(dx: -5, dy: 2.5)
        case 124: impulse = CGVector(dx: 5, dy: 2.5)
        default: impulse = CGVector(dx: 0, dy: 7.5)
        }
        ball.physicsBody?.applyImpulse(impulse)
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
            if let ball {
                let dx = ball.position.x - contact.contactPoint.x
                ball.physicsBody?.applyImpulse(CGVector(dx: dx * 0.12, dy: 8))
            }
        } else if bits & Collision.target != 0 {
            addScore(250)
            bonus += 100
            if let name = other.node?.name, let index = Int(name.replacingOccurrences(of: "target_", with: "")), !bankHits.contains(index) {
                bankHits.insert(index)
                targetNodes[index].alpha = 0.35
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

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 0 : min(currentTime-lastTime, 1.0/20.0)
        lastTime = currentTime
        simTime += dt
        if plungerCharging && running {
            plungerCharge = min(1, plungerCharge + dt/1.2)
            if plungerCharge >= 1 {
                // Automatic launch provides a reliable fallback if macOS does
                // not deliver keyUp (e.g. focus or modifier-key interactions).
                launchBall()
            } else {
                refreshHUD()
            }
        }
        guard running, let ball, !awaitingServe else { return }
        if travelingShooterLane {
            if ball.position.y >= 568 {
                travelingShooterLane = false
                // Feed into the upper-right playfield, clear of both shooter
                // divider and outside cabinet walls.
                ball.position = CGPoint(x: 319, y: 609)
                ball.physicsBody?.affectedByGravity = true
                ball.physicsBody?.velocity = CGVector(dx: -145, dy: 130)
                statusLabel.text = "PLAY BALL"
            } else if ball.position.y < 75 {
                // Safety reset for an unexpected lane collision.
                ball.position = CGPoint(x: 362, y: 105)
                ball.physicsBody?.velocity = CGVector(dx: 0, dy: 800)
            }
        }
        if ball.position.y < 46 || ball.position.x < 25 || ball.position.x > 395 {
            drainBall()
            return
        }
        if let body = ball.physicsBody {
            let speed = hypot(body.velocity.dx, body.velocity.dy)
            if speed > 1550 {
                let factor = 1550/speed
                body.velocity = CGVector(dx: body.velocity.dx * factor, dy: body.velocity.dy * factor)
            }
            if showDebug {
                debugLabel.text = String(format: "BALL (%.0f, %.0f)  V %.0f  NUDGE %d/4", ball.position.x, ball.position.y, speed, nudges)
            }
        }
    }

    private func drainBall() {
        awaitingServe = true
        ball?.removeFromParent()
        ball = nil
        plungerCharging = false
        travelingShooterLane = false
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
