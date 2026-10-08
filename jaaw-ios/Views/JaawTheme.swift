import SwiftUI

// MARK: - Shared jaaw theme

enum JaawColors {
    static let blueHi = Color(hex: 0x3436FF)
    static let blueMid = Color(hex: 0x1517EE)
    static let blueDeep = Color(hex: 0x06074A)
    static let deep = Color(hex: 0x06074A)
    static let cloudMid = Color(hex: 0x6F7BFF)
    static let cloudDeep = Color(hex: 0x0A0CC8)
    static let cloudBright = Color(hex: 0xB9C3FF)
    static let ice = Color(hex: 0xD6DDFF)
    static let muted = Color(red: 222 / 255, green: 228 / 255, blue: 1, opacity: 0.8)
    static let fieldFill = Color(red: 4 / 255, green: 5 / 255, blue: 70 / 255, opacity: 0.34)
    static let fieldFillFocused = Color(red: 4 / 255, green: 5 / 255, blue: 70 / 255, opacity: 0.5)
    static let scrim = Color(red: 5 / 255, green: 6 / 255, blue: 60 / 255)
    static let scrimDeep = Color(red: 4 / 255, green: 5 / 255, blue: 44 / 255)
    static let ctaTint = Color(hex: 0x0C0EC9)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

struct JaawBackground: View {
    struct Configuration {
        var orbOffsets: [CGPoint]
        var highlights: [(point: UnitPoint, radius: CGFloat, opacity: Double)]
        var fadeHeight: CGFloat = 480
        var fadeMidOpacity: Double = 0.78
        var fadeEndOpacity: Double = 0.95
    }

    static let landing = Configuration(
        orbOffsets: [
            CGPoint(x: 10, y: -170),   // o3
            CGPoint(x: -120, y: -130), // o1
            CGPoint(x: -1, y: -60),    // o2 (trailing-anchored, resolved below)
        ],
        highlights: [
            (UnitPoint(x: 0.28, y: 0.20), 220, 0.28),
            (UnitPoint(x: 0.85, y: 0.42), 150, 0.14),
        ]
    )

    static let login = Configuration(
        orbOffsets: [
            CGPoint(x: 40, y: -180),   // o3
            CGPoint(x: -140, y: -50),  // o1
            CGPoint(x: -1, y: 30),     // o2 (trailing-anchored, resolved below)
        ],
        highlights: [
            (UnitPoint(x: 0.70, y: 0.14), 230, 0.28),
            (UnitPoint(x: 0.10, y: 0.40), 150, 0.13),
        ],
        fadeHeight: 500,
        fadeMidOpacity: 0.7,
        fadeEndOpacity: 0.92
    )

