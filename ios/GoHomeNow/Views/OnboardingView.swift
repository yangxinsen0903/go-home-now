import SwiftUI

private struct SizeOption {
    let id: String
    let label: String
    let emoji: String
    let emojiSize: CGFloat
    let tileHeight: CGFloat
}

private let sizeOptions: [SizeOption] = [
    SizeOption(id: "small",  label: "Small",  emoji: "\u{1F429}", emojiSize: 28, tileHeight: 84),
    SizeOption(id: "medium", label: "Medium", emoji: "\u{1F415}", emojiSize: 40, tileHeight: 104),
    SizeOption(id: "large",  label: "Large",  emoji: "\u{1F9AE}", emojiSize: 56, tileHeight: 128),
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
                        // Bottom-aligned tiles of increasing height, each with a distinct dog emoji
                        HStack(alignment: .bottom, spacing: 10) {
                            ForEach(sizeOptions, id: \.id) { opt in
                                let selected = vm.profile.preferredSizes.contains(opt.id)
                                Button(action: { vm.profile.toggleSize(opt.id) }) {
                                    ZStack(alignment: .topTrailing) {
                                        VStack(spacing: 0) {
                                            Spacer(minLength: 0)
                                            Text(opt.emoji)
                                                .font(.system(size: opt.emojiSize))
                                            Text(opt.label)
                                                .font(.caption).fontWeight(.semibold)
                                                .foregroundStyle(Color.primary)
                                                .padding(.top, 6)
                                                .padding(.bottom, 10)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: opt.tileHeight)
                                        .background(selected ? Color.accentColor.opacity(0.12) : Color(.systemGray5))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selected ? Color.accentColor : Color.clear, lineWidth: 2.5)
                                        )
                                        if selected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundStyle(Color.accentColor)
                                                .background(Color(.systemBackground).clipShape(Circle()))
                                                .padding(6)
                                        }
                                    }
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
