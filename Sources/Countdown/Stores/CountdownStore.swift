import Foundation
import Observation

@MainActor @Observable
final class CountdownStore {
    private(set) var session = CountdownSession()
    private(set) var now = Date()
    var onCompletion: (() -> Void)?
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private let persistence: SessionPersistence

    var phase: CountdownPhase { session.phase }
    var remaining: TimeInterval { session.remaining(at: now) }
    var progress: Double { min(1, max(0, 1 - remaining / session.duration)) }

    init(directory: URL) {
        persistence = SessionPersistence(directory: directory)
        if let restored = persistence.load(),
            restored.duration.isFinite, (1...86400).contains(restored.duration),
            restored.pausedRemaining.isFinite,
            (0...restored.duration).contains(restored.pausedRemaining),
            restored.phase != .running || restored.deadline != nil
        {
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
        now = Date()
        session = CountdownSession(
            phase: .running, duration: duration,
            deadline: now.addingTimeInterval(duration), pausedRemaining: duration)
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
            now = Date()
            session.deadline = now.addingTimeInterval(session.pausedRemaining)
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
        persistence.save(session)
    }
}
