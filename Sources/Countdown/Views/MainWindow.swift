import SwiftUI

struct MainWindow: View {
    let model: AppModel

    var body: some View {
        TabView {
            GeneralSettingsView(model: model)
                .tabItem { Label("通用", systemImage: "gearshape") }
            ThemeSettingsView(model: model)
                .tabItem { Label("主题", systemImage: "paintpalette") }
        }
        .padding(16)
        .frame(width: 480, height: 340)
        .alert("无法完成操作", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("好", role: .cancel) { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }
}
