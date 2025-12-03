//  Test
//  MapView.swift
//  BerlIncharge_Daiger
//
//  Created by Tobi on 24.10.25.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var stations: [Station] = []
    @Binding var selectedCar: Car?

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.520008, longitude: 13.404954),
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )
    )
    
    @State private var selectedStation: Station?
    @State private var berlinPolylines: [MKPolyline] = []
    @State private var berlinPolygons: [MKPolygon] = []
    @State private var activeRoute: MKRoute?
    @State private var activeRoutePolyline: MKPolyline?
    @State private var compositePolyline: MKPolyline?
    @State private var compositeDistance: CLLocationDistance = 0
    @State private var compositeTime: TimeInterval = 0
    @State private var searchText: String = ""
    @State private var searchResultItem: MKMapItem?
    @State private var isSearching: Bool = false
    @State private var searchErrorMessage: String?
    @State private var showNavToast: Bool = false
    @State private var navToastText: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(position: $position) {
                    UserAnnotation()

                    ForEach(berlinPolylines, id: \.self) { polyline in
                        MapPolyline(polyline)
                            .stroke(Color.black, lineWidth: 3)
                    }

                    ForEach(berlinPolygons, id: \.self) { polygon in
                        MapPolygon(polygon)
                            .foregroundStyle(Color.black.opacity(0.2))
                    }

                    if let composite = compositePolyline {
                        MapPolyline(composite)
                            .stroke(Color("brandPrimary"), lineWidth: 6)
                    } else if let routePolyline = activeRoutePolyline {
                        MapPolyline(routePolyline)
                            .stroke(Color("brandPrimary"), lineWidth: 6)
                    }

                    ForEach(stations) { station in
                        let coordinate = CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)

                        let isDC = station.powerType.lowercased().contains("dc")

                        let symbolName = "ev.charger"
                        let color = isDC ? Color("brandSecondary") : Color("brandPrimary")

                        Annotation(station.pointName, coordinate: coordinate) {
                            Button {
                                selectedStation = station
                            } label: {
                                Image(systemName: symbolName)
                                    .font(.headline)
                                    .foregroundStyle(color)
                                    .padding(6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color(.systemBackground))
                                            .shadow(radius: 1.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    if let item = searchResultItem {
                        let coord = item.placemark.coordinate
                        Annotation(item.name ?? "Ziel", coordinate: coord) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.red)
                                .background(
                                    Circle()
                                        .fill(Color(.systemBackground))
                                        .shadow(radius: 1.5)
                                )
                        }
                    }
                }
                .ignoresSafeArea()

                if hasAnyActiveRoute {
                    VStack {
                        HStack {
                            Spacer()
                            if let summary = currentRouteSummaryText() {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(summary)
                                        .font(.footnote).bold()
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule(style: .continuous)
                                                .fill(Color.black.opacity(0.7))
                                        )

                                    if let computed = computedCarStats() {
                                        VStack(alignment: .trailing, spacing: 4) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "battery.100")
                                                Text(computed.socText)
                                            }
                                            .font(.footnote).bold()
                                            .foregroundStyle(computed.isCritical ? Color.red : Color.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule(style: .continuous)
                                                    .fill(Color.black.opacity(0.7))
                                            )

                                            HStack(spacing: 6) {
                                                Image(systemName: "road.lanes")
                                                Text(computed.rangeText)
                                            }
                                            .font(.footnote).bold()
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule(style: .continuous)
                                                    .fill(Color.black.opacity(0.7))
                                            )
                                        }
                                        .transition(.opacity)
                                    } else {
                                        VStack(alignment: .trailing, spacing: 4) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "battery.100")
                                                Text("0%")
                                            }
                                            .font(.footnote).bold()
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule(style: .continuous)
                                                    .fill(Color.black.opacity(0.7))
                                            )

                                            HStack(spacing: 6) {
                                                Image(systemName: "road.lanes")
                                                Text("0 km")
                                            }
                                            .font(.footnote).bold()
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule(style: .continuous)
                                                    .fill(Color.black.opacity(0.7))
                                            )
                                        }
                                        .transition(.opacity)
                                    }
                                }
                            }
                        }
                        .padding(.top, 12)
                        .padding(.horizontal, 12)

                        Spacer()
                    }
                    .transition(.opacity)
                }

                if hasAnyActiveRoute {
                    VStack {
                        Spacer()
                        HStack {
                            Button {
                                clearRoute()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark.circle.fill")
                                        .imageScale(.large)
                                    Text("Route entfernen")
                                        .font(.subheadline).bold()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .foregroundStyle(.white)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color.black.opacity(0.75))
                                )
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 16)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if let item = searchResultItem {
                    VStack {
                        HStack(alignment: .center, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name ?? "Ziel")
                                    .font(.subheadline).bold()
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                if let subtitle = formattedSubtitle(for: item) {
                                    Text(subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }

                            Spacer(minLength: 12)

                            let buttonHeight: CGFloat = 32

                            VStack(alignment: .trailing, spacing: 6) {
                                HStack(spacing: 6) {
                                    Button {
                                        Task { await buildCompositeRouteOptimized(to: item, requireDC: false) }
                                    } label: {
                                        Text("AC")
                                            .font(.subheadline).bold()
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.9)
                                            .padding(.horizontal, 12)
                                            .frame(height: buttonHeight)
                                            .foregroundStyle(.white)
                                            .background(Capsule().fill(Color("brandPrimary")))
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        Task { await buildCompositeRouteOptimized(to: item, requireDC: true) }
                                    } label: {
                                        Text("DC")
                                            .font(.subheadline).bold()
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.9)
                                            .padding(.horizontal, 12)
                                            .frame(height: buttonHeight)
                                            .foregroundStyle(.white)
                                            .background(Capsule().fill(Color("brandSecondary")))
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        Task { await requestRoute(to: item) }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "car")
                                            Text("Navigieren")
                                                .font(.subheadline).bold()
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.9)
                                        }
                                        .padding(.horizontal, 14)
                                        .frame(height: buttonHeight)
                                        .foregroundStyle(.white)
                                        .background(
                                            Capsule(style: .continuous)
                                                .fill(Color.gray.opacity(0.9))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(

                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 12)
                        .padding(.top, 12)

                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                VStack {
                    if showNavToast {
                        ToastView(text: navToastText)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .padding(.top, 12)
                    }
                    Spacer()
                }
            }
            .onAppear {
                viewModel.start()
                stations = StationLoader.load()
                Task {
                    let result = GeoLoader.loadBerlinGeoJSON()
                    berlinPolylines = result.polylines
                    berlinPolygons = result.polygons
                }
            }
            .navigationTitle("Map View")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Adresse suchen")
            .onSubmit(of: .search) {
                Task { await performSearch() }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                }
            }
            .sheet(item: $selectedStation) { station in
                StationBottomSheetView(
                    station: station,
                    onClose: { selectedStation = nil },
                    onNavigate: { target in
                        Task { await requestRoute(to: target) }
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(false)
            }
            .alert("Suche fehlgeschlagen", isPresented: .constant(searchErrorMessage != nil), actions: {
                Button("OK") { searchErrorMessage = nil }
            }, message: {
                Text(searchErrorMessage ?? "")
            })
            .animation(.spring(duration: 0.35), value: showNavToast)
        }
    }

    private var hasAnyActiveRoute: Bool {
        activeRoutePolyline != nil || compositePolyline != nil
    }

    private func showTransientToast(_ text: String) {
        navToastText = text
        showNavToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showNavToast = false
        }
    }

    private struct ComputedStats {
        let socText: String
        let rangeText: String
        let isCritical: Bool
    }

    private func computedCarStats() -> ComputedStats? {
        guard let car = selectedCar else { return nil }

        let routeKm: Double? = {
            if compositePolyline != nil {
                return compositeDistance / 1000.0
            } else if let route = activeRoute {
                return route.distance / 1000.0
            } else {
                return nil
            }
        }()

        guard let tripKm = routeKm else { return nil }

        func extractNumber(_ s: String) -> Double? {
            let digits = s
                .replacingOccurrences(of: ",", with: ".")
                .filter { ("0"..."9").contains($0) || $0 == "." }
            return Double(digits)
        }

        let startingRangeKm = extractNumber(car.remainingRangeKm) ?? 0
        let maxRangeKm = extractNumber(car.maxRangeKm) ?? 0

        let adjustedRangeKm = max(0, startingRangeKm - tripKm)

        let socRatio = maxRangeKm > 0 ? adjustedRangeKm / maxRangeKm : 0
        let socPercent = max(0, min(1, socRatio)) * 100.0

        let rangeText = String(format: "%.0f km", adjustedRangeKm.rounded())
        let socText = String(format: "%.0f%%", socPercent.rounded())

        let isCritical = socPercent <= 0.0
        return ComputedStats(socText: socText, rangeText: rangeText, isCritical: isCritical)
    }

    @MainActor
    private func performSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        isSearching = true
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            if let first = response.mapItems.first {
                searchResultItem = first

                let coord = first.placemark.coordinate
                let region = MKCoordinateRegion(center: coord,
                                                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
                position = .region(region)
            } else {
                searchResultItem = nil
                searchErrorMessage = "Kein Ergebnis für „\(query)“ gefunden."
            }
        } catch {
            searchErrorMessage = "Fehler bei der Suche: \(error.localizedDescription)"
        }
    }

    private func formattedSubtitle(for item: MKMapItem) -> String? {
        let p = item.placemark
        let parts = [
            p.thoroughfare,
            p.subThoroughfare,
            p.postalCode,
            p.locality
        ].compactMap { $0 }.filter { !$0.isEmpty }

        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " ")
    }
    
    @MainActor
    private func requestRoute(to station: Station) async {
        guard let userLocation = viewModel.lastKnownLocation?.coordinate else {
            print("Keine Nutzerposition verfügbar.")
            return
        }

        compositePolyline = nil
        compositeDistance = 0
        compositeTime = 0

        let sourcePlacemark = MKPlacemark(coordinate: userLocation)
        let destPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude))

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destPlacemark)
        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)
        do {
            let response = try await directions.calculate()
            if let route = response.routes.first {
                activeRoute = route
                activeRoutePolyline = route.polyline
                selectedStation = nil
                searchResultItem = nil

                showTransientToast("Navigiere zu \(station.pointName)")
            }
        } catch {
            print("Routenberechnung fehlgeschlagen: \(error)")
        }
    }

    @MainActor
    private func requestRoute(to item: MKMapItem) async {
        guard let userLocation = viewModel.lastKnownLocation?.coordinate else {
            print("Keine Nutzerposition verfügbar.")
            return
        }

        compositePolyline = nil
        compositeDistance = 0
        compositeTime = 0

        let sourcePlacemark = MKPlacemark(coordinate: userLocation)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = item
        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)
        do {
            let response = try await directions.calculate()
            if let route = response.routes.first {
                activeRoute = route
                activeRoutePolyline = route.polyline
                searchResultItem = nil

                let name = item.name ?? "Ziel"
                showTransientToast("Navigiere zu \(name)")
            }
        } catch {
            print("Routenberechnung fehlgeschlagen: \(error)")
        }
    }
    
    @MainActor
    private func buildCompositeRouteOptimized(to item: MKMapItem, requireDC: Bool) async {
        guard let userLocation = viewModel.lastKnownLocation?.coordinate else {
            print("Keine Nutzerposition verfügbar.")
            return
        }

        guard let direct = await calculateRoute(from: userLocation, to: item.placemark.coordinate) else {
            searchErrorMessage = "Direkte Route zum Ziel konnte nicht berechnet werden."
            return
        }
        
        let corridorMeters: CLLocationDistance = 2000
        let deviationWeight: CLLocationDistance = 300
        let candidateLimit = 30

        let filtered = filterCandidatesAlongCorridor(
            stations: stations,
            requireDC: requireDC,
            polyline: direct.polyline,
            corridorMeters: corridorMeters
        ).prefix(candidateLimit)

        guard !filtered.isEmpty else {
            searchErrorMessage = "Keine passende \(requireDC ? "DC" : "AC")-Station entlang der Route gefunden."
            return
        }

        var bestScore = Double.greatestFiniteMagnitude
        var bestR1: MKRoute?
        var bestR2: MKRoute?

        for station in filtered {
            let c = CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)
            let dev = distance(point: c, toPolyline: direct.polyline)

            guard let r1 = await calculateRoute(from: userLocation, to: c) else { continue }
            guard let r2 = await calculateRoute(from: c, to: item.placemark.coordinate) else { continue }

            let total = r1.distance + r2.distance
            let score = Double(total) + Double(dev + deviationWeight)

            if score < bestScore {
                bestScore = score
                bestR1 = r1
                bestR2 = r2
            }
        }

        guard let route1 = bestR1, let route2 = bestR2 else {
            searchErrorMessage = "Konnte keine geeignete Route über eine \(requireDC ? "DC" : "AC")-Station finden."
            return
        }

        let merged = combine(routeA: route1, routeB: route2)

        activeRoute = nil
        activeRoutePolyline = nil

        compositePolyline = merged
        compositeDistance = route1.distance + route2.distance
        compositeTime = route1.expectedTravelTime + route2.expectedTravelTime
        searchResultItem = nil

        let name = item.name ?? "Ziel"
        showTransientToast("Navigiere via \(requireDC ? "DC" : "AC") zu \(name)")
    }
    
    private func calculateRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async -> MKRoute? {
        let req = MKDirections.Request()
        req.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        req.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        req.transportType = .automobile
        req.requestsAlternateRoutes = false

        do {
            let response = try await MKDirections(request: req).calculate()
            return response.routes.first
        } catch {
            print("Teilroute fehlgeschlagen: \(error)")
            return nil
        }
    }

    private func filterCandidatesAlongCorridor(stations: [Station],
                                               requireDC: Bool,
                                               polyline: MKPolyline,
                                               corridorMeters: CLLocationDistance) -> [Station] {
        stations.filter { s in
            let isDC = s.powerType.lowercased().contains("dc")
            if requireDC != isDC { return false }
            let p = CLLocationCoordinate2D(latitude: s.latitude, longitude: s.longitude)
            let d = distance(point: p, toPolyline: polyline)
            return d <= corridorMeters
        }
        .sorted { a, b in
            let pa = CLLocationCoordinate2D(latitude: a.latitude, longitude: a.longitude)
            let pb = CLLocationCoordinate2D(latitude: b.latitude, longitude: b.longitude)
            return distance(point: pa, toPolyline: polyline) < distance(point: pb, toPolyline: polyline)
        }
    }

    private func distance(point: CLLocationCoordinate2D, toPolyline polyline: MKPolyline) -> CLLocationDistance {
        let coords = polyline.coordinates
        guard coords.count > 1 else { return .greatestFiniteMagnitude }

        var minDist = CLLocationDistance.greatestFiniteMagnitude

        for i in 0..<(coords.count - 1) {
            let a = coords[i]
            let b = coords[i + 1]
            let d = distanceFromPoint(point, toSegmentFrom: a, to: b)
            if d < minDist { minDist = d }
        }
        return minDist
    }

    private func distanceFromPoint(_ p: CLLocationCoordinate2D,
                                   toSegmentFrom a: CLLocationCoordinate2D,
                                   to b: CLLocationCoordinate2D) -> CLLocationDistance {

        let pMP = MKMapPoint(p)
        let aMP = MKMapPoint(a)
        let bMP = MKMapPoint(b)

        let apx = pMP.x - aMP.x
        let apy = pMP.y - aMP.y
        let abx = bMP.x - aMP.x
        let aby = bMP.y - aMP.y
        let ab2 = abx * abx + aby * aby

        if ab2 == 0 {

            return pMP.distance(to: aMP)
        }

        let t = max(0, min(1, (apx * abx + apy * aby) / ab2))
        let proj = MKMapPoint(x: aMP.x + t * abx, y: aMP.y + t * aby)
        return pMP.distance(to: proj)
    }

    private func combine(routeA: MKRoute, routeB: MKRoute) -> MKPolyline {
        var coordsA = routeA.polyline.coordinates
        let coordsB = routeB.polyline.coordinates
        coordsA.append(contentsOf: coordsB)
        return MKPolyline(coordinates: coordsA, count: coordsA.count)
    }
    private func currentRouteSummaryText() -> String? {
        if compositePolyline != nil {
            return routeSummaryText(distance: compositeDistance, time: compositeTime)
        } else {
            return routeSummaryText()
        }
    }

    private func clearRoute() {
        activeRoute = nil
        activeRoutePolyline = nil
        compositePolyline = nil
        compositeDistance = 0
        compositeTime = 0
        searchResultItem = nil
    }

    private func routeSummaryText() -> String? {
        guard let route = activeRoute else { return nil }
        let km = route.distance / 1000.0
        let distanceText = String(format: "%.1f km", km)

        let totalSeconds = Int(route.expectedTravelTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let timeText: String
        if hours > 0 {
            timeText = String(format: "%d:%02d h", hours, minutes)
        } else {
            timeText = String(format: "%d min", minutes)
        }

        return "\(timeText) • \(distanceText)"
    }

    private func routeSummaryText(distance: CLLocationDistance, time: TimeInterval) -> String {
        let km = distance / 1000.0
        let distanceText = String(format: "%.1f km", km)

        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let timeText: String
        if hours > 0 {
            timeText = String(format: "%d:%02d h", hours, minutes)
        } else {
            timeText = String(format: "%d min", minutes)
        }

        return "\(timeText) • \(distanceText)"
    }
}

private extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: self.pointCount)
        self.getCoordinates(&coords, range: NSRange(location: 0, length: self.pointCount))
        return coords
    }
}

#Preview {
    MapView(selectedCar: .constant(nil))
}

//User Location
//https://www.youtube.com/watch?v=hWMkimzIQoU
//https://www.youtube.com/watch?v=98rQZbwxMFI&t=460s
@MainActor
final class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    private var locationManager: CLLocationManager?
    @Published var lastKnownLocation: CLLocation?

    func start() {
        guard CLLocationManager.locationServicesEnabled() else {
            return
        }

        if locationManager == nil {
            let manager = CLLocationManager()
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager = manager
        }

        handleAuthorizationStatus(locationManager?.authorizationStatus ?? .notDetermined)
    }

    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager?.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("Location access not available.")
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager?.startUpdatingLocation()
        @unknown default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationStatus(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.last {
            lastKnownLocation = loc
        }
    }
}

private struct StationBottomSheetView: View {
    let station: Station
    let onClose: () -> Void
    let onNavigate: (Station) -> Void

    @State private var showToast = false

    private var gridItems: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(station.pointName)
                                .font(.title3).bold()
                            Text("\(station.street) \(station.houseNumber), \(station.postalCode)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Button(action: {
                            onNavigate(station)
                            triggerToast()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "car")
                                Text("Navigation")
                                    .font(.headline)
                            }
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
            }
            .navigationTitle("Station")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .imageScale(.large)
                    }
                }
            }
        }
    }

    private func triggerToast() {
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(duration: 0.35)) {
                showToast = false
            }
        }
    }
}

