import Foundation

// MARK: - jaaw API client
// The base URL is fixed; the app always talks to production.

enum JaawAPIError: LocalizedError, Equatable {
    case invalidCredentials(String)
    case serverUnreachable(String)
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials(let detail):
            return detail.isEmpty ? "Invalid NetID or password." : detail
        case .serverUnreachable(let detail):
            return detail.isEmpty ? "Academia servers unreachable. Please check your connection." : detail
        case .requestFailed(let detail):
            return detail.isEmpty ? "Login failed. Please try again." : detail
        }
    }
}

enum JaawAPI {
    static let baseURL = URL(string: "https://api.jaaw.tosh.cc.cd")!

    private struct LoginPayload: Encodable {
        var username: String
        var password: String
    }

    /// The error body the API returns: a human-readable `message`, with
    /// `detail` as the older field some endpoints still send.
    private struct ErrorBody: Decodable {
        var message: String?
        var detail: String?

        /// The most useful thing the server said, if it said anything.
        var bestMessage: String? {
            for candidate in [message, detail] {
                let text = candidate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !text.isEmpty { return text }
            }
            return nil
        }
    }

    /// POST /login with `{ username, password }`. Returns the full dashboard payload.
    static func login(username: String, password: String) async throws -> LoginResponse {
        let url = baseURL.appendingPathComponent("login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        request.httpBody = try JSONEncoder().encode(LoginPayload(username: username, password: password))

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw JaawAPIError.serverUnreachable("All API servers are unreachable. Please check your connection.")
        }

        guard let http = response as? HTTPURLResponse else {
            throw JaawAPIError.requestFailed("Unexpected server response.")
        }

        guard (200...299).contains(http.statusCode) else {
            let body = try? JSONDecoder().decode(ErrorBody.self, from: data)
            switch http.statusCode {
            case 400, 401, 422:
                // The server's own wording wins; the generic line is the
                // fallback when it says nothing.
                throw JaawAPIError.invalidCredentials(body?.bestMessage ?? "")
            case 502, 503, 504:
                throw JaawAPIError.serverUnreachable(body?.bestMessage ?? "")
            default:
                throw JaawAPIError.requestFailed(
                    body?.bestMessage ?? "HTTP \(http.statusCode)"
                )
            }
        }

        do {
            return try JSONDecoder().decode(LoginResponse.self, from: data)
        } catch {
            throw JaawAPIError.requestFailed("Could not read the server response.")
        }
    }
}
