//
//  HomeView.swift
//  BerlIncharge_Daiger
//
//  Created by Tobi on 24.10.25.
// 

import SwiftUI

struct HomeView: View {
    @State private var cars: [Car] = []
    @Binding var selectedCar: Car?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    StatusBox(
                        selectedCar: selectedCar,
                        onClear: { selectedCar = nil }
                    )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                }

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
                                HStack(spacing: 4) {
                                    Image(systemName: "battery.100")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(Calc.computedSocPercentText(for: car))
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
                HomeDetailView(car: car) { picked in
                    selectedCar = picked
                }
            }
            .onAppear {
                cars = CarLoader.load()
            }
        }
    }
}

private struct StatusBox: View {
    let selectedCar: Car?
    let onClear: () -> Void

    var body: some View {
        let hasSelection = (selectedCar != nil)
        let iconName = hasSelection ? "car.fill" : "car"
        let iconColor: Color = hasSelection ? .primary : .secondary

        HStack(alignment: .center, spacing: 12) {
            Image(systemName: iconName)
                .imageScale(.large)
                .foregroundStyle(iconColor)

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



struct HomeDetailView: View {
    let car: Car
    var onSelect: ((Car) -> Void)?

    @State private var showSelectionToast = false

    private var gridItems: [GridItem] { Calc.twoColumnGridItems() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CarImagePlaceholder(imageName: car.imageName)
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
                                Text(Calc.computedSocPercentText(for: car))
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
                    StatBox("Leistung", car.power, "engine.combustion")
                    StatBox("Beschleunigung 0-100", car.accelaration0To100kmh, "engine.combustion")
                    StatBox("Batteriekapazität", car.batteryCapacityKWh, "battery.100")
                    StatBox("Max. Reichweite", car.maxRangeKm, "speedometer")
                    StatBox("Batterietechnologie", car.batteryTechnology, "minus.plus.batteryblock")
                    StatBox("Verbrauch / 100 km", car.consumptionPer100km, "speedometer")
                    StatBox("Höchstgeschwindigkeit", car.maxSpeed, "engine.combustion")
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
