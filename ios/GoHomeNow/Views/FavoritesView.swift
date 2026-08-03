import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        NavigationStack {
            Group {
                if vm.favorites.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart")
                            .font(.system(size: 52))
                            .foregroundStyle(.secondary)
                        Text("No favorites yet")
                            .font(.title3).bold()
                        Text("Tap the heart on any dog to save it here for quick access.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(vm.favorites) { dog in
                        NavigationLink(destination: DogDetailView(dog: dog)) {
                            DogCardView(dog: dog)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Favorites")
        }
    }
}
