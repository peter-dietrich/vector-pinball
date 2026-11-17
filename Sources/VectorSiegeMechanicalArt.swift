import AppKit
import SpriteKit

/// All Vector Siege mechanical artwork is deterministic and Git-tracked source.
/// The image textures are rendered locally at build/runtime from these vectors,
/// never downloaded or loaded from a user-specific directory.
enum SiegeMechanicalArt {
    enum Part { case reactor, sentry, shield, flipper, insert, post }

    static func sprite(_ part: Part, size: CGSize, mirrored: Bool = false) -> SKSpriteNode {
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.saveGState()
            if mirrored {
                ctx.translateBy(x: rect.width, y: 0)
                ctx.scaleBy(x: -1, y: 1)
            }
            draw(part, in: rect, context: ctx)
            ctx.restoreGState()
            return true
        }
        let node = SKSpriteNode(texture: SKTexture(image: image), size: size)
        node.zPosition = 2
        return node
    }

    private static let black = NSColor(calibratedRed: 0.025, green: 0.045, blue: 0.075, alpha: 1)
    private static let metal = NSColor(calibratedRed: 0.14, green: 0.23, blue: 0.28, alpha: 1)
    private static let steel = NSColor(calibratedRed: 0.49, green: 0.65, blue: 0.69, alpha: 1)
    private static let green = NSColor(calibratedRed: 0.42, green: 1, blue: 0.22, alpha: 1)
    private static let orange = NSColor(calibratedRed: 1, green: 0.33, blue: 0.14, alpha: 1)

    private static func ellipse(_ rect: CGRect, fill: NSColor, stroke: NSColor? = nil, width: CGFloat = 1) {
        let p = NSBezierPath(ovalIn: rect)
        fill.setFill(); p.fill()
        if let stroke { stroke.setStroke(); p.lineWidth = width; p.stroke() }
    }

    private static func rounded(_ rect: CGRect, radius: CGFloat, fill: NSColor, stroke: NSColor? = nil, width: CGFloat = 1) {
        let p = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        fill.setFill(); p.fill()
        if let stroke { stroke.setStroke(); p.lineWidth = width; p.stroke() }
    }

    private static func poly(_ pts: [CGPoint], fill: NSColor, stroke: NSColor? = nil, width: CGFloat = 1) {
        guard let first = pts.first else { return }
        let p = NSBezierPath()
        p.move(to: first)
        for pt in pts.dropFirst() { p.line(to: pt) }
        p.close()
        fill.setFill(); p.fill()
        if let stroke { stroke.setStroke(); p.lineWidth = width; p.stroke() }
    }

    private static func line(_ a: CGPoint, _ b: CGPoint, color: NSColor, width: CGFloat) {
        let p = NSBezierPath()
        p.move(to: a); p.line(to: b)
        color.setStroke(); p.lineWidth = width; p.stroke()
    }

    private static func draw(_ part: Part, in r: CGRect, context: CGContext) {
        let w = r.width, h = r.height
        switch part {
        case .reactor:
            // Reactor housing, brushed-metal concentric rings and pulsing core.
            ellipse(CGRect(x: 1, y: 1, width: w-2, height: h-2), fill: black, stroke: steel, width: 3)
            ellipse(CGRect(x: 6, y: 6, width: w-12, height: h-12), fill: metal, stroke: green, width: 3)
            ellipse(CGRect(x: 13, y: 13, width: w-26, height: h-26), fill: black, stroke: steel, width: 2)
            ellipse(CGRect(x: 18, y: 18, width: w-36, height: h-36), fill: green.withAlphaComponent(0.85), stroke: .white, width: 1.5)
            ellipse(CGRect(x: w*0.37, y: h*0.54, width: w*0.17, height: h*0.12), fill: .white.withAlphaComponent(0.74))
            for i in 0..<8 {
                let a = CGFloat(i)*(.pi/4)
                let c = CGPoint(x: w/2, y: h/2)
                let inner: CGFloat = w*0.35, outer: CGFloat = w*0.43
                line(CGPoint(x: c.x+cos(a)*inner, y: c.y+sin(a)*inner),
                     CGPoint(x: c.x+cos(a)*outer, y: c.y+sin(a)*outer), color: orange, width: 2)
            }
        case .sentry:
            rounded(CGRect(x: 1, y: 1, width: w-2, height: h-2), radius: 5, fill: black, stroke: steel, width: 2)
            poly([CGPoint(x: 3, y: h*0.23), CGPoint(x: w*0.30, y: h*0.78),
                  CGPoint(x: w*0.69, y: h*0.78), CGPoint(x: w-3, y: h*0.23)],
                 fill: metal, stroke: green, width: 1.5)
            rounded(CGRect(x: w*0.24, y: h*0.30, width: w*0.52, height: h*0.29), radius: 2,
                    fill: orange, stroke: .white, width: 1)
            line(CGPoint(x: w*0.5, y: h*0.60), CGPoint(x: w*0.5, y: h*0.93), color: steel, width: 2)
            for i in 0..<3 {
                let x = w*(0.22+CGFloat(i)*0.28)
                ellipse(CGRect(x: x, y: h*0.11, width: 2.4, height: 2.4), fill: green)
            }
        case .shield:
            poly([CGPoint(x: 1, y: h*0.94), CGPoint(x: w*0.85, y: h*0.95),
                  CGPoint(x: w-2, y: h*0.18), CGPoint(x: w*0.47, y: 1),
                  CGPoint(x: w*0.06, y: h*0.18)],
                 fill: black, stroke: steel, width: 2.5)
            poly([CGPoint(x: 6, y: h*0.85), CGPoint(x: w*0.72, y: h*0.86),
                  CGPoint(x: w-8, y: h*0.21), CGPoint(x: w*0.45, y: 6)],
                 fill: metal, stroke: green, width: 1.5)
            for j in 0..<3 {
                let y = h*(0.32+CGFloat(j)*0.19)
                line(CGPoint(x: w*0.28, y: y), CGPoint(x: w*0.73, y: y),
                     color: green.withAlphaComponent(0.6), width: 1.5)
            }
            ellipse(CGRect(x: w*0.49, y: h*0.66, width: 6, height: 6), fill: orange, stroke: .white, width: 1)
        case .flipper:
            // Textured metal bat with tapered armor and neon rubber edge.
            poly([CGPoint(x: 1, y: 4), CGPoint(x: w*0.82, y: h*0.27),
                  CGPoint(x: w-3, y: h*0.42), CGPoint(x: w-3, y: h*0.58),
                  CGPoint(x: w*0.82, y: h*0.73), CGPoint(x: 1, y: h-4)],
                 fill: metal, stroke: steel, width: 2.2)
            poly([CGPoint(x: w*0.10, y: h*0.30), CGPoint(x: w*0.77, y: h*0.39),
                  CGPoint(x: w*0.89, y: h*0.50), CGPoint(x: w*0.77, y: h*0.61),
                  CGPoint(x: w*0.10, y: h*0.70)],
                 fill: black, stroke: green, width: 1.7)
            line(CGPoint(x: w*0.12, y: h*0.77), CGPoint(x: w*0.80, y: h*0.64), color: orange, width: 2.5)
            for i in 0..<4 {
                let x = w*(0.29+CGFloat(i)*0.15)
                line(CGPoint(x: x, y: h*0.43), CGPoint(x: x, y: h*0.57),
                     color: steel.withAlphaComponent(0.8), width: 1)
            }
            ellipse(CGRect(x: 2, y: h/2-6, width: 12, height: 12), fill: steel, stroke: .white, width: 1)
        case .insert:
            ellipse(CGRect(x: 1, y: 1, width: w-2, height: h-2), fill: black, stroke: steel, width: 1.6)
            ellipse(CGRect(x: 4, y: 4, width: w-8, height: h-8), fill: green.withAlphaComponent(0.85), stroke: .white, width: 1)
            line(CGPoint(x: w*0.28, y: h*0.50), CGPoint(x: w*0.72, y: h*0.50), color: black, width: 1.7)
            line(CGPoint(x: w*0.50, y: h*0.28), CGPoint(x: w*0.50, y: h*0.72), color: black, width: 1.7)
        case .post:
            ellipse(CGRect(x: 0.5, y: 0.5, width: w-1, height: h-1), fill: black, stroke: steel, width: 2)
            ellipse(CGRect(x: 3, y: 3, width: w-6, height: h-6), fill: metal, stroke: green, width: 1)
            line(CGPoint(x: w*0.31, y: h*0.50), CGPoint(x: w*0.69, y: h*0.50), color: steel, width: 1)
        }
    }
}
