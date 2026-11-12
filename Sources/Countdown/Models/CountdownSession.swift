import Foundation

enum CountdownPhase: String, Codable {
    case idle, running, paused, completed
}

struct CountdownSession: Codable {
    var phase: CountdownPhase = .idle
    var duration: TimeInterval = 25 * 60
    var deadline: Date?
    var pausedRemaining: TimeInterval = 25 * 60

    func remaining(at now: Date) -> TimeInterval {
        switch phase {
        case .idle: return duration
        case .completed: return 0
        case .paused: return pausedRemaining
        case .running: return max(0, deadline?.timeIntervalSince(now) ?? 0)
        }
    }
}
