import AppKit
import ImageIO
import UniformTypeIdentifiers
import AVFoundation

struct SkinError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct SkinValidator {
    static func load(directory: URL, builtIn: Bool = false) throws -> Skin {
        let manifestURL = directory.appendingPathComponent("skin.json")
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: manifestURL.path),
              let bytes = attributes[.size] as? Int, bytes <= 65536 else {
            throw SkinError(message: "缺少 skin.json，或清单超过 64 KiB。")
        }
        let manifest = try JSONDecoder().decode(SkinManifest.self, from: Data(contentsOf: manifestURL))
        guard manifest.schemaVersion == 1 else { throw SkinError(message: "不支持此皮肤协议版本。") }
        guard manifest.id.range(of: "^[a-z0-9][a-z0-9.-]{0,79}$", options: .regularExpression) != nil,
              !manifest.id.contains(".."), !manifest.name.isEmpty, manifest.name.count <= 80 else {
            throw SkinError(message: "皮肤 ID 或名称不合法。")
        }
        let size = manifest.frameSize
        guard (1...512).contains(size.width), (1...512).contains(size.height),
              (1...100).contains(manifest.animations.count),
              manifest.stages.count <= 100, manifest.stages.first?.from == 0 else {
            throw SkinError(message: "帧尺寸、动画数量或进度阶段不合法。")
        }
        let imageURL = try resource(manifest.spritesheet, in: directory)
        guard let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              (CGImageSourceGetType(source) as String?) == UTType.png.identifier,
              CGImageSourceGetCount(source) == 1,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              let depth = properties[kCGImagePropertyDepth] as? Int, depth <= 8,
              width > 0, height > 0, width <= 8192, height <= 8192,
              width * height <= 16_777_216,
              width % size.width == 0, height % size.height == 0 else {
            throw SkinError(message: "图集须为 8-bit 静态 PNG、尺寸为帧尺寸的整数倍，且解码预算不超过 64 MiB。")
        }
        let frameTotal = (width / size.width) * (height / size.height)
        for animation in manifest.animations.values {
            guard animation.startFrame >= 0, (1...300).contains(animation.frameCount),
                  animation.startFrame <= frameTotal - animation.frameCount,
                  animation.fps.isFinite, (1...30).contains(animation.fps) else {
                throw SkinError(message: "动画帧范围越界或帧率不在 1–30 之间。")
            }
        }
        var previous = -1.0
        for stage in manifest.stages {
            guard stage.from.isFinite, stage.from >= 0, stage.from < 1, stage.from > previous,
                  manifest.animations[stage.animation] != nil else {
                throw SkinError(message: "进度阶段须从 0 开始、严格递增，并引用已有动画。")
            }
            previous = stage.from
        }
        for name in [manifest.idle, manifest.completed] + [manifest.paused].compactMap({ $0 }) {
            guard manifest.animations[name] != nil else { throw SkinError(message: "动画引用不存在：\(name)") }
        }
        if let sound = manifest.completionSound {
            let url = try resource(sound, in: directory)
            guard ["wav", "mp3", "m4a"].contains(url.pathExtension.lowercased()) else {
                throw SkinError(message: "完成音效仅支持 WAV、MP3、M4A。")
            }
            let player = try AVAudioPlayer(contentsOf: url)
            guard player.duration > 0, player.duration <= 10 else { throw SkinError(message: "音效时长须在 10 秒以内。") }
        }
        return Skin(manifest: manifest, directory: directory, isBuiltIn: builtIn)
    }

    static func resource(_ path: String, in directory: URL) throws -> URL {
        let parts = path.split(separator: "/", omittingEmptySubsequences: false)
        guard !path.isEmpty, !path.hasPrefix("/"), !path.contains("\\"),
              !path.contains(":"), !path.contains("\0"),
              parts.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else {
            throw SkinError(message: "非法资源路径：\(path)")
        }
        let root = directory.resolvingSymlinksInPath().standardizedFileURL
        let url = root.appendingPathComponent(path).resolvingSymlinksInPath().standardizedFileURL
        guard url.path.hasPrefix(root.path + "/"),
              (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else {
            throw SkinError(message: "资源不存在或越界：\(path)")
        }
        return url
    }
}
