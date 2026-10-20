import Foundation

/// Finds the `omp` executable that Axi starts as a child process.
public enum OMPLocator {
    /// The executable at the configured path when it is valid, otherwise the first `omp` found by `find`.
    /// Blocking: call it off the main actor.
    public static func resolve(
        configuredPath: String?,
        fileManager: FileManager = .default
    ) -> URL? {
        if let configuredPath, !configuredPath.isEmpty {
            let expanded = (configuredPath as NSString).expandingTildeInPath
            if fileManager.isExecutableFile(atPath: expanded) {
                return URL(fileURLWithPath: expanded)
            }
            return nil
        }
        let environment = ProcessInfo.processInfo.environment
        var merged = environment
        if let loginPath = loginShellPath(), !loginPath.isEmpty {
            merged["PATH"] = loginPath
        }
        return find(environment: merged, fileManager: fileManager)
    }

    /// The first executable `omp` found on the PATH, then in the usual install folders.
    private static func find(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) -> URL? {
        let path = environment["PATH"]?.split(separator: ":").map(String.init) ?? []
        let home = fileManager.homeDirectoryForCurrentUser.path
        let extra = ["/opt/homebrew/bin", "\(home)/.bun/bin"]
        for directory in path + extra {
            let candidate = URL(fileURLWithPath: directory).appending(path: "omp")
            if fileManager.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }

    /// The PATH of the user's login shell, so that a GUI app sees the same tools as a terminal.
    private static func loginShellPath() -> String? {
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: shell)
        process.arguments = ["-l", "-c", "printf %s \"$PATH\""]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return nil
        }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return String(decoding: data, as: UTF8.self)
    }
}
