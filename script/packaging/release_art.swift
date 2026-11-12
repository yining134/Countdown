import AppKit
import ImageIO

enum ArtworkError: Error {
    case invalidArguments, bitmapCreationFailed, pngEncodingFailed, invalidSpriteSheet
}

struct ArtworkManifest: Decodable {
    struct FrameSize: Decodable {
        let width: Int
        let height: Int
    }
    struct Animation: Decodable { let startFrame: Int }
    let frameSize: FrameSize
    let animations: [String: Animation]
    let completed: String
}

guard CommandLine.arguments.count == 3 else { throw ArtworkError.invalidArguments }
let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let source = URL(fileURLWithPath: CommandLine.arguments[2])
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func png(size: NSSize, draw: (CGContext) -> Void) throws -> Data {
    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
        let graphics = NSGraphicsContext(bitmapImageRep: bitmap)
    else { throw ArtworkError.bitmapCreationFailed }
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = graphics
    draw(graphics.cgContext)
    guard let data = bitmap.representation(using: .png, properties: [:]) else { throw ArtworkError.pngEncodingFailed }
    return data
}

let background = try png(size: NSSize(width: 640, height: 400)) { _ in
    NSColor(srgbRed: 0.96, green: 0.97, blue: 0.98, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: 640, height: 400).fill()
    func text(_ value: String, y: CGFloat, size: CGFloat, color: NSColor) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size, weight: .medium), .foregroundColor: color,
        ]
        let string = value as NSString
        string.draw(
            at: NSPoint(x: (640 - string.size(withAttributes: attributes).width) / 2, y: y), withAttributes: attributes)
    }
    text("Countdown", y: 330, size: 28, color: .darkGray)
    text("Drag Countdown to Applications", y: 290, size: 16, color: .gray)
    let arrow = NSBezierPath()
    arrow.move(to: NSPoint(x: 282, y: 200))
    arrow.line(to: NSPoint(x: 358, y: 200))
    arrow.move(to: NSPoint(x: 343, y: 215))
    arrow.line(to: NSPoint(x: 358, y: 200))
    arrow.line(to: NSPoint(x: 343, y: 185))
    arrow.lineWidth = 4
    arrow.lineCapStyle = .round
    NSColor.lightGray.setStroke()
    arrow.stroke()
}
try background.write(to: output.appendingPathComponent("background.png"))

let manifestURL = source.deletingLastPathComponent().appendingPathComponent("skin.json")
let manifest = try JSONDecoder().decode(ArtworkManifest.self, from: Data(contentsOf: manifestURL))
guard let imageSource = CGImageSourceCreateWithURL(source as CFURL, nil),
    let sheet = CGImageSourceCreateImageAtIndex(imageSource, 0, nil),
    manifest.frameSize.width > 0, manifest.frameSize.height > 0,
    sheet.width >= manifest.frameSize.width,
    let animation = manifest.animations[manifest.completed], animation.startFrame >= 0
else { throw ArtworkError.invalidSpriteSheet }
let columns = sheet.width / manifest.frameSize.width
let frameRect = CGRect(
    x: (animation.startFrame % columns) * manifest.frameSize.width,
    y: (animation.startFrame / columns) * manifest.frameSize.height,
    width: manifest.frameSize.width, height: manifest.frameSize.height)
guard let flower = sheet.cropping(to: frameRect) else { throw ArtworkError.invalidSpriteSheet }
let iconset = output.appendingPathComponent("Countdown.iconset", isDirectory: true)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let edge = CGFloat(pixels)
        let data = try png(size: NSSize(width: edge, height: edge)) { context in
            NSColor(srgbRed: 0.12, green: 0.17, blue: 0.19, alpha: 1).setFill()
            NSBezierPath(
                roundedRect: NSRect(x: edge * 0.05, y: edge * 0.05, width: edge * 0.9, height: edge * 0.9),
                xRadius: edge * 0.2, yRadius: edge * 0.2
            ).fill()
            context.interpolationQuality = .none
            context.draw(flower, in: CGRect(x: edge * 0.08, y: edge * 0.08, width: edge * 0.84, height: edge * 0.84))
        }
        let suffix = scale == 2 ? "@2x" : ""
        try data.write(to: iconset.appendingPathComponent("icon_\(size)x\(size)\(suffix).png"))
    }
}
