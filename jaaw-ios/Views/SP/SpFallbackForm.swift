import SwiftUI
import UIKit

// MARK: - Student Portal fallback
//
// Shown on the Attendance/Marks tabs when Academia returns no rows.
//   GET  /sp/captcha · POST /sp/login · POST /sp/refresh

// MARK: View model

@Observable
final class SpFallbackViewModel {
    enum Phase: Equatable {
        case loading
        case ready
        case submitting
    }

    var netid = ""
    var password = ""
    var captcha = ""
    /// Raw image bytes once the captcha is fetched (decoded from the data URL).
    var captchaImageData: Data?
    var phase: Phase = .loading
    var errorMessage: String?
    /// Opaque token tying the solved captcha to this login attempt.
    var cdigest: String?

    private let store = SpSessionStore.shared

    var canSubmit: Bool {
        phase == .ready
            && !netid.trimmed.isEmpty
            && !password.isEmpty
            && !captcha.trimmed.isEmpty
            && cdigest != nil
    }

    var ctaTitle: String {
        phase == .submitting ? "Signing in…" : "Sign in"
    }

    /// Pre-fill saved credentials, reuse a saved SP session when possible,
    /// otherwise fetch a fresh captcha.
    func onAppear() async {
        if let saved = store.savedCredentials() {
            if netid.isEmpty { netid = saved.netid }
            if password.isEmpty { password = saved.password }
        }

        if store.hasCookies {
            do {
                let response = try await SpAPI.refresh(cookies: store.cookies)
                if !response.session.cookies.isEmpty {
                    store.saveCookies(response.session.cookies)
                }
                SessionStore.shared.applySpData(
                    attendance: response.attendance,
                    marks: response.marks
                )
                // Session valid but the portal genuinely has no rows: stay on
                // the form with a fresh captcha so the user can retry.
                if response.attendance.isEmpty && response.marks.isEmpty {
                    await loadCaptcha()
                }
                return
            } catch {
                store.clearCookies()
            }
        }

        await loadCaptcha()
    }

    /// Fetch a fresh captcha image + digest.
    func loadCaptcha() async {
        phase = .loading
        errorMessage = nil
        captcha = ""
        captchaImageData = nil
        cdigest = nil

        do {
            let response = try await SpAPI.captcha()
            captchaImageData = decodeCaptchaDataURL(response.image)
            cdigest = response.cdigest.isEmpty ? nil : response.cdigest
            if cdigest == nil, captchaImageData == nil {
                errorMessage = "Student Portal captcha is unavailable right now."
            }
            phase = .ready
        } catch {
            phase = .ready
            errorMessage = message(for: error)
        }
    }

    /// Submit the SP credentials + solved captcha.
    func submit() async {
        guard canSubmit, let cdigest else { return }
        phase = .submitting
        errorMessage = nil

        let cleanNetID = netid.trimmed
        store.saveCredentials(netid: cleanNetID, password: password)

        do {
            let response = try await SpAPI.login(
                netid: cleanNetID,
                password: password,
                captcha: captcha.trimmed,
                cdigest: cdigest
            )
            store.saveCookies(response.session.cookies)
            SessionStore.shared.applySpData(
                attendance: response.attendance,
                marks: response.marks
            )
            phase = .ready
        } catch {
            let message = message(for: error)
            await loadCaptcha()
            // loadCaptcha clears the error, so restore the failure last.
            errorMessage = message
            phase = .ready
        }
    }

    /// Decodes a `data:image/...;base64,...` URL into image bytes.
    func decodeCaptchaDataURL(_ url: String) -> Data? {
        guard let comma = url.firstIndex(of: ","),
              url[..<comma].contains("base64")
        else { return nil }
        return Data(base64Encoded: String(url[url.index(after: comma)...]))
    }

    private func message(for error: Error) -> String {
        if let spError = error as? SpAPIError {
            return spError.localizedDescription
        }
        return "Something went wrong. Please try again."
    }
}

// MARK: Form

struct SpFallbackForm: View {
    var kind: SpFallbackKind

    @State private var model = SpFallbackViewModel()
    @FocusState private var focused: Field?

