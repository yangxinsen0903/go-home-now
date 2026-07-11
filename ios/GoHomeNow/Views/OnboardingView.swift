import SwiftUI

// MARK: - Dog breed silhouettes drawn with Canvas (monochrome, tintable)

private struct SmallDogSilhouette: View {
    var color: Color
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            func ellipse(_ r: CGRect) { ctx.fill(Path(ellipseIn: r), with: .color(color)) }
            func rRect(_ r: CGRect) {
                var p = Path()
                p.addRoundedRect(in: r, cornerSize: CGSize(width: 3, height: 3))
                ctx.fill(p, with: .color(color))
            }
            // Dachshund: extremely elongated low body
            ellipse(CGRect(x: w*0.02, y: h*0.24, width: w*0.73, height: h*0.40))
            // Head (overlaps right end of body)
            ellipse(CGRect(x: w*0.67, y: h*0.04, width: w*0.25, height: h*0.36))
            // Snout extends right
            ellipse(CGRect(x: w*0.83, y: h*0.22, width: w*0.17, height: h*0.18))
            // Long drooping ear
            ellipse(CGRect(x: w*0.68, y: h*0.34, width: w*0.10, height: h*0.28))
            // 4 very short legs (start inside body to connect)
            for x: CGFloat in [0.07, 0.20, 0.39, 0.52] {
                rRect(CGRect(x: w*x, y: h*0.52, width: w*0.10, height: h*0.40))
            }
            // Short curled tail at left
            ellipse(CGRect(x: w*0.00, y: h*0.10, width: w*0.09, height: h*0.22))
        }
    }
}

private struct MediumDogSilhouette: View {
    var color: Color
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            func ellipse(_ r: CGRect) { ctx.fill(Path(ellipseIn: r), with: .color(color)) }
            func rRect(_ r: CGRect) {
                var p = Path()
                p.addRoundedRect(in: r, cornerSize: CGSize(width: 3, height: 3))
                ctx.fill(p, with: .color(color))
            }
            // Beagle: compact body
            ellipse(CGRect(x: w*0.08, y: h*0.32, width: w*0.66, height: h*0.34))
            // Neck (overlaps body + head)
            ellipse(CGRect(x: w*0.61, y: h*0.20, width: w*0.22, height: h*0.24))
            // Head (round)
            ellipse(CGRect(x: w*0.58, y: h*0.02, width: w*0.34, height: h*0.30))
            // Snout
            ellipse(CGRect(x: w*0.80, y: h*0.18, width: w*0.20, height: h*0.18))
            // Floppy ear (droops from head side)
            ellipse(CGRect(x: w*0.56, y: h*0.22, width: w*0.12, height: h*0.30))
            // 4 medium legs
            for x: CGFloat in [0.12, 0.27, 0.47, 0.61] {
                rRect(CGRect(x: w*x, y: h*0.58, width: w*0.12, height: h*0.36))
            }
            // Tail curves up at left
            ellipse(CGRect(x: w*0.02, y: h*0.10, width: w*0.10, height: h*0.28))
        }
    }
}

private struct LargeDogSilhouette: View {
    var color: Color
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            func ellipse(_ r: CGRect) { ctx.fill(Path(ellipseIn: r), with: .color(color)) }
            func rRect(_ r: CGRect) {
                var p = Path()
                p.addRoundedRect(in: r, cornerSize: CGSize(width: 3, height: 3))
                ctx.fill(p, with: .color(color))
            }
            // Labrador: larger body
            ellipse(CGRect(x: w*0.06, y: h*0.28, width: w*0.68, height: h*0.36))
            // Thick neck
            ellipse(CGRect(x: w*0.60, y: h*0.14, width: w*0.25, height: h*0.26))
            // Large broad head
            ellipse(CGRect(x: w*0.56, y: h*0.00, width: w*0.40, height: h*0.28))
            // Snout (wider / blockier)
            ellipse(CGRect(x: w*0.80, y: h*0.15, width: w*0.20, height: h*0.22))
            // Moderate ear
            ellipse(CGRect(x: w*0.55, y: h*0.18, width: w*0.12, height: h*0.26))
            // 4 long legs
            for x: CGFloat in [0.10, 0.26, 0.48, 0.64] {
                rRect(CGRect(x: w*x, y: h*0.60, width: w*0.13, height: h*0.40))
            }
            // Prominent tail at left, pointing up
            ellipse(CGRect(x: w*0.00, y: h*0.06, width: w*0.10, height: h*0.30))
        }
    }
}

// MARK: - Size options

private struct SizeOption {
    let id: String
    let label: String
    let iconWidth: CGFloat
    let iconHeight: CGFloat
    let tileHeight: CGFloat
}

private let sizeOptions: [SizeOption] = [
    SizeOption(id: "small",  label: "Small",  iconWidth: 70, iconHeight: 28, tileHeight: 84),
    SizeOption(id: "medium", label: "Medium", iconWidth: 52, iconHeight: 44, tileHeight: 104),
    SizeOption(id: "large",  label: "Large",  iconWidth: 46, iconHeight: 62, tileHeight: 128),
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

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dog Size")
                            .font(.headline)
                        Text("Select all sizes you're open to — leave blank for any")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(alignment: .bottom, spacing: 10) {
                            ForEach(sizeOptions, id: \.id) { opt in
                                let selected = vm.profile.preferredSizes.contains(opt.id)
                                let iconColor: Color = selected ? .white : .accentColor
                                Button(action: { vm.profile.toggleSize(opt.id) }) {
                                    VStack(spacing: 0) {
                                        Spacer(minLength: 0)
                                        dogSilhouette(opt.id, color: iconColor)
                                            .frame(width: opt.iconWidth, height: opt.iconHeight)
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

    @ViewBuilder
    private func dogSilhouette(_ id: String, color: Color) -> some View {
        switch id {
        case "small": SmallDogSilhouette(color: color)
        case "large": LargeDogSilhouette(color: color)
        default:      MediumDogSilhouette(color: color)
        }
    }
}
