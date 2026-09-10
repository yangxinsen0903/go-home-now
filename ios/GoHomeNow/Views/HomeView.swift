import SwiftUI

struct HomeView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var nearbyDogs: [Dog] = []
    @State private var rescueDogs: [Dog] = []
    @State private var isLoadingCarousels = false

    private var greetingName: String {
        if let name = vm.accountName, !name.isEmpty { return name }
        if let email = vm.accountEmail, let prefix = email.split(separator: "@").first { return String(prefix) }
        return "there"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Hi \(greetingName) \u{1F44B}")
                        .font(.largeTitle).bold()
                        .padding(.top, 8)

                    matchCard
                    trainingPlanCard
                    dogSection(title: "New pets near you", dogs: nearbyDogs)
                    dogSection(title: "Rescue dogs to meet", dogs: rescueDogs)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadCarousels() }
            .refreshable { await loadCarousels() }
        }
    }

    private var matchCard: some View {
        NavigationLink(destination: MatchResultsView()) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Matches").font(.headline).foregroundStyle(.white)
                    Text(matchSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.white)
            }
            .padding(18)
            .background(Color.brandPurple)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private var matchSubtitle: String {
        guard !vm.dogs.isEmpty else { return "See Your Match" }
        let top = vm.dogs.first?.fitScoreDisplay ?? "--"
        return "\(vm.dogs.count) dogs matched • top fit \(top)"
    }

    private var trainingPlanCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text("Your 90-Day Training Plan").font(.headline)
                Text("Unlocks once you confirm an adoption")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func dogSection(title: String, dogs: [Dog]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            if isLoadingCarousels && dogs.isEmpty {
                ProgressView().frame(maxWidth: .infinity, minHeight: 140)
            } else if dogs.isEmpty {
                Text("Nothing to show right now.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(dogs) { dog in
                            NavigationLink(destination: DogDetailView(dog: dog)) {
                                DogCarouselCard(dog: dog)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func loadCarousels() async {
        isLoadingCarousels = true
        let all: [Dog] = (try? await APIService.shared.fetchDogs()) ?? []

        var nearbyPool = all
        if let city = vm.profile.location {
            nearbyPool = all.filter { $0.city == city }
        }
        nearbyPool.sort { $0.id > $1.id }
        nearbyDogs = Array(nearbyPool.prefix(10))

        let shuffledPool = all.shuffled()
        rescueDogs = Array(shuffledPool.prefix(10))

        isLoadingCarousels = false
    }
}

private struct DogCarouselCard: View {
    let dog: Dog

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let urlStr = dog.imageUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Color(.systemGray5)
                        }
                    }
                } else {
                    Color(.systemGray5)
                }
            }
            .frame(width: 140, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text(dog.name)
                .font(.subheadline).bold()
                .foregroundStyle(.primary)
            Text("\(dog.age) yr\(dog.age == 1 ? "" : "s") • \(dog.breed)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 140)
    }
}
