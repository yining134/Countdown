import SwiftUI

@main
struct CountdownApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var model: AppModel?
    @State private var startupError: String?

    var body: some Scene {
        Window("设置", id: "main") {
            Group {
                if let model { MainScene(model: model) }
                else if let startupError { Text(startupError).padding(30) }
                else { ProgressView().padding(50) }
            }
            .task {
                guard model == nil, startupError == nil else { return }
                do {
                    let created = try AppModel()
                    model = created
                    created.showWidget()
                } catch { startupError = error.localizedDescription }
            }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .appSettings) {
                Button("设置…") { model?.openMainWindow?() }.keyboardShortcut(",")
            }
            CommandGroup(after: .importExport) {
                Button("导入皮肤 ZIP…") { model?.chooseZIP() }.keyboardShortcut("o")
            }
        }
        MenuBarExtra("Countdown", systemImage: "leaf", isInserted: Binding(
            get: { model?.preferences.showMenuBarIcon ?? true },
            set: { model?.preferences.showMenuBarIcon = $0 }
        )) {
            if let model { CountdownMenu(model: model) }
            else { Text("Countdown 正在启动") }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

