import Foundation
import ImageIO

struct SpriteAsset: @unchecked Sendable {
    let image: CGImage
}

struct AnimationLoader {
    static func load(_ url: URL) async throws -> SpriteAsset {
        try await Task.detached(priority: .userInitiated) {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let image = CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary) else {
                throw SkinError(message: "无法解码 PNG 图集。")
            }
            return SpriteAsset(image: image)
        }.value
    }

    static func preview(skin: Skin) async throws -> SpriteAsset {
        try await Task.detached(priority: .utility) {
            let url = try SkinValidator.resource(skin.manifest.spritesheet, in: skin.directory)
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                  let width = properties[kCGImagePropertyPixelWidth] as? Int,
                  let height = properties[kCGImagePropertyPixelHeight] as? Int,
                  let animation = skin.manifest.animations[skin.manifest.completed],
                  let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceThumbnailMaxPixelSize: 1024,
                    kCGImageSourceShouldCacheImmediately: true
                  ] as CFDictionary) else { throw SkinError(message: "无法读取主题预览。") }
            let size = skin.manifest.frameSize
            let columns = width / size.width
            let scaleX = Double(image.width) / Double(width)
            let scaleY = Double(image.height) / Double(height)
            let rect = CGRect(x: Double(animation.startFrame % columns * size.width) * scaleX,
                              y: Double(animation.startFrame / columns * size.height) * scaleY,
                              width: Double(size.width) * scaleX, height: Double(size.height) * scaleY)
            guard let frame = image.cropping(to: rect) else { throw SkinError(message: "无法读取主题预览帧。") }
            return SpriteAsset(image: frame)
        }.value
    }
}
