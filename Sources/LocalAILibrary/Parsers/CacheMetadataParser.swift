import Foundation

public enum CacheMetadataParser {
    public static func repositoryURL(for url: URL) -> URL? {
        let directory = url.hasDirectoryPath ? url : url.deletingLastPathComponent()
        let metadataNames = ["model_info.json", "metadata.json", "config.json"]

        for name in metadataNames {
            let metadataURL = directory.appendingPathComponent(name)
            guard let text = try? String(contentsOf: metadataURL, encoding: .utf8),
                  text.utf8.count <= 256 * 1024,
                  let data = text.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data),
                  let dictionary = object as? [String: Any] else { continue }

            for key in ["repo_id", "repository", "repository_id", "model_id"] {
                if let value = dictionary[key] as? String, let result = repositoryURL(from: value) {
                    return result
                }
            }
        }

        let refs = directory.appendingPathComponent("refs/main")
        if let value = try? String(contentsOf: refs, encoding: .utf8),
           let result = repositoryURL(from: value.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return result
        }

        let components = directory.standardizedFileURL.pathComponents
        guard let repository = components.reversed().first(where: { $0.hasPrefix("models--") }) else { return nil }
        return repositoryURL(from: repository.replacingOccurrences(of: "models--", with: "").replacingOccurrences(of: "--", with: "/"))
    }

    private static func repositoryURL(from value: String) -> URL? {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let parts = value.split(separator: "/", omittingEmptySubsequences: true)
        guard parts.count == 2,
              parts.allSatisfy({ !$0.contains(where: { $0 == " " || $0 == "?" || $0 == "#" }) }) else { return nil }
        return URL(string: "https://huggingface.co/\(parts[0])/\(parts[1])")
    }
}
