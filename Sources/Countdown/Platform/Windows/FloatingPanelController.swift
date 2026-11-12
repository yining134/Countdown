import AppKit
import SwiftUI

@MainActor
final class FloatingPanelController: NSObject, NSWindowDelegate {
    private let panel: NSPanel
    private weak var model: AppModel?
    private var observers: [NotificationObservation] = []

    init(model: AppModel) {
        self.model = model
        panel = NSPanel(
            contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        super.init()
        panel.title = "Countdown Widget"
        panel.delegate = self
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isMovableByWindowBackground = false
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: FloatingWidgetView(model: model))
        resizeAndRestore()
        observers.append(
            NotificationObservation(center: .default, name: NSApplication.didChangeScreenParametersNotification) {
                [weak self] _ in
                Task { @MainActor in self?.clampToScreen() }
            })
        observers.append(
            NotificationObservation(
                center: NSWorkspace.shared.notificationCenter, name: NSWorkspace.didWakeNotification
            ) { [weak model] _ in
                Task { @MainActor in model?.countdown.refresh() }
            })
    }

    func show() {
        resize()
        panel.orderFrontRegardless()
    }
    func hide() { panel.orderOut(nil) }

    func resize() {
        guard let model else { return }
        let old = panel.frame
        panel.setFrame(
            NSRect(
                x: old.minX, y: old.minY, width: model.preferences.widgetSize,
                height: model.preferences.widgetSize + 32 + (model.preferences.showRemainingTime ? 24 : 0)),
            display: true)
        clampToScreen()
    }

    private func placeInitially() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let visible = screen.visibleFrame
        panel.setFrameOrigin(NSPoint(x: visible.maxX - panel.frame.width - 40, y: visible.minY + 60))
        savePosition()
        show()
    }

    func windowDidMove(_ notification: Notification) { savePosition() }

    private func resizeAndRestore() {
        resize()
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "widgetX") != nil {
            panel.setFrameOrigin(NSPoint(x: defaults.double(forKey: "widgetX"), y: defaults.double(forKey: "widgetY")))
            clampToScreen()
        } else {
            placeInitially()
        }
    }

    private func savePosition() {
        UserDefaults.standard.set(panel.frame.minX, forKey: "widgetX")
        UserDefaults.standard.set(panel.frame.minY, forKey: "widgetY")
    }

    private func clampToScreen() {
        let frame = panel.frame
        let screen =
            NSScreen.screens.max { a, b in
                a.visibleFrame.intersection(frame).area < b.visibleFrame.intersection(frame).area
            } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }
        panel.setFrameOrigin(
            NSPoint(
                x: min(max(frame.minX, visible.minX), visible.maxX - frame.width),
                y: min(max(frame.minY, visible.minY), visible.maxY - frame.height)))
    }
}

private extension CGRect {
    var area: CGFloat { isNull ? 0 : max(0, width) * max(0, height) }
}
