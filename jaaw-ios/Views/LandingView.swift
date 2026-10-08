import SwiftUI

struct LandingView: View {
    var onLogin: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false
    @State private var loginTapCount = 0

    var body: some View {
        ZStack {
            JaawBackground(
                configuration: JaawBackground.landing,
                drift: drift,
                reduceMotion: reduceMotion
            )
            content
        }
        .background(JaawColors.deep)
        .onAppear {
            guard !reduceMotion else { return }
            drift = true
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 0) {
            featureCards
                .padding(.top, 72)

            Spacer(minLength: 24)

            copyBlock

            loginButton
                .padding(.top, 28)

            Text("Sign in with your SRM Academia account")
                .font(.system(size: 12))
                .foregroundStyle(JaawColors.ice.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 12)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    // MARK: Feature cards

    private var featureCards: some View {
        VStack(spacing: 14) {
            HStack {
                GlassPanel {
                    AttendanceCardContent()
                        .padding(16)
                        .padding(.trailing, 2)
                        .frame(width: 196, alignment: .leading)
                }
                .frame(width: 196)
                .rotationEffect(.degrees(-5))
                Spacer(minLength: 0)
            }
            .padding(.leading, 10)

            HStack {
                Spacer(minLength: 0)
                GlassPanel {
                    NextClassCardContent()
                        .padding(16)
                        .padding(.trailing, 2)
                        .frame(width: 176, alignment: .leading)
                }
                .frame(width: 176)
                .rotationEffect(.degrees(4))
            }
            .padding(.trailing, 2)

            HStack {
                GlassPanel {
                    MarksCardContent()
                        .padding(16)
                        .padding(.trailing, 2)
                        .frame(width: 172, alignment: .leading)
                }
                .frame(width: 172)
                .rotationEffect(.degrees(-2))
                .opacity(0.9)
                Spacer(minLength: 0)
            }
            .padding(.leading, 38)
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: Copy

    private var copyBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("jaaw")
                .font(.system(size: 102, weight: .heavy))
                .tracking(-6.6)
                .lineSpacing(-18)
                .foregroundStyle(.white)
                .shadow(color: Color(red: 0, green: 0, blue: 90 / 255, opacity: 0.45), radius: 40, y: 8)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)

            Text("Your SRM Academia, finally beautiful.")
                .font(.system(size: 23, weight: .medium))
                .tracking(-0.5)
                .foregroundStyle(.white)
                .lineSpacing(2)
                .padding(.top, 20)
                .frame(maxWidth: 300, alignment: .leading)

            Text("Attendance, timetable, marks and calendar in one fast, native app. No more squinting at the portal.")
                .font(.system(size: 15))
                .lineSpacing(2)
                .foregroundStyle(JaawColors.muted)
                .padding(.top, 10)
                .frame(maxWidth: 310, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("jaaw. Your SRM Academia, finally beautiful. Attendance, timetable, marks and calendar in one fast, native app.")
    }

    // MARK: CTA

    private var loginButton: some View {
        Button {
            loginTapCount += 1
            onLogin()
        } label: {
            Text("Login with Academia")
                .font(.system(size: 17, weight: .heavy))
                .tracking(-0.2)
                .foregroundStyle(JaawColors.ctaTint)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(.white, in: Capsule())
        }
        .buttonStyle(JaawCTAStyle())
        .sensoryFeedback(.impact(weight: .medium), trigger: loginTapCount)
        .accessibilityHint("Signs you in with your SRM Academia account")
    }
}

// MARK: - Card contents

private struct CardEyebrow: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white.opacity(0.72))
    }
}

private struct AttendanceCardContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardEyebrow(text: "Attendance")
            Text("87%")
                .font(.system(size: 40, weight: .heavy))
                .tracking(-1.2)
                .foregroundStyle(.white)
                .padding(.top, 8)
            GeometryReader { proxy in
                Capsule()
                    .fill(.white.opacity(0.22))
                    .frame(height: 6)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(.white)
                            .frame(width: proxy.size.width * 0.78, height: 6)
                    }
            }
            .frame(height: 6)
            .padding(.top, 12)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Attendance 87 percent")
    }
}

private struct NextClassCardContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardEyebrow(text: "Next class · 10:00")
            Text("Machine Learning")
                .font(.system(size: 20, weight: .heavy))
                .tracking(-0.6)
                .foregroundStyle(.white)
                .lineSpacing(2)
                .padding(.top, 7)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next class at 10:00, Machine Learning")
    }
}

private struct MarksCardContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardEyebrow(text: "Internal marks")
            Text("46 / 50")
                .font(.system(size: 20, weight: .heavy))
                .tracking(-0.6)
                .foregroundStyle(.white)
                .padding(.top, 7)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Internal marks 46 out of 50")
    }
}

#Preview("Landing") {
    LandingView()
}
