import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = "http://100.99.145.120:8020"

    func fetchMatches(request: MatchRequest) async throws -> [Dog] {
        let url = URL(string: "\(baseURL)/api/matches/")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(request)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode([Dog].self, from: data)
    }

    func fetchDog(id: Int) async throws -> Dog {
        let url = URL(string: "\(baseURL)/api/dogs/\(id)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Dog.self, from: data)
    }
}
