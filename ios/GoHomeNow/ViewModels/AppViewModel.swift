import Foundation

@MainActor
class AppViewModel: ObservableObject {
    @Published var dogs: [Dog] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var profile = MatchRequest()
    @Published var onboardingDone = false
    @Published private(set) var favorites: [Dog] = [] {
        didSet { saveFavorites() }
    }

    private let favoritesKey = "favoriteDogs"

    init() {
        loadFavorites()
    }

    func fetchMatches() async {
        isLoading = true
        errorMessage = nil
        do {
            dogs = try await APIService.shared.fetchMatches(request: profile)
        } catch {
            errorMessage = "Could not load matches. Check your connection."
        }
        isLoading = false
    }

    func isFavorite(_ dog: Dog) -> Bool {
        favorites.contains { $0.id == dog.id }
    }

    func toggleFavorite(_ dog: Dog) {
        if let idx = favorites.firstIndex(where: { $0.id == dog.id }) {
            favorites.remove(at: idx)
        } else {
            favorites.append(dog)
        }
    }

    private func saveFavorites() {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        UserDefaults.standard.set(data, forKey: favoritesKey)
    }

    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey),
              let saved = try? JSONDecoder().decode([Dog].self, from: data) else { return }
        favorites = saved
    }
}
