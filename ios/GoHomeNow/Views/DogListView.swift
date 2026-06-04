import SwiftUI

struct DogListView: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Finding your matches…")
                } else if let error = vm.errorMessage {
                    VStack(spacing: 12) {
                        Text(error).foregroundStyle(.secondary)
                        Button("Retry") { Task { await vm.fetchMatches() } }
                    }
                } else {
                    List(vm.dogs) { dog in
                        NavigationLink(destination: DogDetailView(dog: dog)) {
                            DogCardView(dog: dog)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Your Matches")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Edit Profile") { vm.onboardingDone = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await vm.fetchMatches() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

struct DogCardView: View {
    let dog: Dog

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color(.systemGray5)).frame(width: 56, height: 56)
                Text(dog.name.prefix(1)).font(.title2).bold()
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(dog.name).font(.headline)
                    Spacer()
                    FitBadge(score: dog.fitScore ?? 0)
                }
                Text("\(dog.temperament) • \(dog.age) yr\(dog.age == 1 ? "" : "s") • \(dog.shelter)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text("$\(dog.monthlyCost)/mo").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FitBadge: View {
    let score: Int

    var color: Color {
        if score >= 85 { return .green }
        if score >= 70 { return .orange }
        return .red
    }

    var body: some View {
        Text("\(score)%")
            .font(.caption).bold()
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
