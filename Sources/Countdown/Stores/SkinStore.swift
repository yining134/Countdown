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
        let packagedBundle = Bundle.main.resourceURL?.appendingPathComponent("Countdown_Countdown.bundle")
        let resources = packagedBundle.flatMap(Bundle.init(url:)) ?? Bundle.module
        guard let starter = resources.url(forResource: "StarterSkin", withExtension: nil) else {
            throw SkinError(message: "内置皮肤资源缺失。")
        }
        skins = [try SkinValidator.load(directory: starter, builtIn: true)]
        reload()
    }

    func reload() {
        skins = skins.filter(\.isBuiltIn)
        warning = nil
        let directories = (try? FileManager.default.contentsOfDirectory(at: library, includingPropertiesForKeys: nil)) ?? []
        for directory in directories where !directory.lastPathComponent.hasPrefix(".") {
            do {
                let skin = try SkinValidator.load(directory: directory)
                guard !skins.contains(where: { $0.id == skin.id }) else { continue }
                skins.append(skin)
            } catch { warning = "部分皮肤无法加载：\(error.localizedDescription)" }
        }
    }

    func selected(id: String) -> Skin { skins.first(where: { $0.id == id }) ?? skins[0] }

    func install(staged: URL) throws -> String {
        let skin = try SkinValidator.load(directory: staged)
        guard !skins.contains(where: { $0.id == skin.id }) else {
            throw SkinError(message: "已存在相同 ID 的皮肤，请先删除旧皮肤再导入。")
        }
        let destination = library.appendingPathComponent(skin.id, isDirectory: true)
        try FileManager.default.moveItem(at: staged, to: destination)
        skins.append(Skin(manifest: skin.manifest, directory: destination, isBuiltIn: false))
        return skin.id
    }

    func delete(_ skin: Skin) throws {
        guard !skin.isBuiltIn else { return }
        try FileManager.default.removeItem(at: skin.directory)
        skins.removeAll { $0.id == skin.id }
    }
}