    private enum Field: Hashable {
        case netid, password, captcha
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            fields
                .padding(.top, 22)
            if let error = model.errorMessage {
                errorRow(error)
                    .padding(.top, 16)
            }
            cta
                .padding(.top, 22)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HomeColors.card, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(HomeColors.cardBorder, lineWidth: 1)
        )
        .task { await model.onAppear() }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        colors: [HomeColors.nowStart, HomeColors.nowEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .shadow(color: HomeColors.glowPrimary.opacity(0.5), radius: 16, y: 6)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(kind.eyebrow)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(HomeColors.ringSecondary)
                Text(kind.heading)
                    .font(.system(size: 19, weight: .heavy))
                    .tracking(-0.4)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(kind.body)
                    .font(.system(size: 13))
                    .lineSpacing(2)
                    .foregroundStyle(HomeColors.secondaryText)
                    .padding(.top, 2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Fields

    private var fields: some View {
        VStack(spacing: 12) {
            netIDField
            secureField
            captchaField
        }
    }

    private var netIDField: some View {
        HStack(spacing: 12) {
            fieldIcon("person.fill")
            TextField("NetID", text: $model.netid)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .tint(.white)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.username)
                .focused($focused, equals: .netid)
                .submitLabel(.next)
                .onSubmit { focused = .password }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(fieldBackground(isFocused: focused == .netid))
    }

    private var secureField: some View {
        HStack(spacing: 12) {
            fieldIcon("lock.fill")
            SecureField("Password", text: $model.password)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .tint(.white)
                .textContentType(.password)
                .focused($focused, equals: .password)
                .submitLabel(.next)
                .onSubmit { focused = .captcha }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(fieldBackground(isFocused: focused == .password))
    }

    private var captchaField: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Captcha")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HomeColors.secondaryText)
                Spacer(minLength: 0)
                Button {
                    Task { await model.loadCaptcha() }
                } label: {
                    Label("New code", systemImage: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HomeColors.ringSecondary)
                }
                .disabled(model.phase == .submitting)
                .accessibilityHint("Loads a fresh captcha")
            }

            HStack(spacing: 12) {
                captchaImage
                HStack(spacing: 12) {
                    fieldIcon("text.cursor")
                    TextField("Enter the code", text: $model.captcha)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .tint(.white)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused, equals: .captcha)
                        .submitLabel(.go)
                        .onSubmit {
                            focused = nil
                            Task { await model.submit() }
                        }
                }
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(fieldBackground(isFocused: focused == .captcha))
            }
        }
    }

    private var captchaImage: some View {
        Button {
            Task { await model.loadCaptcha() }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                if let data = model.captchaImageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                } else if model.phase == .loading {
                    ProgressView().tint(.white)
                } else {
                    Text("Unavailable")
                        .font(.system(size: 11))
                        .foregroundStyle(HomeColors.faintText)
                }
            }
            .frame(width: 118, height: 54)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(HomeColors.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Captcha image. Tap to refresh.")
    }

    private func fieldIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(HomeColors.faintText)
            .frame(width: 20)
    }

    private func fieldBackground(isFocused: Bool) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isFocused ? HomeColors.ringSecondary.opacity(0.6) : HomeColors.cardBorder,
                        lineWidth: 1
                    )
            )
    }

    // MARK: Error + CTA

    private func errorRow(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: 0xE08080))
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: 0xE08080))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Student Portal error: \(message)")
    }

    private var cta: some View {
        Button {
            focused = nil
            Task { await model.submit() }
        } label: {
            HStack(spacing: 8) {
                if model.phase == .submitting {
                    ProgressView().tint(JaawColors.ctaTint)
                }
                Text(model.ctaTitle)
                    .font(.system(size: 16, weight: .heavy))
                    .tracking(-0.2)
            }
            .foregroundStyle(JaawColors.ctaTint)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(.white, in: Capsule())
        }
        .buttonStyle(JaawCTAStyle(isEnabled: model.canSubmit))
        .disabled(!model.canSubmit)
        .sensoryFeedback(.impact(weight: .medium), trigger: model.phase == .submitting)
        .accessibilityHint("Logs in with your Student Portal account")
    }
}

// MARK: - Unavailable card

/// Native empty/failure card used when Academia returns no rows.
struct SpUnavailableCard: View {
    var title: String
    var message: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: 0xE08080))
                .frame(width: 44, height: 44)
                .background(Color(hex: 0xE08080).opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .heavy))
                    .tracking(-0.3)
                    .foregroundStyle(.white)
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(HomeColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HomeColors.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(HomeColors.cardBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

#Preview("SP fallback") {
    ScrollView {
        VStack(spacing: 16) {
            SpUnavailableCard(
                title: "Attendance unavailable",
                message: "We couldn't get your attendance from Academia.",
                systemImage: "calendar.badge.exclamationmark"
            )
            SpFallbackForm(kind: .attendance)
        }
        .padding(18)
    }
    .background(HomeColors.page)
}
