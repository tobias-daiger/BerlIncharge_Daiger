//
//  StationView.swift
//  BerlIncharge_Daiger
//
//  Created by Tobi on 24.10.25.
//

import SwiftUI

struct StationView: View {
    @State private var stations: [Station] = []
    @State private var searchText: String = ""

    private var filteredStations: [Station] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return stations }

        return stations.filter { station in
            let haystacks: [String] = [
                station.pointName,
                station.street,
                station.houseNumber,
                station.postalCode,
                station.status,
                station.powerType
            ]
            .map { $0.lowercased() }

            let needle = query.lowercased()
            return haystacks.contains(where: { $0.contains(needle) })
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredStations) { station in
                NavigationLink(value: station) {
                    HStack(spacing: 12) {
                        // Bild abhängig von pointName (alf/evb) oder powerType (AC/DC)
                        StationImagePlaceholder(pointName: station.pointName,
                                                powerType: station.powerType)
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(station.pointName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            Text("\(station.street) \(station.houseNumber), \(station.postalCode)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.circle")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(station.status)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(station.powerType)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                        .frame(minWidth: 0)
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Stationen")
            .navigationDestination(for: Station.self) { station in
                StationDetailView(station: station)
            }
            .searchable(text: $searchText,
                        placement: .navigationBarDrawer(displayMode: .automatic),
                        prompt: "Station, Straße, Status …")
            .onAppear {
                stations = StationLoader.load()
            }
        }
    }
}

// Bild-Auswahl:
// 1) pointName enthält "alf"  -> Asset "alf"
// 2) pointName enthält "evb"  -> Asset "evb"
// 3) sonst powerType DC -> "terra"
// 4) sonst AC -> "keba"
struct StationImagePlaceholder: View {
    let pointName: String
    let powerType: String

    private var normalizedName: String { pointName.lowercased() }
    private var isDC: Bool { powerType.lowercased().contains("dc") }

    private var assetName: String {
        if normalizedName.contains("alf") { return "alf" }
        if normalizedName.contains("evb") { return "evb" }
        return isDC ? "terra" : "keba"
    }

    var body: some View {
        ZStack {
            // Dezenter Hintergrund, damit bei "Fit" keine harten Kanten auffallen
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.secondarySystemBackground))

            if let uiImage = UIImage(named: assetName) {
                let image = Image(uiImage: uiImage).resizable()
                if isDC {
                    // DC -> terra standardmäßig Fit ohne Beschnitt
                    image
                        .scaledToFit()
                        .padding(4)
                } else {
                    // AC/alf/evb in der Liste dürfen ruhig füllen
                    image
                        .scaledToFill()
                }
            } else {
                // Fallback falls Asset fehlt
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.gray.opacity(0.15))
                    Image(systemName: "photo")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.gray)
                }
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .clipped()
    }
}

// Detailansicht
struct StationDetailView: View {
    let station: Station

    private var gridItems: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    private var isDC: Bool {
        station.powerType.lowercased().contains("dc")
    }

    private var assetName: String {
        let name = station.pointName.lowercased()
        if name.contains("alf") { return "alf" }
        if name.contains("evb") { return "evb" }
        return isDC ? "terra" : "keba"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header mit Bild (inkl. alf/evb)
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemBackground))

                    if let uiImage = UIImage(named: assetName) {
                        let image = Image(uiImage: uiImage).resizable()
                        if isDC {
                            image
                                .scaledToFit()
                                .padding(6)
                        } else {
                            // AC/alf/evb: komplett sichtbar, etwas Luft zum Rand
                            image
                                .scaledToFit()
                                .padding(.top, 8)
                                .padding(.horizontal, 6)
                                .padding(.bottom, 6)
                        }
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.gray)
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                // Linkes Overlay: Name und Adresse kleiner
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(station.pointName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text("\(station.street) \(station.houseNumber), \(station.postalCode)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                    .padding(8)
                }
                // Oben links: Leistung/Zugang kompakt in größerer Bubble
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.95))
                            Text(station.advertisedPower)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.98))
                                .monospacedDigit()
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "lock.open")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.95))
                            Text(station.publicAccess ? "Öffentlich" : "Nicht öffentlich")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.98))
                        }
                    }
                    .padding(.horizontal, 12)   // breiter
                    .padding(.vertical, 10)     // höher
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.black.opacity(0.55)) // etwas kräftiger, größer wirkt ruhiger
                    )
                    .padding(12) // mehr Abstand vom Rand
                }

                // 2x2 Grid mit Kästchen wie bei HomeView
                LazyVGrid(columns: gridItems, spacing: 12) {
                    StatBox(title: "Status", value: station.status, symbol: "bolt.circle")
                    StatBox(title: "Leistung beworben", value: station.advertisedPower, symbol: "bolt.fill")
                    StatBox(title: "Stromart", value: station.powerType, symbol: "powerplug.fill")
                    StatBox(title: "Zugang", value: station.publicAccess ? "Öffentlich" : "Nicht öffentlich", symbol: "lock.open")
                    StatBox(title: "Breitengrad", value: String(format: "%.6f", station.latitude), symbol: "mappin.and.ellipse")
                    StatBox(title: "Längengrad", value: String(format: "%.6f", station.longitude), symbol: "mappin.and.ellipse")
                }
            }
            .padding(16)
        }
        .navigationTitle(station.pointName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    StationView()
}
