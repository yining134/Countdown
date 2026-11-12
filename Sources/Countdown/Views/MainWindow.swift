import SwiftUI

struct MainWindow: View {
    let model: AppModel

    var body: some View {
        TabView {
            GeneralSettingsView(model: model)
                .tabItem { Label(L10n.text("通用"), systemImage: "gearshape") }
            ThemeSettingsView(model: model)
                .tabItem { Label(L10n.text("主题"), systemImage: "paintpalette") }
        }
        .padding(16)
        .frame(width: 480, height: 340)
        .alert(L10n.text("无法完成操作"), isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button(L10n.text("好"), role: .cancel) { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }
}
