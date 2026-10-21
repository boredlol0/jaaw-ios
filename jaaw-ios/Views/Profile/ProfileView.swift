import SwiftUI
import ActivityKit

// MARK: - Profile page
// Pushed from the home page's avatar: the student's details on a card, with
// the way out at the foot. More rows will land here over time.

struct ProfileView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session = SessionStore.shared
    @State private var drift = false
    @State private var isConfirmingLogout = false
    @AppStorage(LiveClassActivityController.enabledKey) private var liveActivitiesEnabled = true
    @State private var activitiesAllowed = ActivityAuthorizationInfo().areActivitiesEnabled

    private var profile: UserProfile { session.profile }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                identityCard
                detailsCard
                    .padding(.top, 14)
                liveActivityCard
                    .padding(.top, 14)
                logoutButton
                    .padding(.top, 18)
                lastSynced
                    .padding(.top, 16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background { backdrop }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(.white)
        .confirmationDialog(
            "Log out of jaaw?",
            isPresented: $isConfirmingLogout,
            titleVisibility: .visible
        ) {
            Button("Log out", role: .destructive) { session.logout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll need your NetID and password to sign back in.")
        }
        .onAppear {
            // The tab behind keeps its own backdrop; this page runs its own.
            TabActivity.shared.isDetailPresented = true
            activitiesAllowed = ActivityAuthorizationInfo().areActivitiesEnabled
            guard !reduceMotion else { return }
            drift = true
        }
        .onDisappear {
            TabActivity.shared.isDetailPresented = false
        }
    }

    private var backdrop: some View {
        JaawTabBackdrop(
            configuration: JaawBackground.profile,
            drift: drift,
            reduceMotion: reduceMotion
        )
    }

    // MARK: - Identity

    private var identityCard: some View {
        HStack(alignment: .center, spacing: 16) {
            avatar
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.system(size: 21, weight: .heavy))
                    .tracking(-0.6)
                    .foregroundStyle(CardPalette.title)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 13.5))
                        .foregroundStyle(CardPalette.body)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !profile.registrationNumber.isEmpty {
                    Text(profile.registrationNumber)
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(0.4)
                        .foregroundStyle(CardPalette.accentInk)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(CardPalette.fill)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(CardPalette.border, lineWidth: 1)
                )
                .shadow(color: CardPalette.shadow, radius: 26, y: 12)
        }
    }

    private var avatar: some View {
        Text(initial)
            .font(.system(size: 24, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: 58, height: 58)
            .background {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [HomeColors.nowStart, HomeColors.nowEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: HomeColors.glowPrimary.opacity(0.45), radius: 14, y: 6)
            .accessibilityHidden(true)
    }

    // MARK: - Details

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if detailRows.isEmpty {
                Text("No profile details yet — sign in again to refresh them.")
                    .font(.system(size: 14))
                    .foregroundStyle(CardPalette.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 16)
            } else {
                ForEach(Array(detailRows.enumerated()), id: \.offset) { index, row in
                    if index > 0 {
                        Rectangle()
                            .fill(CardPalette.divider)
                            .frame(height: 1)
                    }
                    HStack(alignment: .top, spacing: 12) {
                        Text(row.label.uppercased())
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(1.1)
                            .foregroundStyle(CardPalette.muted)
                            .frame(width: 132, alignment: .leading)
                            .padding(.top, 2)
                        Text(row.value)
                            .font(.system(size: 14.5, weight: .semibold))
                            .foregroundStyle(CardPalette.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 13)
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(CardPalette.fill)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(CardPalette.border, lineWidth: 1)
                )
                .shadow(color: CardPalette.shadow, radius: 26, y: 12)
        }
    }

    /// Only the fields the portal actually sent.
    private var detailRows: [(label: String, value: String)] {
        var rows: [(String, String)] = []
        if !session.username.isEmpty { rows.append(("Net ID", session.username)) }
        if !profile.registrationNumber.isEmpty {
            rows.append(("Registration number", profile.registrationNumber))
        }
        if !profile.program.isEmpty { rows.append(("Programme", profile.program)) }
        if !profile.department.isEmpty { rows.append(("Department", profile.department)) }
        if !profile.semester.isEmpty { rows.append(("Semester", profile.semester)) }
        if !profile.batch.isEmpty { rows.append(("Batch", profile.batch)) }
        if !profile.section.isEmpty { rows.append(("Section", profile.section)) }
        if !profile.mobileNumber.isEmpty { rows.append(("Mobile", profile.mobileNumber)) }
        return rows
    }

    // MARK: - Live activities

    /// The switch for the lock screen activity. iOS starts these on their own
    /// once the app has asked for them, so the student never has to open jaaw
    /// mid-class.
    private var liveActivityCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle(isOn: $liveActivitiesEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "waveform.path.ecg.rectangle")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(CardPalette.accentInk)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(CardPalette.accent.opacity(0.12)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Live Activities")
                            .font(.system(size: 14.5, weight: .semibold))
                            .foregroundStyle(CardPalette.title)
                        Text("Put the running class on your lock screen.")
                            .font(.system(size: 12))
                            .foregroundStyle(CardPalette.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .tint(CardPalette.accent)
            .onChange(of: liveActivitiesEnabled) { _, enabled in
                Task { await LiveClassActivityController.shared.setEnabled(enabled) }
            }

            if !activitiesAllowed {
                Rectangle()
                    .fill(CardPalette.divider)
                    .frame(height: 1)
                    .padding(.vertical, 12)
                Text("Live Activities are switched off for jaaw in iOS Settings.")
                    .font(.system(size: 12))
                    .foregroundStyle(CardPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(CardPalette.fill)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(CardPalette.border, lineWidth: 1)
                )
                .shadow(color: CardPalette.shadow, radius: 26, y: 12)
        }
    }

    // MARK: - Log out

    private var logoutButton: some View {
        Button {
            isConfirmingLogout = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .bold))
                Text("Log out")
                    .font(.system(size: 16, weight: .bold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: 0xE0403C))
                    .shadow(color: Color(hex: 0xE0403C).opacity(0.35), radius: 18, y: 8)
            }
        }
        .buttonStyle(PressScaleStyle(scale: 0.97))
        .accessibilityLabel("Log out")
    }

    private var lastSynced: some View {
        Group {
            if let cachedAt = session.cachedAt {
                Text("Last synced \(cachedAtLabel(cachedAt))")
                    .font(.system(size: 12))
                    .foregroundStyle(JaawColors.ice.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func cachedAtLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM yyyy, h:mm a"
        fmt.locale = Locale(identifier: "en_US")
        return fmt.string(from: date)
    }

    // MARK: - Values

    private var initial: String {
        profile.name.first.map { String($0).uppercased() } ?? "J"
    }

    private var displayName: String {
        let name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Your profile" : name
    }

    private var subtitle: String {
        var parts: [String] = []
        if !profile.program.isEmpty { parts.append(profile.program) }
        if !profile.semester.isEmpty { parts.append("Semester \(profile.semester)") }
        if !profile.batch.isEmpty { parts.append("Batch \(profile.batch)") }
        return parts.joined(separator: " · ")
    }
}

#Preview("Profile") {
    NavigationStack {
        ProfileView()
    }
}
