import Foundation

@MainActor
class AppViewModel: ObservableObject {
    @Published var dogs: [Dog] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var profile = MatchRequest()
    @Published var onboardingDone = false
    @Published var isAuthenticated: Bool
    @Published var accountEmail: String?
    @Published var accountName: String?
    @Published var authError: String?
    @Published var isAuthenticating = false
    @Published private(set) var favorites: [Dog] = [] {
        didSet { saveFavorites() }
    }

    private let favoritesKey = "favoriteDogs"

    init() {
        isAuthenticated = APIService.shared.authToken != nil
        loadFavorites()
    }

    func restoreSession() async {
        guard isAuthenticated else { return }
        do {
            let me = try await APIService.shared.fetchMe()
            accountEmail = me.email
            accountName = me.name
            if let serverProfile = try await APIService.shared.fetchProfile() {
                profile = MatchRequest(
                    homeType: serverProfile.homeType,
                    monthlyBudget: serverProfile.monthlyBudget,
                    activityLevel: serverProfile.activityLevel,
                    experience: serverProfile.experience,
                    location: serverProfile.location,
                    preferredSizes: serverProfile.preferredSizes ?? [],
                    preferredAge: serverProfile.preferredAge ?? "any"
                )
                onboardingDone = true
                await fetchMatches()
            } else {
                onboardingDone = false
            }
        } catch {
            logout()
        }
    }

    func signup(email: String, password: String, name: String?) async {
        isAuthenticating = true
        authError = nil
        do {
            let auth = try await APIService.shared.signup(email: email, password: password, name: name)
            APIService.shared.authToken = auth.token
            accountEmail = auth.email
            accountName = auth.name
            isAuthenticated = true
        } catch {
            authError = (error as? APIError)?.errorDescription ?? "Something went wrong. Please try again."
        }
        isAuthenticating = false
    }

    func login(email: String, password: String) async {
        isAuthenticating = true
        authError = nil
        do {
            let auth = try await APIService.shared.login(email: email, password: password)
            APIService.shared.authToken = auth.token
            accountEmail = auth.email
            accountName = auth.name
            isAuthenticated = true
            await restoreSession()
        } catch {
            authError = (error as? APIError)?.errorDescription ?? "Invalid email or password."
        }
        isAuthenticating = false
    }

    func logout() {
        APIService.shared.authToken = nil
        isAuthenticated = false
        onboardingDone = false
        accountEmail = nil
        accountName = nil
        dogs = []
        profile = MatchRequest()
    }

    func completeOnboarding() async {
        onboardingDone = true
        let serverProfile = ServerProfile(
            homeType: profile.homeType,
            monthlyBudget: profile.monthlyBudget,
            activityLevel: profile.activityLevel,
            experience: profile.experience,
            location: profile.location,
            preferredSizes: profile.preferredSizes,
            preferredAge: profile.preferredAge
        )
        _ = try? await APIService.shared.saveProfile(serverProfile)
        await fetchMatches()
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
