import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = "http://187.124.95.189:8020"

    private let tokenKey = "authToken"

    var authToken: String? {
        get { KeychainHelper.read(tokenKey) }
        set {
            if let value = newValue {
                KeychainHelper.save(value, for: tokenKey)
            } else {
                KeychainHelper.delete(tokenKey)
            }
        }
    }

    // MARK: - Auth

    private struct SignupBody: Encodable { let email: String; let password: String; let name: String? }
    private struct LoginBody: Encodable { let email: String; let password: String }

    func signup(email: String, password: String, name: String?) async throws -> AuthResponse {
        try await post("/api/auth/signup", body: SignupBody(email: email, password: password, name: name), authorized: false)
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        try await post("/api/auth/login", body: LoginBody(email: email, password: password), authorized: false)
    }

    func fetchMe() async throws -> AccountInfo {
        try await get("/api/auth/me", authorized: true)
    }

    // MARK: - Profile

    func fetchProfile() async throws -> ServerProfile? {
        let url = URL(string: "\(baseURL)/api/profile/")!
        let req = authorizedRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: req)
        try throwIfError(data: data, response: response)
        if data.isEmpty || data == Data("null".utf8) { return nil }
        return try JSONDecoder().decode(ServerProfile.self, from: data)
    }

    func saveProfile(_ profile: ServerProfile) async throws -> ServerProfile {
        try await put("/api/profile/", body: profile, authorized: true)
    }

    // MARK: - Matches / Dogs

    func fetchMatches(request: MatchRequest) async throws -> [Dog] {
        try await post("/api/matches/", body: request, authorized: false)
    }

    func fetchDogs(city: String? = nil) async throws -> [Dog] {
        var urlString = "\(baseURL)/api/dogs/"
        if let city {
            urlString += "?city=\(city)"
        }
        let url = URL(string: urlString)!
        let (data, response) = try await URLSession.shared.data(from: url)
        try throwIfError(data: data, response: response)
        return try JSONDecoder().decode([Dog].self, from: data)
    }

    func fetchDog(id: Int) async throws -> Dog {
        let url = URL(string: "\(baseURL)/api/dogs/\(id)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try throwIfError(data: data, response: response)
        return try JSONDecoder().decode(Dog.self, from: data)
    }

    // MARK: - Generic helpers

    private func authorizedRequest(url: URL, method: String) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    private func throwIfError(data: Data, response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) else { return }
        if let detail = try? JSONDecoder().decode([String: String].self, from: data), let message = detail["detail"] {
            throw APIError.server(message)
        }
        throw APIError.server("Request failed (\(http.statusCode))")
    }

    private func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body, authorized: Bool) async throws -> Response {
        var req = authorizedRequest(url: URL(string: "\(baseURL)\(path)")!, method: "POST")
        if !authorized { req.setValue(nil, forHTTPHeaderField: "Authorization") }
        req.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: req)
        try throwIfError(data: data, response: response)
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private func put<Body: Encodable, Response: Decodable>(_ path: String, body: Body, authorized: Bool) async throws -> Response {
        var req = authorizedRequest(url: URL(string: "\(baseURL)\(path)")!, method: "PUT")
        if !authorized { req.setValue(nil, forHTTPHeaderField: "Authorization") }
        req.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: req)
        try throwIfError(data: data, response: response)
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private func get<Response: Decodable>(_ path: String, authorized: Bool) async throws -> Response {
        let req = authorizedRequest(url: URL(string: "\(baseURL)\(path)")!, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: req)
        try throwIfError(data: data, response: response)
        return try JSONDecoder().decode(Response.self, from: data)
    }
}
