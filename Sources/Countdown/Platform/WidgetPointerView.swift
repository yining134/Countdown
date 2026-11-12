import AppKit
import SwiftUI

struct WidgetPointerSurface: NSViewRepresentable {
    var onClick: () -> Void
    var onSettings: () -> Void
    var label: String
    func makeNSView(context: Context) -> WidgetPointerView {
        let view = WidgetPointerView()
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.button)
        return view
    }
    func updateNSView(_ view: WidgetPointerView, context: Context) {
        view.onClick = onClick
        view.onSettings = onSettings
        view.setAccessibilityLabel(label)
    }
}

final class WidgetPointerView: NSView {
    var onClick: (() -> Void)?
    var onSettings: (() -> Void)?

    override func accessibilityPerformPress() -> Bool { onClick?(); return true }

    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu()
        let settings = NSMenuItem(title: "设置…", action: #selector(openSettings), keyEquivalent: "")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "退出 Countdown", action: #selector(quitApp), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)
        return menu
    }

    @objc private func openSettings() { onSettings?() }
    @objc private func quitApp() { NSApp.terminate(nil) }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        guard event.clickCount == 1, let window else { return }
        let action = onClick
        let start = event.locationInWindow
        while let next = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) {
            if next.type == .leftMouseUp { action?(); return }
            let delta = next.locationInWindow
            if hypot(delta.x - start.x, delta.y - start.y) > 4 {
                window.performDrag(with: next)
                return
            }
        }
    }
}
