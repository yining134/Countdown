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
