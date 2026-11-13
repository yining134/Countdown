import Foundation
import ImageIO

struct AnimationLoader {
    static func load(_ url: URL) async throws -> SpriteAsset {
        try await Task.detached(priority: .userInitiated) {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                let image = CGImageSourceCreateImageAtIndex(
                    source, 0, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary)
            else {
                throw SkinError(message: L10n.text("无法解码 PNG 图集。"))
            }
            return SpriteAsset(image: image)
        }.value
    }

    static func preview(skin: Skin) async throws -> SpriteAsset {
        try await Task.detached(priority: .utility) {
            let url = try SkinValidator.resource(skin.manifest.spriteSheetPath, in: skin.directory)
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                let width = properties[kCGImagePropertyPixelWidth] as? Int,
                let animation = skin.manifest.animations[skin.manifest.completed],
                let image = CGImageSourceCreateImageAtIndex(
                    source, 0, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary)
            else { throw SkinError(message: L10n.text("无法读取主题预览。")) }
            let size = skin.manifest.frameSize
            let columns = width / size.width
            let rect = CGRect(
                x: animation.startFrame % columns * size.width,
                y: animation.startFrame / columns * size.height,
                width: size.width, height: size.height)
            guard let frame = image.cropping(to: rect) else { throw SkinError(message: L10n.text("无法读取主题预览帧。")) }
            return SpriteAsset(image: frame)
        }.value
    }
}
