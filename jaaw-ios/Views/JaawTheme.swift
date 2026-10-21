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
    /// Neutral field chrome — a whisper of white over the backdrop rather than
    /// a blue tint, so the controls read as native on any background.
    static let fieldFill = Color.white.opacity(0.06)
    static let fieldFillFocused = Color.white.opacity(0.11)
    static let fieldBorder = Color.white.opacity(0.12)
    static let fieldBorderFocused = Color.white.opacity(0.5)
    static let fieldPlaceholder = Color.white.opacity(0.35)
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

    /// A colour that follows the system appearance, swapping between a light
    /// and a dark value. Dynamic under the hood, so it flips the moment the
    /// device changes appearance.
    init(light: UInt, dark: UInt) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
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

    /// Home reuses the brand backdrop: the same blue field and clouds as
    /// landing/login, weighted so the glow sits behind the day-order hero.
    static let home = Configuration(
        orbOffsets: [
            CGPoint(x: 20, y: -200),   // o3
            CGPoint(x: -130, y: -120), // o1
            CGPoint(x: -1, y: -20),    // o2 (trailing-anchored, resolved below)
        ],
        highlights: [
            (UnitPoint(x: 0.74, y: 0.12), 240, 0.26),
            (UnitPoint(x: 0.16, y: 0.34), 170, 0.13),
        ],
        fadeHeight: 420,
        fadeMidOpacity: 0.6,
        fadeEndOpacity: 0.9
    )

    /// Calendar: the same brand field, weighted so the glow sits behind the
    /// page header and the month grid below it stays legible.
    static let calendar = Configuration(
        orbOffsets: [
            CGPoint(x: 30, y: -210),   // o3
            CGPoint(x: -140, y: -140), // o1
            CGPoint(x: -1, y: -30),    // o2 (trailing-anchored, resolved below)
        ],
        highlights: [
            (UnitPoint(x: 0.80, y: 0.10), 250, 0.26),
            (UnitPoint(x: 0.12, y: 0.30), 180, 0.12),
        ],
        fadeHeight: 460,
        fadeMidOpacity: 0.62,
        fadeEndOpacity: 0.9
    )

    /// Marks: the glow sits behind the score hero on the trailing side.
    static let marks = Configuration(
        orbOffsets: [
            CGPoint(x: 10, y: -230),   // o3
            CGPoint(x: -120, y: -150), // o1
            CGPoint(x: -1, y: -40),    // o2 (trailing-anchored, resolved below)
        ],
        highlights: [
            (UnitPoint(x: 0.82, y: 0.08), 260, 0.28),
            (UnitPoint(x: 0.14, y: 0.26), 170, 0.12),
        ],
        fadeHeight: 480,
        fadeMidOpacity: 0.64,
        fadeEndOpacity: 0.9
    )

    /// Timetable: the glow sits behind the day-order hero.
    static let timetable = Configuration(
        orbOffsets: [
            CGPoint(x: 40, y: -220),   // o3
            CGPoint(x: -150, y: -130), // o1
            CGPoint(x: -1, y: -25),    // o2 (trailing-anchored, resolved below)
        ],
        highlights: [
            (UnitPoint(x: 0.78, y: 0.09), 255, 0.27),
            (UnitPoint(x: 0.13, y: 0.28), 175, 0.12),
        ],
        fadeHeight: 470,
        fadeMidOpacity: 0.63,
        fadeEndOpacity: 0.9
    )

    /// Attendance: the glow sits behind the overall-score hero.
    static let attendance = Configuration(
        orbOffsets: [
            CGPoint(x: 0, y: -235),    // o3
            CGPoint(x: -130, y: -140), // o1
            CGPoint(x: -1, y: -35),    // o2 (trailing-anchored, resolved below)
        ],
        highlights: [
            (UnitPoint(x: 0.80, y: 0.09), 255, 0.27),
            (UnitPoint(x: 0.12, y: 0.27), 180, 0.12),
        ],
        fadeHeight: 470,
        fadeMidOpacity: 0.63,
        fadeEndOpacity: 0.9
    )

    /// Profile: the glow sits behind the identity card.
    static let profile = Configuration(
        orbOffsets: [
            CGPoint(x: -20, y: -225),  // o3
            CGPoint(x: -140, y: -125), // o1
            CGPoint(x: -1, y: -30),    // o2 (trailing-anchored, resolved below)
        ],
        highlights: [
            (UnitPoint(x: 0.72, y: 0.10), 250, 0.27),
            (UnitPoint(x: 0.15, y: 0.25), 180, 0.12),
        ],
        fadeHeight: 460,
        fadeMidOpacity: 0.62,
        fadeEndOpacity: 0.9
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

/// The backdrop shared by the calendar, marks, timetable and attendance tabs:
/// the brand field, the entry clip behind it, and a scrim that keeps white
/// type legible over the clip's bright cloud band.
struct JaawTabBackdrop: View {
    var configuration: JaawBackground.Configuration
    var drift: Bool
    var reduceMotion: Bool
    /// The tab this backdrop belongs to — its clip only plays while that tab
    /// is the visible one. `nil` (a pushed page) always plays.
    var tab: MainTab?

    var body: some View {
        ZStack {
            JaawBackground(
                configuration: configuration,
                drift: drift,
                reduceMotion: reduceMotion
            )
            JaawVideoBackdrop(
                resource: JaawEntryVideo.landing,
                reduceMotion: reduceMotion,
                isActive: tab.map { TabActivity.shared.isActive($0) } ?? true
            )
            // The clip's bright cloud band would swallow white type sitting
            // behind the glass panels, so the tabs run a deeper scrim than the
            // landing page does.
            LinearGradient(
                stops: [
                    .init(color: JaawColors.scrimDeep.opacity(0.30), location: 0),
                    .init(color: JaawColors.scrimDeep.opacity(0.60), location: 0.42),
                    .init(color: JaawColors.scrimDeep.opacity(0.80), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
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
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
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

/// A tap that sinks the control a touch — the small press feedback shared by
/// the day cells, the month arrows and the card buttons.
struct PressScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.9

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
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

// MARK: - Card palette
// The sheets and cards follow the system appearance: paper white on light,
// deep slate on dark. The values are dynamic, so a card flips the moment the
// device changes appearance and keeps its own contrast either way.

enum CardPalette {
    /// The card's own surface.
    static let fill = Color(light: 0xFFFFFF, dark: 0x14161F)
    /// Ink.
    static let title = Color(light: 0x121722, dark: 0xF3F5FB)
    static let body = Color(light: 0x6B7383, dark: 0xA7AFC2)
    static let muted = Color(light: 0x9AA3B2, dark: 0x7A8499)
    static let strike = Color(light: 0xB9C0CC, dark: 0x5B6376)
    /// Hairlines.
    static let divider = Color(light: 0xE2E6EE, dark: 0x272B38)
    /// The accent, used as a fill behind white text — the same blue in both
    /// appearances so the buttons stay legible.
    static let accent = Color(hex: 0x2F5BFF)
    /// The accent as ink on a card, lightened once the card is dark.
    static let accentInk = Color(light: 0x2F5BFF, dark: 0x8FA6FF)
    /// Raised sub-surfaces: stat strips, chips and progress tracks.
    static let surface = Color(light: 0xF4F6FA, dark: 0x1D212D)
    static let surfaceAlt = Color(light: 0xEEF1F7, dark: 0x252A38)
    static let track = Color(light: 0xEDF0F5, dark: 0x2C3140)
    /// The card's edge — invisible on paper, a hairline once the card is dark.
    static let border = Color.white.opacity(0.10)
    /// The lift under a card.
    static let shadow = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.black.withAlphaComponent(0.55)
                : UIColor(red: 0.02, green: 0.03, blue: 0.25, alpha: 0.30)
        }
    )
}

// MARK: - Calendar palette
// The month grid lives on dark glass, so its day markers need bright tones
// to read against the video; the same markers become chips on the card,
// which need deeper ones on paper and brighter ones once it turns dark.

enum CalendarPalette {
    /// Markers on the dark glass grid.
    static let holidayDot = Color(hex: 0x3DDC84)
    static let eventDot = Color(hex: 0xFF7A66)
    static let dayOrderDot = Color(hex: 0x8FA6FF)

    /// Chips on the card.
    static let holidayChip = Color(light: 0x0E9F6E, dark: 0x3DDC84)
    static let eventChip = Color(light: 0xE0442E, dark: 0xFF7A66)
    static let dayOrderChip = Color(light: 0x2F5BFF, dark: 0x8FA6FF)
    static let plainChip = Color(light: 0x8C94A4, dark: 0x9AA3B2)
}

// MARK: - Marks palette
// Score tiers run from a deep green through the brand blue and amber to a
// warm red, so a score reads at a glance without leaning on bland greys.
// They lighten once the card they sit on turns dark.

enum MarksPalette {
    static let strong = Color(light: 0x12B981, dark: 0x2FD69C)
    static let steady = Color(light: 0x2F5BFF, dark: 0x8FA6FF)
    static let soft = Color(light: 0xF59E0B, dark: 0xFBBF24)
    static let weak = Color(light: 0xEF5B5B, dark: 0xF87171)
    /// The "best course" marker.
    static let best = Color(light: 0xFFB020, dark: 0xFFC44D)

    /// The tier a percentage falls into.
    static func tier(for percent: Double) -> Color {
        switch percent {
        case 85...: return strong
        case 70..<85: return steady
        case 50..<70: return soft
        default: return weak
        }
    }
}

// MARK: - Attendance palette
// Attendance is judged against the 75% rule, so its tiers break at
// different points than marks do.

enum AttendancePalette {
    static let safe = Color(light: 0x12B981, dark: 0x2FD69C)
    static let warning = Color(light: 0xF59E0B, dark: 0xFBBF24)
    static let atRisk = Color(light: 0xEF5B5B, dark: 0xF87171)

    static func tier(for percent: Double) -> Color {
        switch percent {
        case 85...: return safe
        case 75..<85: return warning
        default: return atRisk
        }
    }
}
