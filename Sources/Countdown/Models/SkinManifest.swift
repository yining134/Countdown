import Foundation

struct SkinManifest: Codable {
    enum CodingKeys: String, CodingKey {
        case schemaVersion, id, name, author, frameSize, animations, idle, stages, paused, completed, completionSound
        case spriteSheetPath = "spritesheet"
    }
    struct FrameSize: Codable {
        let width: Int
        let height: Int
    }
    struct Animation: Codable {
        enum CodingKeys: String, CodingKey {
            case startFrame, frameCount
            case framesPerSecond = "fps"
        }
        let startFrame: Int
        let frameCount: Int
        let framesPerSecond: Double
    }
    /// 已完成比例从 0 开始，严格递增且小于 1。
    struct Stage: Codable {
        let progressThreshold: Double
        let animation: String
        enum CodingKeys: String, CodingKey {
            case progressThreshold = "from"
            case animation
        }
    }
    let schemaVersion: Int
    let id: String
    let name: String
    let author: String?
    let spriteSheetPath: String
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
        stages.last(where: { progress >= $0.progressThreshold })?.animation ?? idle
    }
}
