import SwiftUI

struct AppCommands: Commands {
    let model: AppModel?

    var body: some Commands {
        CommandGroup(replacing: .newItem) {}
        CommandGroup(replacing: .appSettings) {
            Button(L10n.text("设置…")) { model?.openSettingsWindow?() }
                .keyboardShortcut(",")
        }
        CommandGroup(after: .importExport) {
            Button(L10n.text("导入皮肤 ZIP…")) { model?.presentSkinImportPanel() }
                .keyboardShortcut("o")
        }
    }
}
