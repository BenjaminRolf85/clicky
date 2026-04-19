import Foundation

// MARK: - Handoff Result

struct HandoffResult {
    let output: String
    let toolUsed: HandoffTool
}

enum HandoffTool: String {
    case codex        = "codex"
    case claudeCode   = "claude code"
    case openClaw     = "openclaw"
}

// MARK: - Trigger Detection

/// Detects whether a transcript starts with a handoff trigger phrase and
/// strips the trigger prefix to produce a clean prompt.
///
/// Supported triggers (case-insensitive):
///   "nimm codex ..."
///   "nimm claude code ..."
///   "nimm openclaw ..."
///   English equivalents: "use codex ...", "use claude code ...", "use openclaw ..."
enum HandoffDetector {

    private static let triggers: [(prefix: String, tool: HandoffTool)] = [
        ("nimm claude code", .claudeCode),
        ("use claude code",  .claudeCode),
        ("nimm haily",      .openClaw),
        ("use haily",        .openClaw),
        ("nimm codex",       .codex),
        ("use codex",        .codex),
    ]

    /// Returns the matched tool and stripped prompt, or nil if no trigger found.
    static func detect(in transcript: String) -> (tool: HandoffTool, prompt: String)? {
        let lower = transcript.lowercased().trimmingCharacters(in: .whitespaces)
        for (prefix, tool) in triggers {
            if lower.hasPrefix(prefix) {
                let prompt = String(transcript.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard !prompt.isEmpty else { continue }
                return (tool, prompt)
            }
        }
        return nil
    }
}

// MARK: - Handoff Clients

/// Runs a CLI process and captures stdout + stderr.
private func runProcess(
    command: String,
    arguments: [String],
    workingDirectory: String? = nil,
    timeoutSeconds: Int = 120
) async throws -> String {
    return try await withCheckedThrowingContinuation { continuation in
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments

        if let wd = workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: wd)
        }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError  = pipe

        do {
            try process.run()
        } catch {
            continuation.resume(throwing: error)
            return
        }

        let deadline = DispatchTime.now() + .seconds(timeoutSeconds)
        DispatchQueue.global().asyncAfter(deadline: deadline) {
            if process.isRunning { process.terminate() }
        }

        process.waitUntilExit()

        let data   = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        continuation.resume(returning: output.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

// MARK: Codex

struct CodexClient {
    var command: String = "codex"
    var workingDirectory: String? = nil
    var timeoutSeconds: Int = 900

    func run(prompt: String) async throws -> HandoffResult {
        let output = try await runProcess(
            command: command,
            arguments: [prompt],
            workingDirectory: workingDirectory,
            timeoutSeconds: timeoutSeconds
        )
        return HandoffResult(output: output.isEmpty ? "Codex finished." : output, toolUsed: .codex)
    }
}

// MARK: Claude Code

struct ClaudeCodeClient {
    var command: String = "claude"
    var timeoutSeconds: Int = 900

    func run(prompt: String) async throws -> HandoffResult {
        let output = try await runProcess(
            command: command,
            arguments: ["-p", prompt],
            timeoutSeconds: timeoutSeconds
        )
        return HandoffResult(output: output.isEmpty ? "Claude Code finished." : output, toolUsed: .claudeCode)
    }
}

// MARK: OpenClaw (HTTP via Cloudflare Worker — no local CLI needed)

struct OpenClawClient {
    // VPS Gateway — called directly from Mac (bypasses Cloudflare)
    var gatewayBaseURL: String = "http://76.13.140.46:41513"
    var gatewayToken: String = "CmFT7vobJQlmxkzEZPLXX9uz69VoAJ3j"
    var timeoutSeconds: Int = 120

    // Legacy CLI properties (overridden by .env if present)
    var command: String = "openclaw"
    var sessionKey: String = "main"
    var gatewayUrl: String = ""

    func run(prompt: String) async throws -> HandoffResult {
        let message = """
        [ECHO Handoff]
        Quelle: ECHO by Echomotion — macOS Voice Companion
        Nutzer: Benjamin Lange (CEO, Echomotion GmbH)
        Zweck: Ben hat per Sprache eine Aufgabe delegiert.

        Aufgabe: \(prompt)
        """

        // Direct call to VPS Gateway /v1/chat/completions
        guard let url = URL(string: "\(gatewayBaseURL)/v1/chat/completions") else {
            throw NSError(domain: "ECHO", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid worker URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(gatewayToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = TimeInterval(timeoutSeconds)

        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 1024,
            "messages": [["role": "user", "content": message]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TimeInterval(timeoutSeconds)
        let session = URLSession(configuration: config)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Error"
            throw NSError(domain: "ECHO", code: (response as? HTTPURLResponse)?.statusCode ?? -1,
                userInfo: [NSLocalizedDescriptionKey: msg])
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let first = choices.first,
           let msg = first["message"] as? [String: Any],
           let reply = msg["content"] as? String {
            return HandoffResult(output: reply, toolUsed: .openClaw)
        }

        return HandoffResult(
            output: String(data: data, encoding: .utf8) ?? "HAILY: erledigt.",
            toolUsed: .openClaw
        )
    }
}

// MARK: - Unified HandoffRunner

/// Dispatches a prompt to the correct CLI tool based on HandoffTool.
struct HandoffRunner {
    var codex      = CodexClient()
    var claudeCode = ClaudeCodeClient()
    var openClaw   = OpenClawClient()

    mutating func configure(from environment: [String: String]) {
        codex.command             = environment["CODEX_COMMAND"]           ?? "codex"
        codex.workingDirectory    = environment["CODEX_WORKDIR"]
        codex.timeoutSeconds      = Int(environment["CODEX_TIMEOUT_SECONDS"] ?? "") ?? 900

        claudeCode.command        = environment["CLAUDE_CODE_COMMAND"]     ?? "claude"
        claudeCode.timeoutSeconds = Int(environment["CLAUDE_CODE_TIMEOUT_SECONDS"] ?? "") ?? 900

        openClaw.command          = environment["OPENCLAW_COMMAND"]        ?? "openclaw"
        openClaw.sessionKey       = environment["OPENCLAW_SESSION_KEY"]    ?? "main"
        openClaw.gatewayUrl       = environment["OPENCLAW_GATEWAY_URL"]    ?? ""
        openClaw.gatewayToken     = environment["OPENCLAW_GATEWAY_TOKEN"]  ?? "CmFT7vobJQlmxkzEZPLXX9uz69VoAJ3j"
        if let url = environment["OPENCLAW_GATEWAY_URL"], !url.isEmpty {
            openClaw.gatewayBaseURL = url.replacingOccurrences(of: "ws://", with: "http://")
                                        .replacingOccurrences(of: "wss://", with: "https://")
        }
        openClaw.timeoutSeconds   = Int(environment["OPENCLAW_TIMEOUT_SECONDS"] ?? "") ?? 120
    }

    func run(tool: HandoffTool, prompt: String) async throws -> HandoffResult {
        switch tool {
        case .codex:      return try await codex.run(prompt: prompt)
        case .claudeCode: return try await claudeCode.run(prompt: prompt)
        case .openClaw:   return try await openClaw.run(prompt: prompt)
        }
    }
}
