import SwiftUI

struct DogDetailView: View {
    let dog: Dog

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

                // Care stats
                InfoGrid(dog: dog)

                // Behavior notes
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

                // 90-day plan
                SectionCard(title: "90-Day Care Plan") {
                    VStack(alignment: .leading, spacing: 10) {
                        CarePlanRow(day: "Day 0–7", text: "Home setup, supplies, vet visit (within \(dog.firstVetDays) days), decompression")
                        CarePlanRow(day: "Week 2–4", text: dog.trainingPlan)
                        CarePlanRow(day: "Day 30", text: "Progress check-in, training adjustment")
                        CarePlanRow(day: "Day 90", text: "Adoption success review, long-term care plan")
                    }
                }

                Button(action: {}) {
                    Label("Build My 90-Day Plan", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
        }
        .navigationTitle(dog.name)
        .navigationBarTitleDisplayMode(.inline)
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
            InfoTile(icon: "dollarsign.circle", label: "Monthly", value: "$\(dog.monthlyCost)")
            InfoTile(icon: "stethoscope", label: "First Vet", value: "Day \(dog.firstVetDays)")
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
