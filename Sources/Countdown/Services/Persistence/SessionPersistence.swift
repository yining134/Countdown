import Foundation
import OSLog

struct SessionPersistence {
    private static let logger = Logger(subsystem: "local.countdown.app", category: "SessionPersistence")
    private let sessionFileURL: URL

    init(directory: URL) {
        sessionFileURL = directory.appendingPathComponent("Session.json")
    }

    func load() -> CountdownSession? {
        guard FileManager.default.fileExists(atPath: sessionFileURL.path) else { return nil }
        do {
            return try JSONDecoder().decode(CountdownSession.self, from: Data(contentsOf: sessionFileURL))
        } catch {
            Self.logger.error("Unable to restore countdown session: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func save(_ session: CountdownSession) {
        do {
            let data = try JSONEncoder().encode(session)
            try data.write(to: sessionFileURL, options: .atomic)
        } catch {
            Self.logger.error("Unable to save countdown session: \(error.localizedDescription, privacy: .public)")
        }
    }
}
