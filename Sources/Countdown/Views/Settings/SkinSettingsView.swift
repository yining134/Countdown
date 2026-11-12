import SwiftUI

struct SkinSettingsView: View {
    let model: AppModel

    var body: some View {
        VStack(spacing: 8) {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                    ForEach(model.skins.skins) { skin in
                        Button {
                            model.select(skin)
                        } label: {
                            SkinThumbnailView(skin: skin, isSelected: model.selectedSkin.id == skin.id)
                        }
                        .buttonStyle(.plain)
                        .help(skin.manifest.name)
                        .accessibilityLabel(skin.manifest.name)
                        .accessibilityAddTraits(model.selectedSkin.id == skin.id ? [.isSelected] : [])
                        .contextMenu {
                            if !skin.isBuiltIn {
                                Button(L10n.text("删除主题"), role: .destructive) { model.delete(skin) }
                            }
                        }
                    }
                    Button {
                        model.presentSkinImportPanel()
                    } label: {
                        Image(systemName: "plus").font(.title2).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity).frame(height: 96)
                            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                            .contentShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(model.isImporting)
                    .accessibilityLabel(L10n.text("导入主题"))
                    .help(L10n.text("导入主题"))
                }.padding(12)
            }
            if model.isImporting {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text(L10n.text("正在导入…")).font(.caption)
                    Button(L10n.text("取消")) { model.cancelImport() }
                }.padding(.bottom, 8)
            }
            if let warning = model.skins.warning {
                Text(warning).font(.caption).foregroundStyle(.secondary).padding(.horizontal)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first, url.isFileURL, url.pathExtension.lowercased() == "zip", !model.isImporting
            else { return false }
            model.importSkin(url)
            return true
        }
    }
}
