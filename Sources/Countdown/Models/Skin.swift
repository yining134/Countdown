import Foundation

struct Skin: Identifiable {
    let manifest: SkinManifest
    let directory: URL
    let isBuiltIn: Bool
    /// 已安装皮肤实例的标识。
    var id: String { isBuiltIn ? "builtin:\(manifest.id)" : "import:\(directory.lastPathComponent)" }
}
