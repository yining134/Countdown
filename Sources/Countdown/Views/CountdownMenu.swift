import SwiftUI

struct CountdownMenu: View {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(L10n.text("设置…")) { NSApp.activate(ignoringOtherApps: true); openWindow(id: "main") }
            .keyboardShortcut(",")
        Button(model.widgetVisible ? L10n.text("隐藏组件") : L10n.text("显示组件")) { model.toggleWidget() }
        Divider()
        Button(L10n.text("退出 Countdown")) { NSApp.terminate(nil) }.keyboardShortcut("q")
    }
}
