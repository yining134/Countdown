import Foundation

struct SkinImporter {
    static func prepare(url: URL, stagingParent: URL) async throws -> URL {
        guard url.isFileURL else { throw SkinError(message: L10n.text("仅支持导入本地 ZIP 文件。")) }
        let task = Task.detached(priority: .userInitiated) { () throws -> URL in
            let fm = FileManager.default
            let workspace = stagingParent.appendingPathComponent(".import-" + UUID().uuidString, isDirectory: true)
            try fm.createDirectory(at: workspace, withIntermediateDirectories: true)
            do {
                let archive = workspace.appendingPathComponent("skin.zip")
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                try ZIPPreflight.validate(url)
                try fm.copyItem(at: url, to: archive)
                try Task.checkCancellation()
                try ZIPPreflight.validate(archive)
                let expanded = workspace.appendingPathComponent("expanded", isDirectory: true)
                try fm.createDirectory(at: expanded, withIntermediateDirectories: true)
                try extract(archive, to: expanded)
                try Task.checkCancellation()
                _ = try SkinValidator.load(directory: expanded)
                try fm.removeItem(at: archive)
                return expanded
            } catch {
                try? fm.removeItem(at: workspace)
                throw error
            }
        }
        return try await withTaskCancellationHandler(operation: { try await task.value }, onCancel: { task.cancel() })
    }

    private static func extract(_ archive: URL, to destination: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", "--noqtn", "--norsrc", archive.path, destination.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        defer {
            if process.isRunning { process.terminate(); process.waitUntilExit() }
        }
        let started = Date()
        while process.isRunning {
            let size = try expandedSize(destination)
            if Task.isCancelled || Date().timeIntervalSince(started) > 20 || size > ZIPPreflight.maxExpanded {
                process.terminate()
                process.waitUntilExit()
                throw SkinError(message: L10n.text("解压已取消、超时或超出大小限制。"))
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw SkinError(message: L10n.text("ZIP 解压失败。")) }
        guard try expandedSize(destination) <= ZIPPreflight.maxExpanded else { throw SkinError(message: L10n.text("解压内容超过大小限制。")) }
    }

    private static func expandedSize(_ directory: URL) throws -> Int {
        let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey]
        guard let entries = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: keys) else { return 0 }
        var total = 0, count = 0
        for case let file as URL in entries {
            count += 1
            let value = try file.resourceValues(forKeys: Set(keys))
            guard count <= 200, value.isSymbolicLink != true,
                  value.isRegularFile == true || value.isDirectory == true else {
                throw SkinError(message: L10n.text("解压内容包含链接、特殊文件或过多条目。"))
            }
            total += value.fileSize ?? 0
        }
        return total
    }
}
