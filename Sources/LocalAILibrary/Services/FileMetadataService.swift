import Foundation

public struct FileMetadata: Sendable, Hashable {
    public let sizeBytes: Int64
    public let format: ModelFormat
    public let modifiedDate: Date?
    public let representativeFiles: [String]

    public init(sizeBytes: Int64, format: ModelFormat, modifiedDate: Date? = nil, representativeFiles: [String] = []) {
        self.sizeBytes = sizeBytes
        self.format = format
        self.modifiedDate = modifiedDate
        self.representativeFiles = representativeFiles
    }
}

public struct FileMetadataService: Sendable {
    public init() {}

    public func metadata(for url: URL) async -> FileMetadata {
        let canonical = url.resolvingSymlinksInPath().standardizedFileURL
        var isDirectory = ObjCBool(false)
        guard FileManager.default.fileExists(atPath: canonical.path, isDirectory: &isDirectory) else {
            return FileMetadata(sizeBytes: 0, format: .unknown)
        }
        if !isDirectory.boolValue {
            return fileMetadata(for: canonical)
        }

        var total: Int64 = 0
        var dates: [Date] = []
        var names: [String] = []
        var identities = Set<String>()
        if let enumerator = FileManager.default.enumerator(
            at: canonical,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey, .isSymbolicLinkKey],
            options: []
        ) {
            while let child = enumerator.nextObject() as? URL {
                let physicalURL = child.resolvingSymlinksInPath().standardizedFileURL
                let physical = physicalURL.path
                guard identities.insert(physical).inserted else { continue }
                let values = try? physicalURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey])
                guard values?.isRegularFile == true else { continue }
                total += Int64(values?.fileSize ?? 0)
                if let date = values?.contentModificationDate { dates.append(date) }
                let ext = child.pathExtension.lowercased()
                if ["gguf", "safetensors", "bin"].contains(ext), names.count < 8 { names.append(child.lastPathComponent) }
            }
        }
        return FileMetadata(sizeBytes: total, format: .directory, modifiedDate: dates.max(), representativeFiles: names.sorted())
    }

    private func fileMetadata(for url: URL) -> FileMetadata {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        let format: ModelFormat
        switch url.pathExtension.lowercased() {
        case "gguf": format = .gguf
        case "safetensors": format = .safeTensors
        case "bin": format = .binary
        default: format = .unknown
        }
        return FileMetadata(sizeBytes: Int64(values?.fileSize ?? 0), format: format, modifiedDate: values?.contentModificationDate, representativeFiles: [url.lastPathComponent])
    }
}
