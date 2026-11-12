import SwiftUI

struct SettingsView: View {
    let model: AppModel

    var body: some View {
        TabView {
            GeneralSettingsView(
                preferences: model.preferences, onMenuBarVisibilityChange: model.menuBarVisibilityChanged
            )
            .tabItem { Label(L10n.text("通用"), systemImage: "gearshape") }
            SkinSettingsView(model: model)
                .tabItem { Label(L10n.text("主题"), systemImage: "paintpalette") }
        }
        .padding(16)
        .frame(width: 480, height: 340)
        .alert(
            L10n.text("无法完成操作"),
            isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })
        ) {
            Button(L10n.text("好"), role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}
