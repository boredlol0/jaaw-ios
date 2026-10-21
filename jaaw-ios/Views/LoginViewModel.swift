import Foundation

@Observable
final class LoginViewModel {
    var netID = ""
    var password = ""
    var isPasswordVisible = false
    var isLoggingIn = false
    var errorMessage: String?

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

    /// Real sign-in: POST /login, then persist the session. Returns true on success.
    func login() async -> Bool {
        guard !isLoggingIn else { return false }
        let username = sanitizedNetID
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard username.count >= 2, !trimmedPassword.isEmpty else { return false }
        isLoggingIn = true
        errorMessage = nil
        defer { isLoggingIn = false }
        do {
            let response = try await JaawAPI.login(
                username: "\(username)@srmist.edu.in",
                password: trimmedPassword
            )
            guard response.success else {
                errorMessage = Self.message(from: response.message)
                    ?? "Login failed. Please try again."
                return false
            }
            SessionStore.shared.save(loginResponse: response, username: username, password: trimmedPassword)
            return true
        } catch let apiError as JaawAPIError {
            errorMessage = apiError.localizedDescription
            return false
        } catch {
            errorMessage = "Network error. Please check your connection."
            return false
        }
    }

    /// The server's own wording, when it sent one.
    private static func message(from raw: String?) -> String? {
        let text = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? nil : text
    }
}
