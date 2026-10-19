import Foundation

// MARK: - Persisted session
// Credentials + the full dashboard payload, so a login survives restarts and
// the home screen renders instantly from cache.

@Observable
final class SessionStore {
    static let shared = SessionStore()

    private static let storageKey = "jaaw.session.v1"

    private struct PersistedSession: Codable {
        var username: String
        var cookies: [String: String]
        var profile: UserProfile
        var attendance: [AttendanceRecord]
        var marks: [MarkRecord]
        var schedule: [ScheduleDay]
        var courses: [CourseCatalogEntry]
        var calendar: AcademicCalendar
        var cachedAt: Date
    }

    /// NetID without the domain (e.g. "ab1234").
    var username: String = ""
    var cookies: [String: String] = [:]
    var profile: UserProfile = UserProfile()
    var attendance: [AttendanceRecord] = []
    var marks: [MarkRecord] = []
    var schedule: [ScheduleDay] = []
    var courses: [CourseCatalogEntry] = []
    var calendar: AcademicCalendar = AcademicCalendar()
    var cachedAt: Date?

    var isLoggedIn = false
    /// True once the on-disk session has been checked, so the router can
    /// decide between landing and home without flashing.
    var hasCheckedStoredSession = false

    private init() {}

    /// Full email-style username used by the API.
    var apiUsername: String {
        username.contains("@") ? username : "\(username)@srmist.edu.in"
    }

    // MARK: - Save / restore

    func save(loginResponse: LoginResponse, username: String, password: String) {
        let clean = username.components(separatedBy: "@").first ?? username
        self.username = clean
        self.cookies = loginResponse.session.cookies
        self.profile = loginResponse.profile
        self.attendance = loginResponse.attendance
        self.marks = loginResponse.marks
        self.schedule = loginResponse.schedule
        self.courses = loginResponse.courses
        self.calendar = loginResponse.calendar
        self.cachedAt = Date()

        persist()
        KeychainHelper.savePassword(password)
        isLoggedIn = true
    }

    /// Merge Attendance/Marks fetched via the Student Portal fallback and
    /// re-persist, so the tabs (and next launch) see the SP data.
    func applySpData(attendance: [AttendanceRecord], marks: [MarkRecord]) {
        self.attendance = attendance
        self.marks = marks
        self.cachedAt = Date()
        persist()
    }

    private func persist() {
        let persisted = PersistedSession(
            username: username,
            cookies: cookies,
            profile: profile,
            attendance: attendance,
            marks: marks,
            schedule: schedule,
            courses: courses,
            calendar: calendar,
            cachedAt: cachedAt ?? Date()
        )
        if let data = try? JSONEncoder().encode(persisted) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    /// Loads the saved session if one exists. Call once at launch.
    @discardableResult
    func restore() -> Bool {
        defer { hasCheckedStoredSession = true }
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let persisted = try? JSONDecoder().decode(PersistedSession.self, from: data),
              !persisted.username.isEmpty,
              KeychainHelper.loadPassword() != nil
        else {
            isLoggedIn = false
            return false
        }
        username = persisted.username
        cookies = persisted.cookies
        profile = persisted.profile
        attendance = persisted.attendance
        marks = persisted.marks
        schedule = persisted.schedule
        courses = persisted.courses
        calendar = persisted.calendar
        cachedAt = persisted.cachedAt
        isLoggedIn = true
        return true
    }

    func logout() {
        username = ""
        cookies = [:]
        profile = UserProfile()
        attendance = []
        marks = []
        schedule = []
        courses = []
        calendar = AcademicCalendar()
        cachedAt = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
        KeychainHelper.deletePassword()
    }
}
