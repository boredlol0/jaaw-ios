import Foundation

// MARK: - jaaw API client
// The base URL is fixed; the app always talks to production.

enum JaawAPIError: LocalizedError, Equatable {
    case invalidCredentials
    case serverUnreachable(String)
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid NetID or password."
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

    private struct ErrorBody: Decodable {
        var detail: String?
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
            let detail = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.detail
                ?? "HTTP \(http.statusCode)"
            switch http.statusCode {
            case 400, 401, 422:
                throw JaawAPIError.invalidCredentials
            case 502, 503, 504:
                throw JaawAPIError.serverUnreachable(detail)
            default:
                throw JaawAPIError.requestFailed(detail)
            }
        }

        do {
            return try JSONDecoder().decode(LoginResponse.self, from: data)
        } catch {
            throw JaawAPIError.requestFailed("Could not read the server response.")
        }
    }
}
