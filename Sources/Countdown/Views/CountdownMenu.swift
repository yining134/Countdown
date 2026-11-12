import SwiftUI

struct CountdownMenu: View {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("打开 Countdown") { NSApp.activate(ignoringOtherApps: true); openWindow(id: "main") }
        Button(model.widgetVisible ? "隐藏组件" : "显示组件") { model.toggleWidget() }
        Button("重置组件位置") { model.showWidget(); model.panelController?.resetPosition() }
        Divider()
        if model.countdown.phase == .idle || model.countdown.phase == .completed {
            Button("开始倒计时") { model.primaryAction() }
        } else {
            Button(model.countdown.phase == .paused ? "继续" : "暂停") { model.countdown.togglePause() }
        }
        Button("重置倒计时") { model.reset() }
        Divider()
        Button("退出 Countdown") { NSApp.terminate(nil) }.keyboardShortcut("q")
    }
}

