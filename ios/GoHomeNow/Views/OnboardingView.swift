import SwiftUI

private struct SizeOption {
    let id: String
    let label: String
    // Stretch dog.fill to different aspect ratios: wide+short = dachshund, square = medium, tall = large breed
    let iconWidth: CGFloat
    let iconHeight: CGFloat
    let tileHeight: CGFloat
}

private let sizeOptions: [SizeOption] = [
    SizeOption(id: "small",  label: "Small",  iconWidth: 54, iconHeight: 22, tileHeight: 84),
    SizeOption(id: "medium", label: "Medium", iconWidth: 38, iconHeight: 36, tileHeight: 104),
    SizeOption(id: "large",  label: "Large",  iconWidth: 28, iconHeight: 52, tileHeight: 128),
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
                        Text("Select all sizes you're open to — leave blank for any")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        // Bottom-aligned stepped tiles; dog.fill stretched to different aspect ratios
                        // wide+short = dachshund, square = medium, tall = large breed
                        HStack(alignment: .bottom, spacing: 10) {
                            ForEach(sizeOptions, id: \.id) { opt in
                                let selected = vm.profile.preferredSizes.contains(opt.id)
                                Button(action: { vm.profile.toggleSize(opt.id) }) {
                                    VStack(spacing: 0) {
                                        Spacer(minLength: 0)
                                        Image(systemName: "dog.fill")
                                            .resizable()
                                            .frame(width: opt.iconWidth, height: opt.iconHeight)
                                            .foregroundStyle(selected ? Color.white : Color.accentColor)
                                        Text(opt.label)
                                            .font(.caption).fontWeight(.semibold)
                                            .foregroundStyle(selected ? Color.white : Color.primary)
                                            .padding(.top, 8)
                                            .padding(.bottom, 12)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: opt.tileHeight)
                                    .background(selected ? Color.accentColor : Color(.systemGray5))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
