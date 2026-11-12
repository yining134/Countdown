import SwiftUI

struct GeneralSettingsView: View {
    let model: AppModel
    @State private var minutes = ""
    @FocusState private var editingMinutes: Bool

    var body: some View {
        @Bindable var preferences = model.preferences
        Form {
            Section {
                LabeledContent {
                    HStack(spacing: 6) {
                        TextField("", text: $minutes)
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 56)
                            .focused($editingMinutes)
                            .onSubmit { commitMinutes() }
                            .accessibilityLabel("倒计时分钟数")
                        Text("分钟").foregroundStyle(.secondary).fixedSize()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text("倒计时时长")
                        Image(systemName: "questionmark.circle")
                            .imageScale(.small).foregroundStyle(.secondary)
                            .help("修改时长在下次开始时生效")
                            .accessibilityLabel("修改时长在下次开始时生效")
                    }
                }
                LabeledContent("组件大小") {
                    Slider(value: $preferences.widgetSize, in: 64...256, step: 16)
                        .frame(width: 180).accessibilityLabel("组件大小")
                }
                Toggle("显示剩余时间", isOn: $preferences.showRemainingTime)
                Toggle("显示菜单栏图标", isOn: $preferences.showMenuBarIcon)
            }
        }
        .formStyle(.grouped)
        .onAppear { minutes = String(preferences.minutes) }
        .onChange(of: editingMinutes) { if !editingMinutes { commitMinutes() } }
        .onDisappear { commitMinutes() }
        .onChange(of: preferences.showMenuBarIcon) { model.menuBarVisibilityChanged() }
    }

    private func commitMinutes() {
        if let value = Int(minutes.trimmingCharacters(in: .whitespacesAndNewlines)), (1...1440).contains(value) {
            model.preferences.minutes = value
        }
        minutes = String(model.preferences.minutes)
    }
}
