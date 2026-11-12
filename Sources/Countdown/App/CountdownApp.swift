import SwiftUI

@main
struct CountdownApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var model: AppModel?
    @State private var startupError: String?

    var body: some Scene {
        Window(L10n.text("设置"), id: "main") {
            Group {
                if let model {
                    SettingsSceneRoot(model: model)
                } else if let startupError {
                    Text(startupError).padding(30)
                } else {
                    ProgressView().padding(50)
                }
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
        .commands { AppCommands(model: model) }
        MenuBarExtra(
            "Countdown", systemImage: "leaf",
            isInserted: Binding(
                get: { model?.preferences.showMenuBarIcon ?? true },
                set: { model?.preferences.showMenuBarIcon = $0 }
            )
        ) {
            if let model { CountdownMenuView(model: model) } else { Text(L10n.text("Countdown 正在启动")) }
        }
    }
}
