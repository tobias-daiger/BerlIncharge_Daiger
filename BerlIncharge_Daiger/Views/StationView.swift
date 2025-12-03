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
            let container: [String] = [
                station.pointName,
                station.street,
                station.houseNumber,
                station.postalCode,
                station.status,
                station.powerType
            ]
            .map { $0.lowercased() }

            let item = query.lowercased()
            return container.contains(where: { $0.contains(item) })
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredStations) { station in
                NavigationLink(value: station) {
                    HStack(spacing: 12) {
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
                                Image(systemName: "bolt.badge.checkmark")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(station.status)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "ev.charger.arrowtriangle.right.fill")
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
                        placement: .automatic,
                        prompt: "Seriennummer...")
            .onAppear {
                stations = StationLoader.load()
            }
        }
    }
}

struct StationDetailView: View {
    let station: Station

    private var gridItems: [GridItem] { Calc.twoColumnGridItems() }
    private var isDC: Bool { Calc.isDC(powerType: station.powerType) }
    private var assetName: String { Calc.assetName(pointName: station.pointName, powerType: station.powerType) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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
                            image
                                .scaledToFit()
                                .padding(.top, 8)
                                .padding(.horizontal, 6)
                                .padding(.bottom, 6)
                        }
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.black.opacity(0.55))
                    )
                    .padding(12)
                }

                LazyVGrid(columns: gridItems, spacing: 12) {
                    StatBox("Status", station.status, "bolt.circle")
                    StatBox("Leistung beworben", station.advertisedPower, "bolt.fill")
                    StatBox("Stromart", station.powerType, "powerplug.fill")
                    StatBox("Zugang", station.publicAccess ? "Öffentlich" : "Nicht öffentlich", "lock.open")
                    StatBox("Breitengrad", String(format: "%.6f", station.latitude), "mappin.and.ellipse")
                    StatBox("Längengrad", String(format: "%.6f", station.longitude), "mappin.and.ellipse")
                }
            }
            .padding(16)
        }
        .navigationTitle(station.pointName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
