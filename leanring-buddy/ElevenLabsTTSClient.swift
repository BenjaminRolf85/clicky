//
//  ElevenLabsTTSClient.swift
//  ECHO — by Echomotion
//
//  TTS powered by Fish Audio via the Cloudflare Worker proxy.
//  The class name is kept for backward compatibility with all call sites.
//

import AVFoundation
import Foundation

@MainActor
final class ElevenLabsTTSClient {

    private let proxyURL: URL
    private let session: URLSession
    private var audioPlayer: AVAudioPlayer?

    init(proxyURL: String) {
        self.proxyURL = URL(string: proxyURL)!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    /// Sends `text` to the Worker /tts endpoint (Fish Audio) and plays the MP3.
    func speakText(_ text: String) async throws {
        var request = URLRequest(url: proxyURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "ECHOTTS", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ECHOTTS", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "TTS error (\(http.statusCode)): \(msg)"])
        }

        try Task.checkCancellation()

        let player = try AVAudioPlayer(data: data)
        self.audioPlayer = player
        player.play()
        print("🔊 ECHO TTS: playing \(data.count / 1024)KB audio")
    }

    var isPlaying: Bool { audioPlayer?.isPlaying ?? false }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
