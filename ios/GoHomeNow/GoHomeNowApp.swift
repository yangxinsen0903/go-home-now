import SwiftUI

@main
struct GoHomeNowApp: App {
    @StateObject private var vm = AppViewModel()

    var body: some Scene {
        WindowGroup {
            if vm.onboardingDone {
                DogListView().environmentObject(vm)
            } else {
                OnboardingView().environmentObject(vm)
            }
        }
    }
}
