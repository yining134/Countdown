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
}
