import SwiftUI

struct AccountView: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Adoption Preferences") {
                    LabeledContent("Home Type", value: vm.profile.homeType.capitalized)
                    LabeledContent("Monthly Budget", value: "$\(vm.profile.monthlyBudget)")
                    LabeledContent("Activity Level", value: vm.profile.activityLevel.capitalized)
                    LabeledContent("Experience", value: vm.profile.experience.capitalized)
                    LabeledContent("Preferred Age", value: vm.profile.preferredAge.capitalized)
                    if !vm.profile.preferredSizes.isEmpty {
                        LabeledContent("Preferred Sizes", value: vm.profile.preferredSizes.map { $0.capitalized }.joined(separator: ", "))
                    }
                    if let location = vm.profile.location, !location.isEmpty {
                        LabeledContent("Location", value: location)
                    }
                }

                Section {
                    Button("Edit Preferences") { vm.onboardingDone = false }
                } footer: {
                    Text("These preferences power your GoHome Fit matches. Keeping them current helps us find dogs that fit your life.")
                }
            }
            .navigationTitle("Account")
        }
    }
}
