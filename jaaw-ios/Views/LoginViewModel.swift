import Foundation

@Observable
final class LoginViewModel {
    var netID = ""
    var password = ""
    var isPasswordVisible = false
    var isLoggingIn = false

    var sanitizedNetID: String {
        netID
            .components(separatedBy: "@").first?
            .filter { !$0.isWhitespace } ?? ""
    }

    var isFormValid: Bool {
        sanitizedNetID.count >= 2 && !password.isEmpty && !isLoggingIn
    }

    var ctaTitle: String {
        isLoggingIn ? "Logging in…" : "Login"
    }

    /// Called on NetID change to keep the stored value clean.
    func netIDChanged(_ newValue: String) {
        let clean = newValue
            .components(separatedBy: "@").first?
            .filter { !$0.isWhitespace } ?? ""
        netID = String(clean.prefix(12))
    }

    /// Placeholder sign-in used until real auth lands. Returns true on success.
    func login() async -> Bool {
        guard !isLoggingIn else { return false }
        guard sanitizedNetID.count >= 2, !password.isEmpty else { return false }
        isLoggingIn = true
        defer { isLoggingIn = false }
        try? await Task.sleep(for: .milliseconds(1600))
        guard !Task.isCancelled else { return false }
        return true
    }
}
