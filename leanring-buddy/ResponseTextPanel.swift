//
//  ResponseTextPanel.swift
//  ECHO — by Echomotion
//
//  A small floating panel that appears next to the ECHO menu bar icon
//  when a response is being generated, showing the spoken text.
//  Fades out automatically after TTS playback ends.
//

import AppKit
import Combine
import SwiftUI

// MARK: - View Model

final class ResponseTextPanelViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var isVisible: Bool = false
}

// MARK: - SwiftUI View

private struct ResponseTextView: View {
    @ObservedObject var model: ResponseTextPanelViewModel

    var body: some View {
        if model.isVisible && !model.text.isEmpty {
            HStack(alignment: .top, spacing: 10) {
                // ECHO logo dot
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.48, green: 0.18, blue: 0.75),
                                     Color(red: 0, green: 0.83, blue: 1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 8, height: 8)
                    .padding(.top, 5)

                Text(model.text)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                    .lineLimit(8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.purple.opacity(0.25), lineWidth: 0.5)
            )
            .padding(8)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .topTrailing)),
                removal: .opacity
            ))
        }
    }
}

// MARK: - Panel Manager

@MainActor
final class ResponseTextPanelManager {
    private let model = ResponseTextPanelViewModel()
    private var panel: NSPanel?
    private var hideTask: Task<Void, Never>?

    private let panelWidth: CGFloat = 300

    func setup() {
        let contentView = NSHostingView(rootView:
            ResponseTextView(model: model)
                .frame(maxWidth: panelWidth)
        )

        let p = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.contentView = contentView
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.level = .statusBar + 1
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.ignoresMouseEvents = true
        self.panel = p
    }

    /// Show the panel anchored near the menu bar status item.
    func show(text: String, near statusItemButton: NSButton? = nil) {
        hideTask?.cancel()

        model.text = text

        // Position panel near top-right of screen (below menu bar)
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let menuBarHeight: CGFloat = screen.frame.height - screenFrame.maxY + 4
            let x = screen.frame.maxX - panelWidth - 20
            let y = screen.frame.maxY - menuBarHeight - 4

            panel?.setFrameTopLeftPoint(NSPoint(x: x, y: y))
            panel?.setContentSize(NSSize(width: panelWidth, height: 1)) // auto-size
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            model.isVisible = true
        }
        panel?.orderFrontRegardless()
    }

    /// Append streaming text chunk.
    func appendText(_ chunk: String) {
        model.text += chunk
    }

    /// Hide the panel after a short delay.
    func hide(afterSeconds delay: Double = 4.0) {
        hideTask?.cancel()
        hideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.4)) {
                model.isVisible = false
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
            panel?.orderOut(nil)
            model.text = ""
        }
    }

    /// Hide immediately.
    func hideNow() {
        hideTask?.cancel()
        model.isVisible = false
        panel?.orderOut(nil)
        model.text = ""
    }
}
