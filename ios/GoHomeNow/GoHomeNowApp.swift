import SwiftUI

@main
struct GoHomeNowApp: App {
    @StateObject private var vm = AppViewModel()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if vm.onboardingDone {
                    RootTabView().environmentObject(vm)
                } else {
                    OnboardingView().environmentObject(vm)
                }

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    withAnimation(.easeOut(duration: 0.3)) { showSplash = false }
                }
            }
        }
    }
}
