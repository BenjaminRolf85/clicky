//
//  EchoLogoCursor.swift
//  ECHO — by Echomotion
//
//  Renders the official Echomotion logo as the floating cursor that follows
//  the mouse and points at UI elements.
//
//  The logo is loaded from the asset catalog (EchoLogo imageset).
//  Animates: glow on idle, pulse ring on listening, rotation on processing.
//

import SwiftUI

// MARK: - Echo Logo Cursor View

struct EchoLogoView: View {
    var size: CGFloat = 32
    var glowIntensity: CGFloat = 1.0
    var isListening: Bool = false
    var isProcessing: Bool = false

    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    private let purple = Color(red: 0.482, green: 0.184, blue: 0.745)

    var body: some View {
        ZStack {
            // Glow ring underneath
            Circle()
                .fill(purple.opacity(0.35 * glowIntensity))
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: size * 0.3)

            // Pulse ring when listening
            if isListening {
                Circle()
                    .stroke(purple.opacity(0.7), lineWidth: size * 0.06)
                    .frame(width: size * 1.3, height: size * 1.3)
                    .scaleEffect(pulseScale)
                    .opacity(2.0 - pulseScale)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.8).repeatForever(autoreverses: false)) {
                            pulseScale = 1.6
                        }
                    }
            }

            // The actual logo image
            Image("EchoLogo")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .rotationEffect(.degrees(isProcessing ? rotationAngle : 0))
                .onAppear {
                    if isProcessing {
                        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }
                }
        }
        .frame(width: size * 1.5, height: size * 1.5)
    }
}

// MARK: - Preview

#if DEBUG
struct EchoLogoView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 20) {
            EchoLogoView(size: 32, glowIntensity: 1.0)
            EchoLogoView(size: 32, isListening: true)
            EchoLogoView(size: 32, isProcessing: true)
            EchoLogoView(size: 48, glowIntensity: 1.5)
        }
        .padding(40)
        .background(Color(white: 0.1))
        .previewLayout(.sizeThatFits)
    }
}
#endif
