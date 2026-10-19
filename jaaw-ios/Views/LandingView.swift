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
            JaawVideoBackdrop(
                resource: JaawEntryVideo.landing,
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
            // One flexible band above the CTA; the copy centres inside it, so it
            // lands around the vertical middle instead of hugging the top.
            copyBlock
                .frame(maxHeight: .infinity, alignment: .center)

            loginButton

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

    // MARK: Copy

    private var copyBlock: some View {
        VStack(alignment: .center, spacing: 0) {
            Text(" jaaw ")
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
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .lineSpacing(2)
                .padding(.top, 20)
                .frame(maxWidth: 300)

            Text("Attendance, timetable, marks and calendar in one fast, native app. No more squinting at the portal.")
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .foregroundStyle(JaawColors.muted)
                .padding(.top, 10)
                .frame(maxWidth: 310)
        }
        .frame(maxWidth: .infinity)
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

#Preview("Landing") {
    LandingView()
}
