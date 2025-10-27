//
//  HomeView.swift
//  BerlIncharge_Daiger
//
//  Created by Tobi on 24.10.25.
//

import SwiftUI

struct HomeView: View {
    @State private var cars: [Car] = []

    var body: some View {
        NavigationStack {
            List(cars) { car in
                NavigationLink(value: car) {
                    HStack(spacing: 12) {
                        // Platzhalter-Bild: zeigt Systembild, wenn Asset noch fehlt
                        CarImagePlaceholder(imageName: car.imageName, contentMode: .fit)
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(car.name)
                                    .font(.headline)
                                Text(car.model)
                                    .font(.subheadline)
                            }

                            Text(car.brand)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Kompakter, untereinander: Ladezustand und Restreichweite rechts
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "battery.100")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(car.stateOfChargePercent)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Ladezustand")
                            .accessibilityValue(car.stateOfChargePercent)

                            HStack(spacing: 4) {
                                Image(systemName: "road.lanes")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(car.remainingRangeKm)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Restreichweite")
                            .accessibilityValue(car.remainingRangeKm)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Home")
            .navigationDestination(for: Car.self) { car in
                CarDetailView(car: car)
            }
            .onAppear {
                cars = CarLoader.load()
            }
        }
    }
}

// Bild-Platzhalter: versucht Asset zu laden, fällt auf SF Symbol zurück
struct CarImagePlaceholder: View {
    enum ContentMode {
        case fill
        case fit
    }

    let imageName: String
    var contentMode: ContentMode = .fill

    var body: some View {
        ZStack {
            if let uiImage = UIImage(named: imageName) {
                let image = Image(uiImage: uiImage).resizable()
                switch contentMode {
                case .fill:
                    image.scaledToFill()
                case .fit:
                    image.scaledToFit()
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.gray.opacity(0.15))
                    Image(systemName: "car.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.gray)
                }
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .clipped()
    }
}

// Detailansicht mit 2x2-Grid der vier Boxen
struct CarDetailView: View {
    let car: Car

    @State private var showSelectionToast = false

    private var gridItems: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header mit Bild
                CarImagePlaceholder(imageName: car.imageName, contentMode: .fill)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(car.name)
                                    .font(.title2).bold()
                                    .foregroundStyle(.primary)
                                Text(car.model)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                            Text(car.brand)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .padding(8)
                    }
                    // SoC und Restreichweite oben im Bild sichtbar machen (rechts unten, untereinander)
                    .overlay(alignment: .bottomTrailing) {
                        VStack(alignment: .trailing, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "battery.100")
                                    .foregroundStyle(.white)
                                Text(car.stateOfChargePercent)
                                    .font(.subheadline).bold()
                                    .foregroundStyle(.white)
                                    .monospacedDigit()
                            }
                            HStack(spacing: 8) {
                                Image(systemName: "road.lanes")
                                    .foregroundStyle(.white)
                                Text(car.remainingRangeKm)
                                    .font(.subheadline).bold()
                                    .foregroundStyle(.white)
                                    .monospacedDigit()
                            }
                        }
                        .padding(.horizontal, 14)   // etwas größerer Hintergrund
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.black.opacity(0.6)) // leicht dunkler, bessere Lesbarkeit
                        )
                        .padding(12)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Ladezustand und Restreichweite")
                        .accessibilityValue("\(car.stateOfChargePercent), \(car.remainingRangeKm)")
                    }

                // Auswahl-Button über dem Grid
                Button(action: {
                    showTransientToast()
                }) {
                    Text("Fahrzeug auswählen")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                }
                // Eigene, feste Gestaltung: grauer Hintergrund + weiße Schrift
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.systemGray)) // oder .gray für statisches Grau
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(.systemGray2), lineWidth: 0.5)
                )
                .controlSize(.regular)

                // 2x2 Grid
                LazyVGrid(columns: gridItems, spacing: 12) {
                    StatBox(title: "Leistung", value: car.power, symbol: "engine.combustion")
                    StatBox(title: "Beschleunigung 0.100", value: car.accelaration0To100kmh, symbol: "engine.combustion")
                    StatBox(title: "Batteriekapazität", value: car.batteryCapacityKWh, symbol: "battery.100")
                    StatBox(title: "Max. Reichweite kombiniert bis", value: car.maxRangeKm, symbol: "speedometer")
                    StatBox(title: "Batterietechnologie", value: car.batteryTechnology, symbol: "minus.plus.batteryblock")
                    StatBox(title: "Verbrauch / 100 km", value: car.consumptionPer100km, symbol: "speedometer")
                    StatBox(title: "Höchstgeschwindigkeit", value: car.maxSpeed, symbol: "engine.combustion")
                }
            }
            .padding(16)
        }
        .navigationTitle(car.name)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if showSelectionToast {
                ToastView(text: "\(car.name) ausgewählt")
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 12)
            }
        }
        .animation(.spring(duration: 0.35), value: showSelectionToast)
    }

    private func showTransientToast() {
        showSelectionToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showSelectionToast = false
        }
    }
}

// Kleine Box-Komponente
struct StatBox: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .foregroundStyle(.tint)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            Text(value)
                .font(.title3).bold()
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// Einfache Toast-Ansicht
struct ToastView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline).bold()
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.8))
            )
            .shadow(radius: 8)
    }
}

#Preview {
    HomeView()
}
