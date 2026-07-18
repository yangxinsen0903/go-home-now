import SwiftUI

private let sizeChoices: [(id: String, label: String)] = [
    ("small", "Small"), ("medium", "Medium"), ("large", "Large"),
]

// MARK: - OnboardingView

struct OnboardingView: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Home") {
                    Picker("Home type", selection: $vm.profile.homeType) {
                        Text("Apartment").tag("apartment")
                        Text("House").tag("house")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Activity Level") {
                    Picker("Schedule", selection: $vm.profile.activityLevel) {
                        Text("Low").tag("low")
                        Text("Moderate").tag("moderate")
                        Text("High").tag("high")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Monthly Dog Budget: $\(vm.profile.monthlyBudget)") {
                    Slider(
                        value: Binding(
                            get: { Double(vm.profile.monthlyBudget) },
                            set: { vm.profile.monthlyBudget = Int($0) }
                        ),
                        in: 100...500, step: 25
                    )
                }

                Section("Owner Experience") {
                    Picker("Experience", selection: $vm.profile.experience) {
                        Text("First-time").tag("first-time")
                        Text("Some").tag("some")
                        Text("Experienced").tag("experienced")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Dog Size") {
                    Text("Select all you're open to — leave blank for any")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 10) {
                        ForEach(sizeChoices, id: \.id) { choice in
                            let selected = vm.profile.preferredSizes.contains(choice.id)
                            Button(action: { vm.profile.toggleSize(choice.id) }) {
                                Text(choice.label)
                                    .font(.subheadline).fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selected ? Color.accentColor : Color(.systemGray5))
                                    .foregroundStyle(selected ? Color.white : Color.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Age Preference") {
                    Picker("Age", selection: $vm.profile.preferredAge) {
                        Text("Any").tag("any")
                        Text("Puppy (< 1 yr)").tag("puppy")
                        Text("Adult (1+ yr)").tag("adult")
                    }
                    .pickerStyle(.segmented)
                }

                Section("City") {
                    Picker("Location", selection: Binding(
                        get: { vm.profile.location ?? "all" },
                        set: { vm.profile.location = $0 == "all" ? nil : $0 }
                    )) {
                        Text("All cities").tag("all")
                        Text("DMV Area").tag("dc")
                        Text("New York City").tag("nyc")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Find Your Dog")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("See Matches") {
                        vm.onboardingDone = true
                        Task { await vm.fetchMatches() }
                    }
                }
            }
        }
    }
}
