import SwiftUI

enum AppTab: CaseIterable {
    case home, favorites, account

    var title: String {
        switch self {
        case .home: return "Home"
        case .favorites: return "Favorites"
        case .account: return "Account"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .favorites: return "heart.fill"
        case .account: return "person.fill"
        }
    }
}

struct RootTabView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home: DogListView()
                case .favorites: FavoritesView()
                case .account: AccountView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct FloatingTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabBarButton(tab: tab, isSelected: selectedTab == tab) {
                    withAnimation(.easeOut(duration: 0.2)) { selectedTab = tab }
                }
            }
        }
        .padding(6)
        .background(Capsule().fill(Color.black.opacity(0.85)))
        .frame(maxWidth: .infinity)
    }
}

private struct TabBarButton: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            content
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var content: some View {
        HStack(spacing: 6) {
            Image(systemName: tab.icon)
            if isSelected {
                Text(tab.title).font(.subheadline).bold()
            }
        }
        .foregroundStyle(isSelected ? Color.brandPurple : .white)
        .padding(.vertical, 12)
        .padding(.horizontal, isSelected ? 16 : 14)
        .background(background)
    }

    @ViewBuilder
    private var background: some View {
        if isSelected {
            Capsule().fill(Color.white)
        } else {
            Capsule().fill(Color.clear)
        }
    }
}
