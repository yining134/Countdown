import Foundation

final class DownloadGuard: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        if totalBytesWritten > ZIPPreflight.maxArchive || totalBytesExpectedToWrite > ZIPPreflight.maxArchive {
            downloadTask.cancel()
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        let url = request.url
        completionHandler(url?.scheme?.lowercased() == "https" && url?.user == nil && url?.password == nil ? request : nil)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {}
}

struct SkinImporter {
    static func prepare(url: URL, stagingParent: URL) async throws -> URL {
        let task = Task.detached(priority: .userInitiated) { () throws -> URL in
            let fm = FileManager.default
            let workspace = stagingParent.appendingPathComponent(".import-" + UUID().uuidString, isDirectory: true)
            try fm.createDirectory(at: workspace, withIntermediateDirectories: true)
            do {
                let archive = workspace.appendingPathComponent("skin.zip")
                if url.isFileURL {
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    try ZIPPreflight.validate(url)
                    try fm.copyItem(at: url, to: archive)
                } else {
                    guard url.scheme?.lowercased() == "https", url.host != nil,
                          url.user == nil, url.password == nil else {
                        throw SkinError(message: "请输入不带凭据的 HTTPS ZIP 直链。")
                    }
                    let configuration = URLSessionConfiguration.ephemeral
                    configuration.timeoutIntervalForRequest = 30
                    configuration.timeoutIntervalForResource = 120
                    let session = URLSession(configuration: configuration)
                    defer { session.invalidateAndCancel() }
                    let (location, response) = try await session.download(from: url, delegate: DownloadGuard())
                    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
                          http.url?.scheme?.lowercased() == "https" else {
                        throw SkinError(message: "皮肤下载失败，请检查 ZIP 直链。")
                    }
                    try fm.moveItem(at: location, to: archive)
                }
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
                throw SkinError(message: "解压已取消、超时或超出大小限制。")
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw SkinError(message: "ZIP 解压失败。") }
        guard try expandedSize(destination) <= ZIPPreflight.maxExpanded else { throw SkinError(message: "解压内容超过大小限制。") }
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
                throw SkinError(message: "解压内容包含链接、特殊文件或过多条目。")
            }
            total += value.fileSize ?? 0
        }
        return total
    }
}
