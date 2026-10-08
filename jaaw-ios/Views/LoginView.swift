import SwiftUI

/// Login screen.
///
/// The status bar, Dynamic Island and home indicator come from the system.
/// Routing is injected via closures so the view stays decoupled from
/// `ContentView`'s `NavigationStack`.
struct LoginView: View {
    var onBack: () -> Void = {}
    /// Called after a successful sign-in; the router decides what "home" is.
    var onAuthenticated: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedField: Field?
    @State private var viewModel = LoginViewModel()
    @State private var drift = false

    private enum Field: Hashable {
        case netID, password
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                JaawBackground(
                    configuration: JaawBackground.login,
                    drift: drift,
                    reduceMotion: reduceMotion
                )

                ScrollView {
                    VStack(spacing: 0) {
                        backButton
                        header
                        Spacer(minLength: 32)
                        formPanel
                        ctaButton
                            .padding(.top, 20)
                            .padding(.horizontal, 8)
                        Spacer(minLength: 16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    // Floor so short content still pins the panel and CTA
                    // toward the bottom of the screen.
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height - 60, alignment: .top)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .background(JaawColors.deep)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            guard !reduceMotion else { return }
            drift = true
        }
        .onChange(of: viewModel.netID) { _, newValue in
            viewModel.netIDChanged(newValue)
        }
    }

    // MARK: - Back (`.back`)

    private var backButton: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.16), in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(JaawCTAStyle())
            .accessibilityLabel("Back")
            Spacer(minLength: 0)
        }
        .padding(.leading, 6)
        .padding(.top, 8)
    }

    // MARK: - Header (`.head`)

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Log in to Academia")
                .font(.system(size: 60, weight: .heavy))
                .tracking(-3.3) // ≈ −0.055em at 60pt
                .lineSpacing(0)
                .foregroundStyle(.white)
                .shadow(color: Color(red: 0, green: 0, blue: 90 / 255, opacity: 0.45), radius: 40, y: 8)
                .minimumScaleFactor(0.6)
                .accessibilityAddTraits(.isHeader)

            Text("Use the NetID and password you sign in to SRM Academia with.")
                .font(.system(size: 16))
                .lineSpacing(2)
                .foregroundStyle(JaawColors.muted)
                .padding(.top, 16)
                .frame(maxWidth: 290, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.top, 24)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Form panel (`.panel`)

    private var formPanel: some View {
        GlassPanel(cornerRadius: 34) {
            VStack(alignment: .leading, spacing: 0) {
                fieldLabel("NetID")
                netIDField
                fieldLabel("Password")
                    .padding(.top, 16)
                passwordField
            }
            .padding(20)
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color(red: 235 / 255, green: 239 / 255, blue: 1, opacity: 0.85))
            .padding(.leading, 4)
            .padding(.bottom, 8)
    }

    private var netIDField: some View {
        HStack(spacing: 2) {
            TextField("ab1234", text: $viewModel.netID)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
                .tint(.white)
                .focused($focusedField, equals: .netID)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.username)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
                .accessibilityLabel("NetID")

            Text("@srmist.edu.in")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(JaawColors.ice.opacity(0.62))
                .lineLimit(1)
                .layoutPriority(1)
                .accessibilityHidden(true)
        }
        .padding(.leading, 18)
        .padding(.trailing, 14)
        .frame(height: 58)
        .background(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .fill(focusedField == .netID ? JaawColors.fieldFillFocused : JaawColors.fieldFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .strokeBorder(.white.opacity(focusedField == .netID ? 0.75 : 0.2), lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.2), value: focusedField)
    }

    private var passwordField: some View {
        HStack(spacing: 0) {
            Group {
                if viewModel.isPasswordVisible {
                    TextField("Your password", text: $viewModel.password)
                } else {
                    SecureField("Your password", text: $viewModel.password)
                }
            }
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(.white)
            .tint(.white)
            .focused($focusedField, equals: .password)
            .textContentType(.password)
            .submitLabel(.go)
            .onSubmit { Task { await submit() } }
            .accessibilityLabel("Password")

            Button {
                viewModel.isPasswordVisible.toggle()
            } label: {
                Image(systemName: viewModel.isPasswordVisible ? "eye.slash" : "eye")
                    .font(.system(size: 17))
                    .foregroundStyle(viewModel.isPasswordVisible ? .white : JaawColors.ice.opacity(0.75))
                    .frame(width: 52, height: 58)
            }
            .accessibilityLabel(viewModel.isPasswordVisible ? "Hide password" : "Show password")
        }
        .padding(.leading, 18)
        .frame(height: 58)
        .background(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .fill(focusedField == .password ? JaawColors.fieldFillFocused : JaawColors.fieldFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .strokeBorder(.white.opacity(focusedField == .password ? 0.75 : 0.2), lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.2), value: focusedField)
    }

    // MARK: - CTA

    private var ctaButton: some View {
        Button {
            Task { await submit() }
        } label: {
            Text(viewModel.ctaTitle)
                .font(.system(size: 17, weight: .heavy))
                .tracking(-0.2)
                .foregroundStyle(JaawColors.ctaTint)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(.white, in: Capsule())
        }
        .buttonStyle(JaawCTAStyle(isEnabled: viewModel.isFormValid))
        .disabled(!viewModel.isFormValid)
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.isLoggingIn)
        .accessibilityHint("Logs in with your SRM Academia account")
    }

    private func submit() async {
        focusedField = nil
        let ok = await viewModel.login()
        if ok { onAuthenticated() }
    }
}

#Preview("Login") {
    NavigationStack {
        LoginView()
    }
}
