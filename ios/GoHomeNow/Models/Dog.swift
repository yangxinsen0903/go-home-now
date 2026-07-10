import Foundation

struct Dog: Codable, Identifiable {
    let id: Int
    let name: String
    let age: Int
    let breed: String
    let size: String
    let energyLevel: String
    let temperament: String
    let shelter: String
    let city: String
    let monthlyCost: Int
    let firstVetDays: Int
    let trainingPlan: String
    let riskFlags: [String]
    let behaviorNotes: String
    let imageUrl: String?
    var photos: [String]
    let sex: String?
    let weightLbs: Int?
    let goodWith: String?
    let neutered: String?
    let vaccinated: String?
    let houseTrained: String?
    var fitScore: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, age, breed, size, temperament, shelter, city, photos, sex, neutered, vaccinated
        case energyLevel = "energy_level"
        case monthlyCost = "monthly_cost"
        case firstVetDays = "first_vet_days"
        case trainingPlan = "training_plan"
        case riskFlags = "risk_flags"
        case behaviorNotes = "behavior_notes"
        case imageUrl = "image_url"
        case weightLbs = "weight_lbs"
        case goodWith = "good_with"
        case houseTrained = "house_trained"
        case fitScore = "fit_score"
    }

    var fitScoreDisplay: String {
        guard let score = fitScore else { return "--" }
        return "\(score)%"
    }

    var fitScoreColor: String {
        guard let score = fitScore else { return "gray" }
        if score >= 85 { return "green" }
        if score >= 70 { return "orange" }
        return "red"
    }
}
