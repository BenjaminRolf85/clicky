//
//  EchoAnalytics.swift
//  ECHO — by Echomotion
//
//  Lightweight analytics stub. Replaces the original PostHog/ClickyAnalytics
//  integration. All tracking calls are no-ops by default so the app ships
//  without any third-party telemetry. Wire up your own analytics backend here
//  if needed (e.g. Amplitude, Mixpanel, or a self-hosted solution).
//

import Foundation

enum EchoAnalytics {

    // MARK: - Setup

    static func configure() {
        // No-op. Add your analytics SDK initialisation here if desired.
    }

    // MARK: - App Lifecycle

    static func trackAppOpened() {}

    // MARK: - Onboarding

    static func trackOnboardingStarted() {}
    static func trackOnboardingReplayed() {}
    static func trackOnboardingVideoCompleted() {}
    static func trackOnboardingDemoTriggered() {}

    // MARK: - Permissions

    static func trackAllPermissionsGranted() {}
    static func trackPermissionGranted(permission: String) {}

    // MARK: - Voice Interaction

    static func trackPushToTalkStarted() {}
    static func trackPushToTalkReleased() {}
    static func trackUserMessageSent(transcript: String) {}
    static func trackAIResponseReceived(response: String) {}
    static func trackElementPointed(elementLabel: String?) {}

    // MARK: - Errors

    static func trackResponseError(error: String) {}
    static func trackTTSError(error: String) {}
}

/// Backward-compat alias so call sites that still say ClickyAnalytics compile.
typealias ClickyAnalytics = EchoAnalytics
