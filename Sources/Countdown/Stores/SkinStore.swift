import Foundation
import Observation

@MainActor @Observable
final class SkinStore {
    private(set) var skins: [Skin] = []
    private(set) var warning: String?
    let library: URL

    init(directory: URL) throws {
        library = directory.appendingPathComponent("Skins", isDirectory: true)
        try FileManager.default.createDirectory(at: library, withIntermediateDirectories: true)
        let resources = AppResources.bundle
        guard let starter = resources.url(forResource: "StarterSkin", withExtension: nil) else {
            throw SkinError(message: L10n.text("内置皮肤资源缺失。"))
        }
        skins = [try SkinValidator.load(directory: starter, builtIn: true)]
        reload()
    }

    func reload() {
        skins = skins.filter(\.isBuiltIn)
        warning = nil
        let directories: [URL]
        do {
            directories = try FileManager.default.contentsOfDirectory(
                at: library, includingPropertiesForKeys: [.creationDateKey])
        } catch {
            warning = L10n.format("部分皮肤无法加载：%@", error.localizedDescription)
            return
        }
        for directory in directories.sorted(by: {
            let left = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let right = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return left == right ? $0.lastPathComponent < $1.lastPathComponent : left < right
        }) where !directory.lastPathComponent.hasPrefix(".") {
            do {
                let skin = try SkinValidator.load(directory: directory)
                skins.append(skin)
            } catch { warning = L10n.format("部分皮肤无法加载：%@", error.localizedDescription) }
        }
    }

    func selectedSkin(id: String) -> Skin { skins.first(where: { $0.id == id }) ?? skins[0] }

    func install(staged: URL) throws -> String {
        let skin = try SkinValidator.load(directory: staged)
        let destination = library.appendingPathComponent(UUID().uuidString.lowercased(), isDirectory: true)
        try FileManager.default.moveItem(at: staged, to: destination)
        let installed = Skin(manifest: skin.manifest, directory: destination, isBuiltIn: false)
        skins.append(installed)
        return installed.id
    }

    func delete(_ skin: Skin) throws {
        guard !skin.isBuiltIn else { return }
        try FileManager.default.removeItem(at: skin.directory)
        skins.removeAll { $0.id == skin.id }
    }
}
