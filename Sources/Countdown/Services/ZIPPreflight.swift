import Foundation

struct ZIPPreflight {
    static let maxArchive = 25 * 1024 * 1024
    static let maxExpanded = 100 * 1024 * 1024

    static func validate(_ url: URL) throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let size = attributes[.size] as? Int, size <= maxArchive else {
            throw SkinError(message: "ZIP 不得超过 25 MiB。")
        }
        let data = try Data(contentsOf: url)
        func u16(_ offset: Int) -> Int {
            Int(data[offset]) | (Int(data[offset + 1]) << 8)
        }
        func u32(_ offset: Int) -> Int {
            u16(offset) | (u16(offset + 2) << 16)
        }
        guard data.count >= 22 else { throw SkinError(message: "ZIP 文件不完整。") }
        let lower = max(0, data.count - 65557)
        guard let end = stride(from: data.count - 22, through: lower, by: -1).first(where: {
            u32($0) == 0x06054b50 && $0 + 22 + u16($0 + 20) == data.count
        }) else { throw SkinError(message: "无法读取 ZIP 目录。") }
        let count = u16(end + 10), centralSize = u32(end + 12), centralOffset = u32(end + 16)
        guard u16(end + 4) == 0, u16(end + 6) == 0, u16(end + 8) == count,
              (1...200).contains(count), centralOffset + centralSize == end else {
            throw SkinError(message: "不支持分卷、ZIP64 或超过 200 个条目的 ZIP。")
        }
        var offset = centralOffset, expanded = 0, names = Set<String>(), occupied: [Range<Int>] = []
        for _ in 0..<count {
            guard offset >= 0, offset + 46 <= end, u32(offset) == 0x02014b50 else {
                throw SkinError(message: "ZIP 目录已损坏。")
            }
            let flags = u16(offset + 8), method = u16(offset + 10)
            let compressed = u32(offset + 20), uncompressed = u32(offset + 24)
            let length = u16(offset + 28), extra = u16(offset + 30), comment = u16(offset + 32)
            let local = u32(offset + 42), mode = (u32(offset + 38) >> 16) & 0xf000
            guard offset + 46 + length + extra + comment <= end,
                  let path = String(data: data.subdata(in: offset + 46..<offset + 46 + length), encoding: .utf8),
                  !path.isEmpty, !path.hasPrefix("/"), !path.contains("\\"),
                  !path.contains(":"), !path.contains("\0"),
                  !path.hasPrefix("__MACOSX/"),
                  path.split(separator: "/").allSatisfy({ $0 != ".." && $0 != "." }),
                  names.insert(path.precomposedStringWithCanonicalMapping.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))).inserted,
                  flags & 1 == 0, [0, 8].contains(method),
                  mode == 0 || mode == 0x8000 || mode == 0x4000,
                  u16(offset + 34) == 0,
                  uncompressed <= maxExpanded, compressed <= maxArchive,
                  local >= 0, local + 30 <= centralOffset, u32(local) == 0x04034b50,
                  u16(local + 6) == flags, u16(local + 8) == method else {
                throw SkinError(message: "ZIP 包含非法路径、重复条目、链接、加密或不支持的压缩格式。")
            }
            let localName = u16(local + 26), localExtra = u16(local + 28)
            let contentStart = local + 30 + localName + localExtra
            guard localName == length, contentStart <= centralOffset,
                  data.subdata(in: local + 30..<local + 30 + localName) == data.subdata(in: offset + 46..<offset + 46 + length),
                  contentStart + compressed <= centralOffset,
                  !occupied.contains(where: { $0.overlaps(local..<contentStart + compressed) }) else {
                throw SkinError(message: "ZIP 本地条目与目录不一致。")
            }
            occupied.append(local..<contentStart + compressed)
            expanded += uncompressed
            guard expanded <= maxExpanded else { throw SkinError(message: "ZIP 展开后不得超过 100 MiB。") }
            offset += 46 + length + extra + comment
        }
        guard offset == end else { throw SkinError(message: "ZIP 目录长度不匹配。") }
    }
}
