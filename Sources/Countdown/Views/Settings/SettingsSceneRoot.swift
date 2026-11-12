import SwiftUI

struct SettingsSceneRoot: View {
    @Environment(\.openWindow) private var openWindow

    let model: AppModel
    var body: some View {
        SettingsView(model: model).onAppear {
            model.openSettingsWindow = {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "main")
            }
        }
    }
}
