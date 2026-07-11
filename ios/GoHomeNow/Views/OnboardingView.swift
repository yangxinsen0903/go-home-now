import SwiftUI

private let sizeOptions: [(id: String, label: String, hint: String)] = [
    ("toy",    "Toy",     "e.g. Chihuahua"),
    ("small",  "Small",   "e.g. Beagle"),
    ("medium", "Medium",  "e.g. Border Collie"),
    ("large",  "Large",   "e.g. Labrador"),
    ("xlarge", "X-Large", "e.g. Great Dane"),
]

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

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dog Size")
                            .font(.headline)
                        Text("Select all sizes you're open to — leave blank for any size")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 8
                        ) {
                            ForEach(sizeOptions, id: \.id) { opt in
                                Button(action: { vm.profile.toggleSize(opt.id) }) {
                                    VStack(spacing: 2) {
                                        Text(opt.label)
                                            .font(.subheadline).fontWeight(.semibold)
                                        Text(opt.hint)
                                            .font(.caption2)
                                            .foregroundStyle(
                                                vm.profile.preferredSizes.contains(opt.id) ? Color.white.opacity(0.8) : Color.secondary
                                            )
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        vm.profile.preferredSizes.contains(opt.id)
                                        ? Color.accentColor
                                        : Color(.systemGray5)
                                    )
                                    .foregroundStyle(
                                        vm.profile.preferredSizes.contains(opt.id)
                                        ? Color.white
                                        : Color.primary
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)
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
                        Text("Washington D.C.").tag("dc")
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
