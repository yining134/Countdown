import SwiftUI

struct MainScene: View {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        MainWindow(model: model).onAppear {
            model.openMainWindow = {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "main")
            }
        }
    }
}
