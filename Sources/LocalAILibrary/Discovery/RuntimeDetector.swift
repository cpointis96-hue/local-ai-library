import Foundation

public struct RuntimeDetector: Sendable {
    private let executableLookup: ExecutableLookup

    public init() {
        self.executableLookup = RuntimeDetector.defaultLookup
    }

    public init(executableLookup: @escaping ExecutableLookup) {
        self.executableLookup = executableLookup
    }

    public func detect() -> Set<RuntimeType> {
        var result = Set<RuntimeType>()
        if executableLookup("ollama") != nil { result.insert(.ollama) }
        if executableLookup("mlx_lm") != nil { result.insert(.mlx) }
        if executableLookup("llama-server") != nil || executableLookup("llama-cli") != nil { result.insert(.llamaCPP) }
        if executableLookup("lms") != nil { result.insert(.lmStudio) }
        return result
    }

    private static let defaultLookup: ExecutableLookup = { executable in
        let paths = (ProcessInfo.processInfo.environment["PATH"] ?? "").split(separator: ":").map(String.init)
            + ["/usr/local/bin", "/opt/homebrew/bin", "/usr/bin", "/bin"]
        for directory in paths {
            let path = URL(fileURLWithPath: directory).appendingPathComponent(executable).path
            if FileManager.default.isExecutableFile(atPath: path) { return path }
        }
        return nil
    }
}
