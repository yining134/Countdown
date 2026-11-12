import SwiftUI

struct ThemeSettingsView: View {
    let model: AppModel

    var body: some View {
        VStack(spacing: 8) {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                    ForEach(model.skins.skins) { skin in
                        Button { model.select(skin) } label: {
                            ThemeThumbnail(skin: skin, selected: model.selectedSkin.id == skin.id)
                        }
                        .buttonStyle(.plain)
                        .help(skin.manifest.name)
                        .accessibilityLabel(skin.manifest.name)
                        .accessibilityAddTraits(model.selectedSkin.id == skin.id ? [.isSelected] : [])
                        .contextMenu {
                            if !skin.isBuiltIn {
                                Button("删除主题", role: .destructive) { model.delete(skin) }
                            }
                        }
                    }
                    Button { model.chooseZIP() } label: {
                        Image(systemName: "plus").font(.title2).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity).frame(height: 96)
                            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                            .contentShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(model.importing)
                    .accessibilityLabel("导入主题")
                    .help("导入主题")
                }.padding(12)
            }
            if model.importing {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("正在导入…").font(.caption)
                    Button("取消") { model.cancelImport() }
                }.padding(.bottom, 8)
            }
            if let warning = model.skins.warning {
                Text(warning).font(.caption).foregroundStyle(.secondary).padding(.horizontal)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first, url.isFileURL, url.pathExtension.lowercased() == "zip", !model.importing else { return false }
            model.importSkin(url)
            return true
        }
    }
}
