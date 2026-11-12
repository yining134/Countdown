import AppKit
import UniformTypeIdentifiers

@MainActor
enum SkinImportPanel {
    static func present(onSelection: @escaping @MainActor (URL) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.zip]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            onSelection(url)
        }
    }
}
