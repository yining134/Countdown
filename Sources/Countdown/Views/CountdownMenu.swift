import SwiftUI

struct CountdownMenu: View {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("设置…") { NSApp.activate(ignoringOtherApps: true); openWindow(id: "main") }
            .keyboardShortcut(",")
        Button(model.widgetVisible ? "隐藏组件" : "显示组件") { model.toggleWidget() }
        Divider()
        Button("退出 Countdown") { NSApp.terminate(nil) }.keyboardShortcut("q")
    }
}
