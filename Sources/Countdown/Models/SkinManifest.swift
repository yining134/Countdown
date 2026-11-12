import Foundation

struct SkinManifest: Codable {
    struct FrameSize: Codable { let width: Int; let height: Int }
    struct Animation: Codable {
        let startFrame: Int
        let frameCount: Int
        let fps: Double
    }
    struct Stage: Codable { let from: Double; let animation: String }
    let schemaVersion: Int
    let id: String
    let name: String
    let author: String?
    let spritesheet: String
    let frameSize: FrameSize
    let animations: [String: Animation]
    let idle: String
    let stages: [Stage]
    let paused: String?
    let completed: String
    let completionSound: String?

    func animationName(phase: CountdownPhase, progress: Double) -> String {
        switch phase {
        case .idle: return idle
        case .completed: return completed
        case .paused: return paused ?? stageName(progress)
        case .running: return stageName(progress)
        }
    }

    private func stageName(_ progress: Double) -> String {
        stages.last(where: { progress >= $0.from })?.animation ?? idle
    }
}

struct Skin: Identifiable {
    let manifest: SkinManifest
    let directory: URL
    let isBuiltIn: Bool
    var id: String { isBuiltIn ? "builtin:\(manifest.id)" : "import:\(directory.lastPathComponent)" }
}
