import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? FileManager.default.currentDirectoryPath)
let resources = root.appendingPathComponent("RawOptionsApp/Resources", isDirectory: true)
try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

let rect = NSRect(origin: .zero, size: size)
let backgroundPath = NSBezierPath(roundedRect: rect.insetBy(dx: 42, dy: 42), xRadius: 210, yRadius: 210)
NSGraphicsContext.current?.imageInterpolation = .high

let background = NSGradient(colors: [
    NSColor(calibratedRed: 0.06, green: 0.07, blue: 0.09, alpha: 1),
    NSColor(calibratedRed: 0.14, green: 0.18, blue: 0.24, alpha: 1),
    NSColor(calibratedRed: 0.02, green: 0.03, blue: 0.04, alpha: 1)
])!
background.draw(in: backgroundPath, angle: -35)

NSColor(calibratedWhite: 1, alpha: 0.10).setStroke()
backgroundPath.lineWidth = 5
backgroundPath.stroke()

let sensorRect = NSRect(x: 212, y: 230, width: 600, height: 560)
let sensorPath = NSBezierPath(roundedRect: sensorRect, xRadius: 78, yRadius: 78)
NSGradient(colors: [
    NSColor(calibratedRed: 0.58, green: 0.64, blue: 0.70, alpha: 1),
    NSColor(calibratedRed: 0.18, green: 0.22, blue: 0.28, alpha: 1)
])!.draw(in: sensorPath, angle: 90)

NSColor(calibratedWhite: 1, alpha: 0.35).setStroke()
sensorPath.lineWidth = 4
sensorPath.stroke()

let inset = sensorRect.insetBy(dx: 54, dy: 54)
let lensPath = NSBezierPath(ovalIn: inset)
NSGradient(colors: [
    NSColor(calibratedRed: 0.04, green: 0.08, blue: 0.12, alpha: 1),
    NSColor(calibratedRed: 0.00, green: 0.72, blue: 0.92, alpha: 1),
    NSColor(calibratedRed: 0.06, green: 0.08, blue: 0.16, alpha: 1)
])!.draw(in: lensPath, angle: 35)

NSColor(calibratedWhite: 1, alpha: 0.24).setStroke()
lensPath.lineWidth = 10
lensPath.stroke()

for (index, color) in [
    NSColor.systemCyan,
    NSColor.systemBlue,
    NSColor.systemPink,
    NSColor.systemOrange
].enumerated() {
    color.withAlphaComponent(0.72).setFill()
    let x = 292 + CGFloat(index) * 112
    NSBezierPath(roundedRect: NSRect(x: x, y: 658, width: 76, height: 44), xRadius: 18, yRadius: 18).fill()
}

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 360, weight: .black),
    .foregroundColor: NSColor.white,
    .paragraphStyle: paragraph,
    .kern: -12
]
"9".draw(in: NSRect(x: 0, y: 300, width: 1024, height: 420), withAttributes: attributes)

NSColor(calibratedWhite: 1, alpha: 0.22).setFill()
NSBezierPath(ovalIn: NSRect(x: 642, y: 574, width: 92, height: 92)).fill()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Unable to render app icon PNG.")
}

try png.write(to: resources.appendingPathComponent("AppIcon.png"), options: .atomic)
