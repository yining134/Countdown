import AppKit

let width = 512, height = 640
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
                             bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                             colorSpaceName: .deviceRGB, bytesPerRow: width * 4, bitsPerPixel: 32)!
bitmap.bitmapData!.initialize(repeating: 0, count: width * height * 4)
let soil = NSColor(srgbRed: 0.47, green: 0.28, blue: 0.16, alpha: 1)
let stem = NSColor(srgbRed: 0.22, green: 0.49, blue: 0.25, alpha: 1)
let leaf = NSColor(srgbRed: 0.40, green: 0.73, blue: 0.34, alpha: 1)
let light = NSColor(srgbRed: 0.70, green: 0.88, blue: 0.40, alpha: 1)
for row in 0..<5 {
    for frame in 0..<4 {
        let originX = frame * 128, originY = row * 128
        let sway = [0, 3, 0, -3][frame] * (row == 4 ? 2 : 1)
        func rect(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ color: NSColor) {
            for py in y..<y+h { for px in x..<x+w {
                let index = ((originY + py) * width + originX + px) * 4
                let pixel = bitmap.bitmapData!
                pixel[index] = UInt8(color.redComponent * 255)
                pixel[index + 1] = UInt8(color.greenComponent * 255)
                pixel[index + 2] = UInt8(color.blueComponent * 255)
                pixel[index + 3] = 255
            } }
        }
        rect(34, 108, 60, 6, soil)
        rect(42, 114, 44, 4, soil)
        if row == 0 {
            rect(56, 96 + frame % 2, 16, 12, soil)
            rect(60, 94 + frame % 2, 8, 4, light)
        } else {
            let top = [0, 80, 60, 38, 38][row]
            rect(61 + sway, top, 6, 108 - top, stem)
            rect(43 + sway, top + 6, 18, 8, leaf)
            rect(39 + sway, top + 2, 14, 8, light)
            rect(67 + sway, top - 4, 18, 8, leaf)
            rect(77 + sway, top - 8, 12, 8, light)
            if row >= 2 {
                rect(44 + sway, top + 26, 20, 8, leaf)
                rect(67 + sway, top + 36, 20, 8, light)
            }
            if row >= 3 {
                rect(35 + sway, top + 12, 10, 12, leaf)
                rect(85 + sway, top + 2, 10, 12, leaf)
            }
            if row == 4 {
                rect(22, 28 + frame * 3, 4, 8, light)
                rect(102, 44 - frame * 3, 4, 8, light)
                rect(62, 12 + frame % 2 * 4, 6, 6, light)
            }
        }
    }
}
let destination = CommandLine.arguments[1]
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: destination))
