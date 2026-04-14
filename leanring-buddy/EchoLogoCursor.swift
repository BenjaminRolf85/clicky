//
//  EchoLogoCursor.swift
//  ECHO — by Echomotion
//
//  Renders the Echomotion brand mark (purple circle with 9 white dots)
//  as the floating cursor that follows the mouse and points at UI elements.
//
//  The 9-dot pattern matches the official Echomotion favicon:
//    center column: top · center · bottom
//    middle row:    left · center · right
//    diagonals:     four corners
//

import SwiftUI

// MARK: - Echomotion Brand Mark

struct EchoLogoView: View {
    var size: CGFloat = 32
    var glowIntensity: CGFloat = 1.0   // 0 = no glow, 1 = full
    var isListening: Bool = false
    var isProcessing: Bool = false

    private let purple = Color(red: 0.482, green: 0.184, blue: 0.745)  // #7B2FBE

    /// Relative positions of the 9 dots (nx, ny in 0–1 space).
    private let dotPositions: [(CGFloat, CGFloat)] = [
        (0.50, 0.25),  // top
        (0.50, 0.50),  // center
        (0.50, 0.75),  // bottom
        (0.25, 0.50),  // left
        (0.75, 0.50),  // right
        (0.28, 0.28),  // top-left
        (0.72, 0.28),  // top-right
        (0.28, 0.72),  // bottom-left
        (0.72, 0.72),  // bottom-right
    ]

    var body: some View {
        ZStack {
            // Purple circle background
            Circle()
                .fill(purple)
                .frame(width: size, height: size)
                .shadow(
                    color: purple.opacity(0.7 * glowIntensity),
                    radius: size * 0.4 * glowIntensity
                )

            // 9 white dots
            Canvas { context, canvasSize in
                let dotRadius = size * 0.075
                for (nx, ny) in dotPositions {
                    let cx = nx * canvasSize.width
                    let cy = ny * canvasSize.height
                    let rect = CGRect(
                        x: cx - dotRadius, y: cy - dotRadius,
                        width: dotRadius * 2, height: dotRadius * 2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(.white))
                }
            }
            .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
        // Pulse ring when listening
        .overlay(
            Circle()
                .stroke(purple.opacity(isListening ? 0.6 : 0), lineWidth: size * 0.06)
                .scaleEffect(isListening ? 1.4 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isListening)
        )
        // Spin when processing
        .rotationEffect(isProcessing ? .degrees(360) : .degrees(0))
        .animation(
            isProcessing
                ? .linear(duration: 1.5).repeatForever(autoreverses: false)
                : .default,
            value: isProcessing
        )
    }
}

// MARK: - Preview

#if DEBUG
struct EchoLogoView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                EchoLogoView(size: 20, glowIntensity: 0)
                EchoLogoView(size: 32, glowIntensity: 1.0)
                EchoLogoView(size: 48, glowIntensity: 1.5)
            }
            Text("Idle · Listening · Processing")
                .font(.caption)
            HStack(spacing: 16) {
                EchoLogoView(size: 32, glowIntensity: 0.5)
                EchoLogoView(size: 32, isListening: true)
                EchoLogoView(size: 32, isProcessing: true)
            }
        }
        .padding(40)
        .background(Color(white: 0.15))
        .previewLayout(.sizeThatFits)
    }
}
#endif
