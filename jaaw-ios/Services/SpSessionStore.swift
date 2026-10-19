import Foundation

// MARK: - Student Portal (SP) fallback session
//
// The SP session cookies plus the user's NetID/password, so they only have to
// solve a fresh captcha next time.
//
// Cookies and credentials persist across an Academia logout, so signing out of
// the main app does not force another captcha solve.

@Observable
final class SpSessionStore {
    static let shared = SpSessionStore()

    private static let storageKey = "jaaw.sp.v1"

    private struct Persisted: Codable {
        var netid: String
        var cookies: [String: String]
        var cachedAt: Date
    }

    /// NetID without the domain (e.g. "ab1234").
    var netid: String = ""
    /// Student Portal session cookies, once a login succeeds.
    var cookies: [String: String] = [:]

    private init() {
        restore()
    }

    var hasCookies: Bool { !cookies.isEmpty }

    /// Saved credentials for pre-filling the form (password lives in Keychain).
    func savedCredentials() -> (netid: String, password: String)? {
        let password = KeychainHelper.loadPassword(account: KeychainHelper.spAccount) ?? ""
        guard !netid.isEmpty || !password.isEmpty else { return nil }
        return (netid, password)
    }

    func saveCredentials(netid: String, password: String) {
        self.netid = netid
        KeychainHelper.savePassword(password, account: KeychainHelper.spAccount)
        persist()
    }

    func saveCookies(_ cookies: [String: String]) {
        self.cookies = cookies
        persist()
    }

    /// Drop only the session; stored credentials stay so they can be pre-filled.
    func clearCookies() {
        cookies = [:]
        persist()
    }

    func clearAll() {
        netid = ""
        cookies = [:]
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
        KeychainHelper.deletePassword(account: KeychainHelper.spAccount)
    }

    // MARK: - Disk

    private func persist() {
        let persisted = Persisted(netid: netid, cookies: cookies, cachedAt: Date())
        if let data = try? JSONEncoder().encode(persisted) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private func restore() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let persisted = try? JSONDecoder().decode(Persisted.self, from: data)
        else { return }
        netid = persisted.netid
        cookies = persisted.cookies
    }
}