    var configuration: Configuration
    var drift: Bool
    var reduceMotion: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: JaawColors.blueHi, location: 0),
                    .init(color: JaawColors.blueMid, location: 0.45),
                    .init(color: JaawColors.blueDeep, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            GeometryReader { proxy in
                let w = proxy.size.width
                ZStack {
                    // o3 — bright cloud, top.
                    orb(
                        color: JaawColors.cloudBright,
                        size: CGSize(width: 340, height: 200),
                        baseOffset: CGPoint(
                            x: configuration.orbOffsets[0].x + 170 - w / 2,
                            y: configuration.orbOffsets[0].y
                        ),
                        opacity: 0.5,
                        duration: 26
                    )
                    // o1 — mid cloud, upper-left.
                    orb(
                        color: JaawColors.cloudMid,
                        size: CGSize(width: 380, height: 300),
                        baseOffset: CGPoint(
                            x: configuration.orbOffsets[1].x + 190 - w / 2,
                            y: configuration.orbOffsets[1].y
                        ),
                        opacity: 0.7,
                        duration: 18
                    )
                    // o2 — deep cloud, trailing-anchored.
                    orb(
                        color: JaawColors.cloudDeep,
                        size: CGSize(width: 300, height: 340),
                        baseOffset: CGPoint(x: w / 2 - 20 - 150, y: configuration.orbOffsets[2].y),
                        opacity: 0.9,
                        duration: 22
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }

            ForEach(configuration.highlights.indices, id: \.self) { index in
                let highlight = configuration.highlights[index]
                GeometryReader { proxy in
                    RadialGradient(
                        colors: [.white.opacity(highlight.opacity), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: highlight.radius
                    )
                    .frame(width: highlight.radius * 2, height: highlight.radius * 2)
                    .position(
                        x: highlight.point.x * proxy.size.width,
                        y: highlight.point.y * proxy.size.height * 0.9
                    )
                    .blendMode(.screen)
                }
            }

            VStack {
                Spacer()
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: JaawColors.scrim.opacity(configuration.fadeMidOpacity), location: 0.55),
                        .init(color: JaawColors.scrimDeep.opacity(configuration.fadeEndOpacity), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: configuration.fadeHeight)
            }
        }
        .ignoresSafeArea()
    }

    private func orb(
        color: Color,
        size: CGSize,
        baseOffset: CGPoint,
        opacity: Double,
        duration: Double
    ) -> some View {
        Ellipse()
            .fill(color)
            .frame(width: size.width, height: size.height)
            .opacity(opacity)
            .blur(radius: 46)
            .offset(
                x: baseOffset.x + (drift ? 34 : 0),
                y: baseOffset.y + (drift ? 26 : 0)
            )
            .scaleEffect(drift ? 1.08 : 1.0)
            .animation(
                reduceMotion
                    ? nil
                    : .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: drift
            )
    }
}

struct GlassPanel<Content: View>: View {
    var cornerRadius: CGFloat = 26
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.55)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.26), .white.opacity(0.07)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.28), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .clear],
                            startPoint: .top,
                            endPoint: .center
                        ),
                        lineWidth: 1
                    )
                    .mask(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .frame(height: 27)
                            .frame(maxHeight: .infinity, alignment: .top)
                    )
            )
            .shadow(color: Color(red: 0, green: 0, blue: 60 / 255, opacity: 0.6), radius: 40, y: 18)
    }
}

struct JaawCTAStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && isEnabled ? 0.97 : 1.0)
            .opacity(isEnabled ? 1 : 0.55)
            .shadow(
                color: Color(red: 0, green: 0, blue: 70 / 255, opacity: 0.7),
                radius: configuration.isPressed ? 16 : 30,
                y: configuration.isPressed ? 6 : 14
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Home (dashboard) palette
// Fixed dark theme with a restrained blue ambience: near-black base, soft
// glows, solid cards. White text throughout.

enum HomeColors {
    static let page = Color(hex: 0x08090E)
    static let glowPrimary = Color(hex: 0x3436FF)
    static let glowSecondary = Color(hex: 0x1E20D2)
    static let orbBlue = Color(hex: 0x2A2CFF)
    static let orbBright = Color(hex: 0x5A64FF)
    static let card = Color(hex: 0x12131B)
    static let cardBorder = Color.white.opacity(0.07)
    static let tileEyebrow = Color(red: 235 / 255, green: 239 / 255, blue: 1, opacity: 0.8)
    static let secondaryText = Color(red: 214 / 255, green: 220 / 255, blue: 245 / 255, opacity: 0.62)
    static let faintText = Color(red: 214 / 255, green: 220 / 255, blue: 245 / 255, opacity: 0.55)
    static let timeText = Color(red: 226 / 255, green: 231 / 255, blue: 1, opacity: 0.9)
    static let nowDetail = Color(red: 235 / 255, green: 239 / 255, blue: 1, opacity: 0.82)
    static let avatarFill = Color(hex: 0x1A1B27)
    static let avatarBorder = Color.white.opacity(0.1)
    static let ringTrack = Color.white.opacity(0.09)
    static let ringPrimary = Color.white
    static let ringSecondary = Color(hex: 0x7D88FF)
    static let nowStart = Color(hex: 0x4143FF)
    static let nowEnd = Color(hex: 0x1D1FE6)
    static let nowBorder = Color.white.opacity(0.18)
    static let tagBlue = Color(hex: 0x2022EE)
}
