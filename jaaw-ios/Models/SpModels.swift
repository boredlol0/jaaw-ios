import Foundation

// MARK: - Student Portal (SP) fallback models
// Used by the SP fallback screen when Academia returns no attendance/marks rows.

enum SpFallbackKind {
    case attendance
    case marks

    var eyebrow: String { "Student Portal" }

    var heading: String {
        switch self {
        case .attendance: return "Fetch attendance from the portal"
        case .marks: return "Fetch marks from the portal"
        }
    }

    var body: String {
        switch self {
        case .attendance:
            return "Academia didn't return any attendance rows. Sign in with your Student Portal account and we'll pull them straight from there."
        case .marks:
            return "Academia didn't return any mark rows. Sign in with your Student Portal account and we'll pull them straight from there."
        }
    }
}

struct SpCaptchaResponse: Codable {
    var success: Bool = false
    var cdigest: String = ""
    var image: String = ""   // data URL: "data:image/png;base64,..."
}

struct SpLoginResponse: Codable {
    var success: Bool = false
    var source: String = ""
    var attendance: [AttendanceRecord] = []
    var marks: [MarkRecord] = []
    var session: SessionPayload = SessionPayload()
}

/// Payload for `/sp/login` and `/sp/refresh`.
struct SpPayload: Encodable {
    var netid: String?
    var password: String?
    var captcha: String?
    var cdigest: String?
    var cookies: [String: String]?
}
