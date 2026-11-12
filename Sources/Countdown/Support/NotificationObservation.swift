import Foundation

final class NotificationObservation {
    private let center: NotificationCenter
    private let token: NSObjectProtocol

    init(
        center: NotificationCenter, name: Notification.Name,
        handler: @escaping @Sendable (Notification) -> Void
    ) {
        self.center = center
        token = center.addObserver(forName: name, object: nil, queue: .main, using: handler)
    }

    deinit {
        center.removeObserver(token)
    }
}
