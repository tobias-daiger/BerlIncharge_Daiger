//
//  HomeView.swift
//  BerlIncharge_Daiger
//
//  Created by Tobi on 24.10.25.
// https://www.youtube.com/watch?v=IopCl8sOyFA

import SwiftUI

struct HomeView: View {
    @State private var cars: [Car] = []
    @Binding var selectedCar: Car?

    var body: some View {
        NavigationStack {
            List {
                // Statusbox oben über der Liste
                Section {
                    StatusBox(
                        selectedCar: selectedCar,
                        onClear: { selectedCar = nil }
                    )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                }

                // Fahrzeugliste
                ForEach(cars) { car in
                    NavigationLink(value: car) {
                        HStack(spacing: 12) {
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

                            VStack(alignment: .trailing, spacing: 4) {
                                // Ladezustand berechnet: remainingRangeKm / maxRangeKm
                                HStack(spacing: 4) {
                                    Image(systemName: "battery.100")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(computedSocPercentText(for: car))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }

                                HStack(spacing: 4) {
                                    Image(systemName: "road.lanes")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(car.remainingRangeKm)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Home")
            .navigationDestination(for: Car.self) { car in
                CarDetailView(car: car) { picked in
                    selectedCar = picked
                }
            }
            .onAppear {
                cars = CarLoader.load()
            }
        }
    }

    // MARK: - Helpers
    private func computedSocPercentText(for car: Car) -> String {
        func extractNumber(_ s: String) -> Double? {
            let digits = s
                .replacingOccurrences(of: ",", with: ".")
                .filter { ("0"..."9").contains($0) || $0 == "." }
            return Double(digits)
        }

        let remaining = extractNumber(car.remainingRangeKm) ?? 0
        let maxRange = extractNumber(car.maxRangeKm) ?? 0
        guard maxRange > 0 else { return "0%" }

        let ratio = max(0, min(1, remaining / maxRange))
        let percent = (ratio * 100).rounded()
        return String(format: "%.0f%%", percent)
    }
}

private struct StatusBox: View {
    let selectedCar: Car?
    let onClear: () -> Void

    var body: some View {
        // Extracted to simplify type-checking
        let hasSelection = (selectedCar != nil)
        let iconName = hasSelection ? "car.fill" : "car"
        // Use AnyShapeStyle to avoid overload complexity with ternary
        let iconStyle: AnyShapeStyle = hasSelection ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary)

        HStack(alignment: .center, spacing: 12) {
            Image(systemName: iconName)
                .imageScale(.large)
                .foregroundStyle(iconStyle)

            VStack(alignment: .leading, spacing: 2) {
                if let car = selectedCar {
                    Text("\(car.name) ausgewählt")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(car.brand) • \(car.model)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else {
                    Text("Kein Fahrzeug ausgewählt")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Wähle ein Fahrzeug aus der Liste.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if hasSelection {
                Button {
                    onClear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
    }
}

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

struct CarDetailView: View {
    let car: Car
    var onSelect: ((Car) -> Void)?

    @State private var showSelectionToast = false

    private var gridItems: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.black.opacity(0.6))
                        )
                        .padding(12)
                    }

                Button(action: {
                    onSelect?(car)
                    showTransientToast()
                }) {
                    Text("Fahrzeug auswählen")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.systemGray))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(.systemGray2), lineWidth: 0.5)
                )
                .controlSize(.regular)

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

//https://www.youtube.com/watch?v=pC6qGSSh9bI
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
    HomeView(selectedCar: .constant(nil))
}

