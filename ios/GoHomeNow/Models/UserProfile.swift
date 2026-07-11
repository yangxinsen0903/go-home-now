import Foundation

struct MatchRequest: Codable {
    var homeType: String = "apartment"
    var monthlyBudget: Int = 250
    var activityLevel: String = "moderate"
    var experience: String = "first-time"
    var location: String? = nil
    var preferredSizes: [String] = []
    var preferredAge: String = "any"

    enum CodingKeys: String, CodingKey {
        case homeType = "home_type"
        case monthlyBudget = "monthly_budget"
        case activityLevel = "activity_level"
        case preferredSizes = "preferred_sizes"
        case preferredAge = "preferred_age"
        case experience, location
    }

    mutating func toggleSize(_ size: String) {
        if let idx = preferredSizes.firstIndex(of: size) {
            preferredSizes.remove(at: idx)
        } else {
            preferredSizes.append(size)
        }
    }
}
