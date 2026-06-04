import Foundation

@MainActor
class AppViewModel: ObservableObject {
    @Published var dogs: [Dog] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var profile = MatchRequest()
    @Published var onboardingDone = false

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
}
