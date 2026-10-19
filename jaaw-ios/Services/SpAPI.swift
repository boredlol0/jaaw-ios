import Foundation

// MARK: - Student Portal (SP) API client
//
// Routes:
//   GET  /sp/captcha
//   POST /sp/login    { netid, password, captcha, cdigest }
//   POST /sp/refresh  { cookies }
//
// The bridge is a Cloudflare Worker at the same host as the Academia API,
// so all SP traffic goes to `JaawAPI.baseURL`.

enum SpAPIError: LocalizedError, Equatable {
    case wrongCaptcha
    case invalidCredentials
    case accountLocked(String)
    case captchaRequired(String)
    case sessionExpired(String)
    case serverUnreachable(String)
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .wrongCaptcha:
            return "Invalid captcha. Please try again."
        case .invalidCredentials:
            return "Invalid credentials. Please try again."
        case .accountLocked(let message):
            return message.isEmpty ? "This account is locked. Contact your administrator." : message
        case .captchaRequired(let message):
            return message.isEmpty ? "Captcha expired. Fetch a new captcha and try again." : message
        case .sessionExpired(let message):
            return message.isEmpty ? "Student Portal session expired. Log in again." : message
        case .serverUnreachable(let message):
            return message.isEmpty ? "Student Portal bridge is unreachable. Please check your connection." : message
        case .requestFailed(let message):
            return message.isEmpty ? "Something went wrong while logging in. Please try again." : message
        }
    }
}

enum SpAPI {
    private static var baseURL: URL { JaawAPI.baseURL }

    private struct LoginPayload: Encodable {
        var netid: String
        var password: String
        var captcha: String
        var cdigest: String
    }

    private struct RefreshPayload: Encodable {
        var cookies: [String: String]
    }

    // MARK: Routes

    /// GET /sp/captcha
    static func captcha() async throws -> SpCaptchaResponse {
        let url = baseURL.appendingPathComponent("sp/captcha")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        let data = try await perform(request, url: url)
        do {
            return try JSONDecoder().decode(SpCaptchaResponse.self, from: data)
        } catch {
            throw SpAPIError.requestFailed("Could not read the captcha response.")
        }
    }

    /// POST /sp/login
    static func login(netid: String, password: String, captcha: String, cdigest: String) async throws -> SpLoginResponse {
        let url = baseURL.appendingPathComponent("sp/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90
        request.httpBody = try JSONEncoder().encode(
            LoginPayload(netid: netid, password: password, captcha: captcha, cdigest: cdigest)
        )
        let data = try await perform(request, url: url)
        do {
            return try JSONDecoder().decode(SpLoginResponse.self, from: data)
        } catch {
            throw SpAPIError.requestFailed("Could not read the Student Portal response.")
        }
    }

    /// POST /sp/refresh
    static func refresh(cookies: [String: String]) async throws -> SpLoginResponse {
        let url = baseURL.appendingPathComponent("sp/refresh")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90
        request.httpBody = try JSONEncoder().encode(RefreshPayload(cookies: cookies))
        let data = try await perform(request, url: url)
        do {
            return try JSONDecoder().decode(SpLoginResponse.self, from: data)
        } catch {
            throw SpAPIError.requestFailed("Could not read the Student Portal response.")
        }
    }

    // MARK: Transport + errors

    private static func perform(_ request: URLRequest, url: URL) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw SpAPIError.serverUnreachable("Student Portal bridge is unreachable. Please check your connection.")
        }
        guard let http = response as? HTTPURLResponse else {
            throw SpAPIError.requestFailed("Unexpected server response.")
        }
        guard (200...299).contains(http.statusCode) else {
            throw mapError(status: http.statusCode, data: data)
        }
        return data
    }

    private static func mapError(status: Int, data: Data) -> SpAPIError {
        let envelope = try? JSONDecoder().decode(SpErrorEnvelope.self, from: data)
        let type = envelope?.detailObject?.type
        let message = envelope?.detailObject?.message ?? envelope?.detailString ?? ""

        switch type {
        case "WRONG_CAPTCHA":
            return .wrongCaptcha
        case "INVALID_CREDENTIALS":
            return .invalidCredentials
        case "ACCOUNT_LOCKED":
            return .accountLocked(message)
        case "CAPTCHA_REQUIRED":
            return .captchaRequired(message)
        case "SESSION_EXPIRED":
            return .sessionExpired(message)
        default:
            if !message.isEmpty { return .requestFailed(message) }
            if status == 401 { return .invalidCredentials }
            if status == 503 { return .serverUnreachable("") }
            return .requestFailed("")
        }
    }

    /// `detail` is either a plain string or an object `{ type, message }`.
    private struct SpErrorObject: Decodable {
        var type: String?
        var message: String?
    }

    private struct SpErrorEnvelope: Decodable {
        var detailString: String?
        var detailObject: SpErrorObject?

        enum CodingKeys: String, CodingKey { case detail }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let string = try? container.decode(String.self, forKey: .detail) {
                detailString = string
            } else if let object = try? container.decode(SpErrorObject.self, forKey: .detail) {
                detailObject = object
            }
        }
    }
}
