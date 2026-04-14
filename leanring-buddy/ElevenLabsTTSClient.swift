//
//  ElevenLabsTTSClient.swift
//  ECHO — by Echomotion
//
//  TTS powered by Fish Audio (api.fish.audio) instead of ElevenLabs.
//  The class name is kept for backward compatibility with all call sites.
//
//  API: POST https://api.fish.audio/v1/tts
//  Auth: Authorization: Bearer <api_key>
//  Returns: raw MP3 audio bytes
//

import AVFoundation
import Foundation

@MainActor
final class ElevenLabsTTSClient {

    private let apiKey: String
    private let referenceId: String   // Fish Audio voice/model ID
    private let session: URLSession

    private var audioPlayer: AVAudioPlayer?

    /// proxyURL parameter is accepted but ignored — Fish Audio is called directly.
    /// apiKey and referenceId are read from the app bundle Info.plist or environment.
    init(proxyURL: String) {
        // Read Fish Audio credentials from Info.plist build settings
        self.apiKey    = AppBundleConfiguration.stringValue(forKey: "FISH_AUDIO_API_KEY")   ?? ""
        self.referenceId = AppBundleConfiguration.stringValue(forKey: "FISH_AUDIO_VOICE_ID") ?? ""

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    /// Sends `text` to Fish Audio TTS and plays the resulting MP3.
    func speakText(_ text: String) async throws {
        guard !apiKey.isEmpty else {
            throw NSError(
                domain: "FishAudioTTS", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "FISH_AUDIO_API_KEY not set in build settings"]
            )
        }

        var request = URLRequest(url: URL(string: "https://api.fish.audio/v1/tts")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json",  forHTTPHeaderField: "Content-Type")
        // Model header: s1 (fast) or s2-pro (higher quality)
        request.setValue("s1", forHTTPHeaderField: "model")

        var body: [String: Any] = ["text": text, "format": "mp3"]
        if !referenceId.isEmpty {
            body["reference_id"] = referenceId
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "FishAudioTTS", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "FishAudioTTS", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Fish Audio error (\(http.statusCode)): \(msg)"])
        }

        try Task.checkCancellation()

        let player = try AVAudioPlayer(data: data)
        self.audioPlayer = player
        player.play()
        print("🔊 Fish Audio TTS: playing \(data.count / 1024)KB audio")
    }

    var isPlaying: Bool { audioPlayer?.isPlaying ?? false }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
