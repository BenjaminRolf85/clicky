import Foundation

/// Loads SOUL.md from the app bundle root (next to the .app) or the project root.
/// The SOUL.md text is injected into Claude's system prompt so ECHO can have
/// a custom personality — the same pattern Zippy uses on Windows.
enum SOULConfiguration {

    /// Returns the content of SOUL.md if one is found, or nil otherwise.
    static func load() -> String? {
        // 1. Next to the running .app bundle (production)
        if let bundleURL = Bundle.main.bundleURL.deletingLastPathComponent() as URL?,
           let content = try? String(contentsOf: bundleURL.appendingPathComponent("SOUL.md"), encoding: .utf8),
           !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return content
        }

        // 2. Two levels up from the binary (Xcode build, running from DerivedData)
        if let resourcePath = Bundle.main.resourcePath {
            let candidates = [
                URL(fileURLWithPath: resourcePath).appendingPathComponent("SOUL.md").path,
                URL(fileURLWithPath: resourcePath)
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .appendingPathComponent("SOUL.md").path,
            ]
            for path in candidates {
                if let content = try? String(contentsOfFile: path, encoding: .utf8),
                   !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return content
                }
            }
        }

        return nil
    }

    /// Returns a system-prompt prefix that incorporates SOUL.md when present.
    /// If no SOUL.md is found the empty string is returned and the caller should
    /// fall back to its built-in persona.
    static func systemPromptPrefix() -> String {
        guard let soul = load() else { return "" }
        return """
        The following is your personality and soul configuration. Follow it precisely.

        \(soul)

        ---

        """
    }
}
