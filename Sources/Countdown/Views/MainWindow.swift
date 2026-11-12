import SwiftUI

struct MainWindow: View {
    @Bindable var model: AppModel
    @State private var importURL = ""
    @State private var showDelete = false

    var body: some View {
        @Bindable var preferences = model.preferences
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("皮肤").font(.headline).padding(.horizontal, 12)
                List(model.skins.skins, selection: Binding(get: { model.selectedSkin.id }, set: { id in
                    if let skin = model.skins.skins.first(where: { $0.id == id }) { model.select(skin) }
                })) { skin in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(skin.manifest.name)
                        Text(skin.isBuiltIn ? "内置皮肤" : skin.manifest.author ?? "导入的皮肤")
                            .font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 4).tag(skin.id)
                }.listStyle(.sidebar)
                Button("导入 ZIP…", systemImage: "plus") { model.chooseZIP() }
                    .disabled(model.importing).padding(.horizontal, 12)
            }
            .padding(.vertical, 20).frame(width: 190)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Countdown").font(.largeTitle.bold())
                            Text("让时间慢慢生长").foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("找回组件") { model.showWidget(); model.panelController?.resetPosition() }
                    }
                    HStack(spacing: 24) {
                        SpriteView(skin: model.selectedSkin,
                                   animationName: model.selectedSkin.manifest.animationName(phase: model.countdown.phase, progress: model.countdown.progress),
                                   playing: model.countdown.phase != .paused)
                            .frame(width: 150, height: 150)
                            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
                        VStack(alignment: .leading, spacing: 12) {
                            Text(model.selectedSkin.manifest.name).font(.title2.bold())
                            Text(status).foregroundStyle(.secondary)
                            HStack {
                                if model.countdown.phase == .idle || model.countdown.phase == .completed {
                                    Button("开始倒计时") { model.primaryAction() }.buttonStyle(.borderedProminent)
                                } else {
                                    Button(model.countdown.phase == .paused ? "继续" : "暂停") { model.countdown.togglePause() }
                                    Button("重置") { model.reset() }
                                }
                            }
                            if !model.selectedSkin.isBuiltIn {
                                Button("删除皮肤", role: .destructive) { showDelete = true }.font(.caption)
                            }
                        }
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 14) {
                        Text("倒计时").font(.headline)
                        HStack {
                            Text("时长")
                            TextField("分钟", value: $preferences.minutes, format: .number)
                                .frame(width: 64)
                                .onChange(of: model.preferences.minutes) {
                                    model.preferences.minutes = min(1440, max(1, model.preferences.minutes))
                                }
                            Text("分钟").foregroundStyle(.secondary)
                            Stepper("时长", value: $preferences.minutes, in: 1...1440).labelsHidden()
                        }
                        Text("修改时长在下一轮或重置后生效。关闭窗口后，组件和菜单栏继续运行。")
                            .font(.caption).foregroundStyle(.secondary)
                        HStack {
                            Text("组件大小")
                            Slider(value: $preferences.widgetSize, in: 64...256, step: 16)
                            Text("\(Int(model.preferences.widgetSize)) pt").monospacedDigit().frame(width: 52)
                        }
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 10) {
                        Text("从链接导入皮肤").font(.headline)
                        HStack {
                            TextField("HTTPS ZIP 直链", text: $importURL)
                            Button("导入") {
                                guard let url = URL(string: importURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                                    model.errorMessage = "请输入有效的 HTTPS ZIP 直链。"; return
                                }
                                model.importSkin(url)
                            }.disabled(model.importing || importURL.isEmpty)
                        }
                        Text("也可以把 ZIP 拖到此窗口。皮肤使用 PNG 精灵图 + JSON，完成音效可选。")
                            .font(.caption).foregroundStyle(.secondary)
                        if model.importing {
                            HStack { ProgressView().controlSize(.small); Text("正在导入…"); Button("取消") { model.cancelImport() } }
                        }
                        if let warning = model.skins.warning { Text(warning).font(.caption).foregroundStyle(.orange) }
                    }
                }.padding(28)
            }
        }
        .frame(minWidth: 750, idealWidth: 810, minHeight: 610)
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first, url.isFileURL, url.pathExtension.lowercased() == "zip" else { return false }
            model.importSkin(url)
            return true
        }
        .alert("无法完成操作", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("好", role: .cancel) { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
        .confirmationDialog("删除“\(model.selectedSkin.manifest.name)”？", isPresented: $showDelete) {
            Button("删除", role: .destructive) { model.deleteSelected() }
        } message: { Text("可以通过原 ZIP 再次导入。") }
    }

    private var status: String {
        switch model.countdown.phase {
        case .idle: return "准备开始"
        case .running: return "正在成长 · \(Int(model.countdown.progress * 100))%"
        case .paused: return "已暂停"
        case .completed: return "本轮已完成"
        }
    }
}
