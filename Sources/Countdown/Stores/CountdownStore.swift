import Foundation
import Observation

@MainActor @Observable
final class CountdownStore {
    private(set) var session = CountdownSession()
    private(set) var now = Date()
    var onCompletion: (() -> Void)?
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private let file: URL

    var phase: CountdownPhase { session.phase }
    var remaining: TimeInterval { session.remaining(at: now) }
    var progress: Double { min(1, max(0, 1 - remaining / session.duration)) }

    init(directory: URL) {
        file = directory.appendingPathComponent("Session.json")
        if let data = try? Data(contentsOf: file),
           let restored = try? JSONDecoder().decode(CountdownSession.self, from: data),
           restored.duration.isFinite, (1...86400).contains(restored.duration),
           restored.pausedRemaining.isFinite,
           (0...restored.duration).contains(restored.pausedRemaining),
           restored.phase != .running || restored.deadline != nil {
            session = restored
        }
        refresh(notify: false)
        updateTicker()
    }

    func refresh(notify: Bool = true) {
        guard phase == .running else { return }
        now = Date()
        if remaining <= 0 {
            session.phase = .completed
            session.deadline = nil
            updateTicker()
            persist()
            if notify { onCompletion?() }
        }
    }

    func start(duration: TimeInterval) {
        session = CountdownSession(phase: .running, duration: duration,
                                   deadline: Date().addingTimeInterval(duration), pausedRemaining: duration)
        now = Date()
        updateTicker()
        persist()
    }

    func togglePause() {
        refresh()
        if phase == .running {
            session.pausedRemaining = remaining
            session.phase = .paused
            session.deadline = nil
        } else if phase == .paused {
            session.deadline = Date().addingTimeInterval(session.pausedRemaining)
            session.phase = .running
        }
        updateTicker()
        persist()
    }

    func reset(duration: TimeInterval) {
        session = CountdownSession(duration: duration, pausedRemaining: duration)
        now = Date()
        updateTicker()
        persist()
    }

    private func updateTicker() {
        ticker?.invalidate()
        ticker = nil
        guard phase == .running else { return }
        ticker = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(session) { try? data.write(to: file, options: .atomic) }
    }
}
