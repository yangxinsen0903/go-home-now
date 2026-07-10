import SwiftUI

struct DogDetailView: View {
    let dog: Dog
    @State private var showShelterSheet = false
    @State private var showAdoptedConfirm = false
    @State private var showCarePlan = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Photo carousel
                PhotoCarousel(photos: dog.photos, fallbackUrl: dog.imageUrl)

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dog.name).font(.largeTitle).bold()
                        Text("\(dog.breed) • \(dog.age) yr\(dog.age == 1 ? "" : "s") • \(dog.size.capitalized)")
                            .foregroundStyle(.secondary)
                        Text(dog.shelter).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let score = dog.fitScore {
                        VStack {
                            Text("\(score)%").font(.title).bold()
                                .foregroundStyle(score >= 85 ? .green : score >= 70 ? .orange : .red)
                            Text("GoHome Fit").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Basic info grid
                InfoGrid(dog: dog)

                // Behavior section
                SectionCard(title: "Behavior") {
                    VStack(alignment: .leading, spacing: 8) {
                        FactRow(label: "House-trained", value: dog.houseTrained)
                        if let g = dog.goodWith {
                            FactRow(label: "Gets Along With", value: g)
                        } else {
                            FactRow(label: "Gets Along With", value: nil)
                        }
                    }
                }

                // Health section
                SectionCard(title: "Health") {
                    VStack(alignment: .leading, spacing: 8) {
                        FactRow(label: "Sex", value: dog.sex)
                        FactRow(label: "Spayed/Neutered", value: dog.neutered)
                        FactRow(label: "Vaccinated", value: dog.vaccinated)
                        if let w = dog.weightLbs {
                            FactRow(label: "Weight", value: "~\(w) lbs")
                        } else {
                            FactRow(label: "Weight", value: nil)
                        }
                    }
                }

                // Behavior notes (cleaned)
                if !dog.behaviorNotes.isEmpty {
                    SectionCard(title: "About \(dog.name)") {
                        Text(dog.behaviorNotes).font(.body)
                    }
                }

                // Risk flags
                if !dog.riskFlags.isEmpty {
                    SectionCard(title: "Things to Know") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(dog.riskFlags, id: \.self) { flag in
                                Label(flag, systemImage: "exclamationmark.triangle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }

                // 90-day plan preview (locked until adopted)
                SectionCard(title: "90-Day Care Plan Preview") {
                    VStack(alignment: .leading, spacing: 10) {
                        CarePlanRow(day: "Day 0–7", text: "Home setup, supplies, vet visit (within \(dog.firstVetDays) days), decompression")
                        CarePlanRow(day: "Week 2–4", text: dog.trainingPlan)
                        CarePlanRow(day: "Day 30", text: "Progress check-in, training adjustment")
                        CarePlanRow(day: "Day 90", text: "Adoption success review, long-term care plan")
                    }
                    .opacity(0.5)
                    HStack {
                        Image(systemName: "lock.fill").foregroundStyle(.secondary)
                        Text("Complete your adoption to unlock your personal plan")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }

                // Primary CTA: contact shelter
                Button(action: { showShelterSheet = true }) {
                    Label("I Want to Adopt \(dog.name)", systemImage: "heart.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Secondary CTA: already adopted
                Button(action: { showAdoptedConfirm = true }) {
                    Text("I've Already Adopted \(dog.name) →")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                .padding(.bottom, 8)
            }
            .padding()
        }
        .navigationTitle(dog.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShelterSheet) {
            ShelterContactSheet(dog: dog, onAdopted: {
                showShelterSheet = false
                showCarePlan = true
            })
        }
        .alert("Congratulations! 🎉", isPresented: $showAdoptedConfirm) {
            Button("Build My 90-Day Plan") { showCarePlan = true }
            Button("Not Yet", role: .cancel) {}
        } message: {
            Text("Did you complete the adoption of \(dog.name)?")
        }
        .sheet(isPresented: $showCarePlan) {
            CarePlanView(dog: dog)
        }
    }

    private var dogPlaceholder: some View {
        ZStack {
            Color(.systemGray5)
            Image(systemName: "pawprint.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color(.systemGray3))
        }
    }
}

struct PhotoCarousel: View {
    let photos: [String]
    let fallbackUrl: String?

    private var urls: [URL] {
        let all = photos.isEmpty ? [fallbackUrl].compactMap { $0 } : photos
        return all.prefix(6).compactMap { URL(string: $0) }
    }

    @State private var currentIndex = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            if urls.isEmpty {
                placeholder
            } else if urls.count == 1 {
                photoView(url: urls[0])
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                        photoView(url: url).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 300)

                // Dot indicators
                HStack(spacing: 6) {
                    ForEach(0..<urls.count, id: \.self) { i in
                        Circle()
                            .fill(i == currentIndex ? Color.white : Color.white.opacity(0.45))
                            .frame(width: i == currentIndex ? 8 : 6, height: i == currentIndex ? 8 : 6)
                    }
                }
                .padding(.bottom, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func photoView(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                placeholder
            default:
                placeholder.overlay(ProgressView())
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .clipped()
    }

    private var placeholder: some View {
        ZStack {
            Color(.systemGray5)
            Image(systemName: "pawprint.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color(.systemGray3))
        }
    }
}

struct InfoGrid: View {
    let dog: Dog
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            InfoTile(icon: "calendar", label: "Age", value: dog.age == 0 ? "< 1 yr" : "\(dog.age) yr\(dog.age == 1 ? "" : "s")")
            InfoTile(icon: "scalemass", label: "Size", value: dog.size.capitalized)
            InfoTile(icon: "figure.run", label: "Energy", value: dog.energyLevel.capitalized)
            InfoTile(icon: "building.2", label: "City", value: dog.city.uppercased())
        }
    }
}

struct InfoTile: View {
    let icon: String
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.title2).foregroundStyle(Color.accentColor)
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            content
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct FactRow: View {
    let label: String
    let value: String?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if let v = value {
                Image(systemName: v == "Yes" ? "checkmark.circle.fill" : v == "No" ? "xmark.circle.fill" : "questionmark.circle.fill")
                    .foregroundStyle(v == "Yes" ? .green : v == "No" ? .red : .secondary)
            } else {
                Image(systemName: "questionmark.circle.fill").foregroundStyle(.secondary)
            }
            Text(label).font(.subheadline).foregroundStyle(.secondary).frame(width: 130, alignment: .leading)
            Text(value ?? "Unknown").font(.subheadline)
                .foregroundStyle(value == nil ? .secondary : .primary)
        }
    }
}

struct CarePlanRow: View {
    let day: String
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(day).font(.caption).bold().foregroundStyle(Color.accentColor)
            Text(text).font(.subheadline)
        }
    }
}

struct ShelterContactSheet: View {
    let dog: Dog
    let onAdopted: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.accentColor)
                    Text("Contact the Shelter")
                        .font(.title2).bold()
                    Text(dog.shelter)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 12) {
                    Label("Search \"\(dog.shelter)\" online to find their phone number, address, and hours.", systemImage: "magnifyingglass")
                        .font(.subheadline)
                    Label("Ask to schedule a meet & greet with \(dog.name).", systemImage: "calendar")
                        .font(.subheadline)
                    Label("Complete the adoption application at the shelter.", systemImage: "doc.text.fill")
                        .font(.subheadline)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Spacer()

                VStack(spacing: 12) {
                    Text("Completed your adoption?")
                        .font(.subheadline).foregroundStyle(.secondary)

                    Button(action: onAdopted) {
                        Label("I've Adopted \(dog.name)! 🎉", systemImage: "checkmark.seal.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button("Not Yet — I'll Come Back Later") { dismiss() }
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationTitle("Adopt \(dog.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct CarePlanView: View {
    let dog: Dog
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.green)
                        Text("Welcome home, \(dog.name)!")
                            .font(.title2).bold()
                        Text("Here's your personalized 90-day plan.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)

                    SectionCard(title: "Your 90-Day Plan") {
                        VStack(alignment: .leading, spacing: 14) {
                            CarePlanRow(day: "Day 0–7", text: "Home setup, buy supplies, vet visit within \(dog.firstVetDays) days, decompression — let \(dog.name) settle in at their own pace.")
                            CarePlanRow(day: "Week 2–4", text: dog.trainingPlan)
                            CarePlanRow(day: "Day 30", text: "First progress check-in — adjust training and routine as needed.")
                            CarePlanRow(day: "Day 60", text: "Mid-point review — health check, bonding assessment.")
                            CarePlanRow(day: "Day 90", text: "Adoption success review — celebrate and plan long-term care.")
                        }
                    }

                    SectionCard(title: "Estimated Monthly Cost") {
                        HStack {
                            Text("~$\(dog.monthlyCost)/month")
                                .font(.title3).bold()
                            Spacer()
                            Text("food, vet, supplies")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("90-Day Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
