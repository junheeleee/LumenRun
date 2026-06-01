import AppKit

let size = CGSize(width: 1024, height: 1024)
let outputPath = "LumenRun/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(red: red, green: green, blue: blue, alpha: alpha)
}

let teal = color(0.0, 0.9, 0.82)
let gold = color(1.0, 0.84, 0.12)
let magenta = color(1.0, 0.18, 0.48)
let purple = color(0.48, 0.12, 0.72)
let center = CGPoint(x: 512, y: 512)

func radians(_ degrees: CGFloat) -> CGFloat {
    degrees * .pi / 180
}

func point(on radius: CGFloat, degrees: CGFloat) -> CGPoint {
    CGPoint(
        x: center.x + cos(radians(degrees)) * radius,
        y: center.y + sin(radians(degrees)) * radius
    )
}

func circlePath(center: CGPoint, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
}

func arcPath(radius: CGFloat, startDegrees: CGFloat, endDegrees: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    path.appendArc(withCenter: center, radius: radius, startAngle: startDegrees, endAngle: endDegrees, clockwise: false)
    return path
}

func starPath(center: CGPoint, outer: CGFloat, inner: CGFloat, points: Int, rotation: CGFloat = -.pi / 2) -> NSBezierPath {
    let path = NSBezierPath()
    for index in 0..<(points * 2) {
        let radius = index.isMultiple(of: 2) ? outer : inner
        let angle = CGFloat(index) / CGFloat(points * 2) * 2 * .pi + rotation
        let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        if index == 0 {
            path.move(to: point)
        } else {
            path.line(to: point)
        }
    }
    path.close()
    return path
}

func polygonPath(center: CGPoint, sides: Int, radius: CGFloat, rotation: CGFloat = -.pi / 2) -> NSBezierPath {
    let path = NSBezierPath()
    for index in 0..<sides {
        let angle = CGFloat(index) / CGFloat(sides) * 2 * .pi + rotation
        let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        if index == 0 {
            path.move(to: point)
        } else {
            path.line(to: point)
        }
    }
    path.close()
    return path
}

func plusPath(center: CGPoint, size: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: center.x, y: center.y - size / 2))
    path.line(to: CGPoint(x: center.x, y: center.y + size / 2))
    path.move(to: CGPoint(x: center.x - size / 2, y: center.y))
    path.line(to: CGPoint(x: center.x + size / 2, y: center.y))
    return path
}

func xPath(center: CGPoint, size: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: center.x - size / 2, y: center.y - size / 2))
    path.line(to: CGPoint(x: center.x + size / 2, y: center.y + size / 2))
    path.move(to: CGPoint(x: center.x + size / 2, y: center.y - size / 2))
    path.line(to: CGPoint(x: center.x - size / 2, y: center.y + size / 2))
    return path
}

func disruptPath(center: CGPoint, size: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: center.x - size * 0.42, y: center.y + size * 0.36))
    path.line(to: CGPoint(x: center.x - size * 0.08, y: center.y + size * 0.05))
    path.line(to: CGPoint(x: center.x - size * 0.3, y: center.y + size * 0.05))
    path.move(to: CGPoint(x: center.x + size * 0.42, y: center.y - size * 0.36))
    path.line(to: CGPoint(x: center.x + size * 0.08, y: center.y - size * 0.05))
    path.line(to: CGPoint(x: center.x + size * 0.3, y: center.y - size * 0.05))
    return path
}

func signalLinePath(y: CGFloat, offset: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: 96, y: y))
    path.curve(
        to: CGPoint(x: 928, y: y + offset),
        controlPoint1: CGPoint(x: 312, y: y - 26),
        controlPoint2: CGPoint(x: 704, y: y + 26)
    )
    return path
}

func drawWithShadow(color: NSColor, blur: CGFloat, _ draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color
    shadow.shadowBlurRadius = blur
    shadow.shadowOffset = .zero
    shadow.set()
    draw()
    NSGraphicsContext.restoreGraphicsState()
}

func stroke(_ path: NSBezierPath, color: NSColor, lineWidth: CGFloat, cap: NSBezierPath.LineCapStyle = .round) {
    color.setStroke()
    path.lineWidth = lineWidth
    path.lineCapStyle = cap
    path.lineJoinStyle = .round
    path.stroke()
}

func fill(_ path: NSBezierPath, color: NSColor) {
    color.setFill()
    path.fill()
}

func drawRoute(radius: CGFloat, start: CGFloat, end: CGFloat, routeColor: NSColor, lineWidth: CGFloat) {
    let route = arcPath(radius: radius, startDegrees: start, endDegrees: end)
    stroke(route, color: routeColor.withAlphaComponent(0.14), lineWidth: lineWidth * 3.6)

    drawWithShadow(color: routeColor.withAlphaComponent(0.42), blur: lineWidth * 2.4) {
        stroke(route, color: routeColor.withAlphaComponent(0.84), lineWidth: lineWidth)
    }

    let highlight = arcPath(radius: radius, startDegrees: start + 8, endDegrees: min(end - 10, start + 54))
    stroke(highlight, color: .white.withAlphaComponent(0.42), lineWidth: lineWidth * 0.34)
}

