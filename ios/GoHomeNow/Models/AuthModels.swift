import Foundation

struct AuthResponse: Codable {
    let token: String
    let email: String
    let name: String?
}

struct AccountInfo: Codable {
    let email: String
    let name: String?
}

struct ServerProfile: Codable {
    var homeType: String
    var monthlyBudget: Int
    var activityLevel: String
    var experience: String
    var location: String?
    var preferredSizes: [String]?
    var preferredAge: String?

    enum CodingKeys: String, CodingKey {
        case homeType = "home_type"
        case monthlyBudget = "monthly_budget"
        case activityLevel = "activity_level"
        case preferredSizes = "preferred_sizes"
        case preferredAge = "preferred_age"
        case experience, location
    }
}

enum APIError: LocalizedError {
    case server(String)

    var errorDescription: String? {
        switch self {
        case .server(let message): return message
        }
    }
}
