import OSLog
import UserNotifications

@MainActor
final class CompletionNotificationService: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: "local.countdown.app", category: "Notifications")

    override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() {
        Task {
            do {
                _ = try await center.requestAuthorization(options: [.alert])
            } catch {
                logger.error("Notification authorization failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func notifyCompletion() {
        Task {
            do {
                guard try await center.requestAuthorization(options: [.alert]) else { return }
                let content = UNMutableNotificationContent()
                content.title = L10n.text("倒计时结束")
                content.body = L10n.text("本次计时已完成，休息一下吧。")
                let request = UNNotificationRequest(
                    identifier: UUID().uuidString, content: content, trigger: nil)
                try await center.add(request)
            } catch {
                logger.error("Completion notification failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }
}