func drawSpark(at position: CGPoint, radius: CGFloat) {
    drawWithShadow(color: gold.withAlphaComponent(0.5), blur: radius * 1.2) {
        fill(starPath(center: position, outer: radius, inner: radius * 0.42, points: 5), color: gold)
        stroke(starPath(center: position, outer: radius, inner: radius * 0.42, points: 5), color: .white.withAlphaComponent(0.66), lineWidth: radius * 0.12)
    }

    let badgeCenter = CGPoint(x: position.x + radius * 0.68, y: position.y + radius * 0.68)
    fill(circlePath(center: badgeCenter, radius: radius * 0.36), color: gold.withAlphaComponent(0.96))
    stroke(circlePath(center: badgeCenter, radius: radius * 0.36), color: .white.withAlphaComponent(0.9), lineWidth: radius * 0.09)
    stroke(plusPath(center: badgeCenter, size: radius * 0.46), color: .white.withAlphaComponent(0.96), lineWidth: radius * 0.12)
}

func drawGlitchShard(at position: CGPoint, radius: CGFloat) {
    let warning = polygonPath(center: position, sides: 3, radius: radius * 1.34)
    stroke(warning, color: magenta.withAlphaComponent(0.82), lineWidth: radius * 0.13)

    drawWithShadow(color: magenta.withAlphaComponent(0.5), blur: radius * 1.1) {
        fill(starPath(center: position, outer: radius, inner: radius * 0.58, points: 6), color: magenta)
        stroke(starPath(center: position, outer: radius, inner: radius * 0.58, points: 6), color: .white.withAlphaComponent(0.36), lineWidth: radius * 0.08)
    }

    stroke(xPath(center: position, size: radius * 1.1), color: .black.withAlphaComponent(0.66), lineWidth: radius * 0.16)
}

func drawVoidGate(radius: CGFloat, angle: CGFloat) {
    let gate = arcPath(radius: radius, startDegrees: angle - 16, endDegrees: angle + 16)
    drawWithShadow(color: purple.withAlphaComponent(0.52), blur: 24) {
        stroke(gate, color: purple.withAlphaComponent(0.82), lineWidth: 26)
    }

    let marker = point(on: radius, degrees: angle)
    stroke(disruptPath(center: marker, size: 46), color: .white.withAlphaComponent(0.86), lineWidth: 7)
    fill(circlePath(center: marker, radius: 10), color: purple.withAlphaComponent(0.92))
    stroke(circlePath(center: marker, radius: 10), color: .white.withAlphaComponent(0.5), lineWidth: 2)
}

func drawRelayCore() {
    drawWithShadow(color: teal.withAlphaComponent(0.36), blur: 44) {
        stroke(circlePath(center: center, radius: 124), color: teal.withAlphaComponent(0.22), lineWidth: 30)
    }

    drawWithShadow(color: gold.withAlphaComponent(0.6), blur: 54) {
        fill(circlePath(center: center, radius: 98), color: gold)
    }

    stroke(circlePath(center: center, radius: 72), color: .white.withAlphaComponent(0.74), lineWidth: 12)
    fill(polygonPath(center: center, sides: 4, radius: 34, rotation: .pi / 4), color: .white.withAlphaComponent(0.92))
    stroke(plusPath(center: center, size: 68), color: teal.withAlphaComponent(0.9), lineWidth: 8)
}

let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size.width),
    pixelsHigh: Int(size.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

let rect = CGRect(origin: .zero, size: size)
let background = NSGradient(colors: [
    color(0.012, 0.016, 0.045),
    color(0.014, 0.07, 0.09),
    color(0.04, 0.018, 0.06)
])!
background.draw(in: rect, angle: -90)

for index in 0..<7 {
    let y = CGFloat(index) * 128 + 124
    let line = signalLinePath(y: y, offset: index.isMultiple(of: 2) ? 18 : -18)
    stroke(line, color: teal.withAlphaComponent(index.isMultiple(of: 3) ? 0.055 : 0.032), lineWidth: index.isMultiple(of: 3) ? 2 : 1.2)
}

for radius in stride(from: CGFloat(210), through: CGFloat(420), by: CGFloat(70)) {
    stroke(circlePath(center: center, radius: radius), color: teal.withAlphaComponent(0.04), lineWidth: 2)
}

drawRoute(radius: 208, start: 202, end: 520, routeColor: teal, lineWidth: 15)
drawRoute(radius: 304, start: 18, end: 298, routeColor: gold, lineWidth: 12)
drawRoute(radius: 398, start: 104, end: 362, routeColor: magenta, lineWidth: 10)

drawVoidGate(radius: 398, angle: 156)
drawSpark(at: point(on: 304, degrees: 36), radius: 42)
drawSpark(at: point(on: 208, degrees: 252), radius: 30)
drawGlitchShard(at: point(on: 398, degrees: 326), radius: 40)

drawRelayCore()

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not render app icon")
}

try png.write(to: URL(fileURLWithPath: outputPath))
print("Wrote \(outputPath)")
