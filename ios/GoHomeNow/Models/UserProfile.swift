import Foundation

struct MatchRequest: Codable {
    var homeType: String = "apartment"
    var monthlyBudget: Int = 250
    var activityLevel: String = "moderate"
    var experience: String = "first-time"
    var location: String? = nil

    enum CodingKeys: String, CodingKey {
        case homeType = "home_type"
        case monthlyBudget = "monthly_budget"
        case activityLevel = "activity_level"
        case experience, location
    }
}
