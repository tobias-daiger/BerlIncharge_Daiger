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

    @State private var position: MapCameraPosition = .region( MKCoordinateRegion( center: CLLocationCoordinate2D(latitude: 52.520008, longitude: 13.404954), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)))
    
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
                        let isDC = Calc.isDC(powerType: station.powerType)
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

                if let item = searchResultItem {
                    VStack {
                        HStack(alignment: .center, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name ?? "Ziel")
                                    .font(.subheadline).bold()
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }

                            Spacer(minLength: 12)

                            let buttonHeight: CGFloat = 32

                            VStack(alignment: .trailing, spacing: 6) {
                                HStack(spacing: 6) {
                                    Button {
                                        Task { await requestAssembledRoute(to: item, requireDC: false) }
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
                                        Task { await requestAssembledRoute(to: item, requireDC: true) }
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
                                        Task { await requestRouteToItem(to: item) }
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

                if searchResultItem != nil {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                withAnimation(.spring(duration: 0.3)) {
                                    searchResultItem = nil
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(10)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.75))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 16)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                if hasActiveRoute {
                    VStack {
                        HStack {
                            Spacer()
                            if let summary = displayRouteInfo() {
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

                                    if let computed = displayCarRouteInfo() {
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

                if hasActiveRoute {
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
            .sheet(item: $selectedStation) { station in
                MapDetailView(
                    station: station,
                    onClose: { selectedStation = nil },
                    onNavigate: { target in
                        Task { await requestRouteToStation(to: target) }
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

    @MainActor
    private func performSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            if let first = response.mapItems.first {
                searchResultItem = first

                let coord = first.placemark.coordinate
                let region = MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
                position = .region(region)
            } else {
                searchResultItem = nil
                searchErrorMessage = "Kein Ergebnis für „\(query)“ gefunden."
            }
        } catch {
            searchErrorMessage = "Fehler bei der Suche: \(error.localizedDescription)"
        }
    }

    
    private func requestRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async -> MKRoute? {
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
    
    @MainActor
    private func requestRouteToCoord(to coordinate: CLLocationCoordinate2D, displayName: String?) async {
        guard let userLocation = viewModel.lastKnownLocation?.coordinate else {
            print("Keine Nutzerposition verfügbar.")
            return
        }

        compositePolyline = nil
        compositeDistance = 0
        compositeTime = 0

        guard let route = await requestRoute(from: userLocation, to: coordinate) else {
            print("Berechnung fehlgeschlagen: requestRoute lieferte nil")
            searchErrorMessage = "Route konnte nicht berechnet werden."
            return
        }
                activeRoute = route
                activeRoutePolyline = route.polyline

                let name = displayName ?? "Ziel"
                showTransientToast("Navigiere zu \(name)")
        
    }

    @MainActor
    private func requestRouteToStation(to station: Station) async {
        selectedStation = nil
        searchResultItem = nil
        let coord = CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)
        await requestRouteToCoord(to: coord, displayName: station.pointName)
    }

    @MainActor
    private func requestRouteToItem(to item: MKMapItem) async {
        selectedStation = nil
        searchResultItem = nil
        await requestRouteToCoord(to: item.placemark.coordinate, displayName: item.name)
    }
    
    @MainActor
    private func requestAssembledRoute(to item: MKMapItem, requireDC: Bool) async {
        guard
            let userLocation = viewModel.lastKnownLocation?.coordinate,
            let directRoute = await requestRoute(from: userLocation, to: item.placemark.coordinate)
        else {
            searchErrorMessage = "Direkte Route zum Ziel konnte nicht berechnet werden."
            return
        }

        let radius: CLLocationDistance = 2000
        let maxStations = 30

        let stationContainer = Array(
            filterStationsInRadius(
                stations: stations,
                requireDC: requireDC,
                polyline: directRoute.polyline,
                radius: radius
            ).prefix(maxStations)
        )

        guard !stationContainer.isEmpty else {
            searchErrorMessage = "Keine passende \(requireDC ? "DC" : "AC")-Station entlang der Route gefunden."
            searchResultItem = nil
            return
        }

        func evaluateStationsInRadius(_ s: Station) async -> (score: Double, userToStationRoute: MKRoute, StationToItemRoute: MKRoute)? {
            let stationCoord = CLLocationCoordinate2D(latitude: s.latitude, longitude: s.longitude)
            let distanceFromStationToRoute = distanceFromPointToPolyline(point: stationCoord, to: directRoute.polyline)

            guard
                let userToStationRoute = await requestRoute(from: userLocation, to: stationCoord),
                let StationToItemRoute = await requestRoute(from: stationCoord, to: item.placemark.coordinate)
            else { return nil }

            let totalDistance = userToStationRoute.distance + StationToItemRoute.distance
            let score = Double(totalDistance) + Double(distanceFromStationToRoute)
            return (score, userToStationRoute, StationToItemRoute)
        }

        var bestStation: (score: Double, userToStationRoute: MKRoute, StationToItemRoute: MKRoute)?

        for s in stationContainer {
            if let observedStation = await evaluateStationsInRadius(s) {
                if let currentBestStation = bestStation {
                    if observedStation.score < currentBestStation.score {
                        bestStation = observedStation
                    }
                } else {
                    bestStation = observedStation
                }
            }
        }

        guard let bestAssembledRoute = bestStation else {
            searchErrorMessage = "Konnte keine geeignete Route über eine \(requireDC ? "DC" : "AC")-Station finden."
            return
        }

        let assembledRoute = assembleRoute(routeA: bestAssembledRoute.userToStationRoute, routeB: bestAssembledRoute.StationToItemRoute)
        activeRoute = nil
        activeRoutePolyline = nil
        compositePolyline = assembledRoute
        compositeDistance = bestAssembledRoute.userToStationRoute.distance + bestAssembledRoute.StationToItemRoute.distance
        compositeTime = bestAssembledRoute.userToStationRoute.expectedTravelTime + bestAssembledRoute.StationToItemRoute.expectedTravelTime
        searchResultItem = nil

        showTransientToast("Navigiere via \(requireDC ? "DC" : "AC") zu \(item.name ?? "Ziel")")
    }

    private func filterStationsInRadius(stations: [Station], requireDC: Bool, polyline: MKPolyline, radius: CLLocationDistance) -> [Station] {
        stations.filter { s in
                let matchesType = Calc.isDC(powerType: s.powerType) == requireDC
                guard matchesType else { return false }
                
                let p = CLLocationCoordinate2D(latitude: s.latitude, longitude: s.longitude)
                return distanceFromPointToPolyline(point: p, to: polyline) <= radius
            }
    }

    private func distanceFromPointToPolyline(point: CLLocationCoordinate2D, to polyline: MKPolyline) -> CLLocationDistance {
        let coords = polyline.coordinates
        guard coords.count > 1 else { return .greatestFiniteMagnitude }

        var minDist = CLLocationDistance.greatestFiniteMagnitude
        for i in 0..<(coords.count - 1) {
            let a = coords[i], b = coords[i + 1]
            minDist = min(minDist, distanceFromPointToSegment(point, from: a, to: b))
        }
        return minDist
    }

    private func distanceFromPointToSegment(_ p: CLLocationCoordinate2D, from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> CLLocationDistance {
        let stationMapPoint = MKMapPoint(p)
        let startMapPoint = MKMapPoint(a)
        let endMapPoint = MKMapPoint(b)
        
        let startToStationVectorX = stationMapPoint.x - startMapPoint.x
        let startToStationVectorY = stationMapPoint.y - startMapPoint.y
        let startToEndVectorX = endMapPoint.x - startMapPoint.x
        let startToEndVectorY = endMapPoint.y - startMapPoint.y
        
        let startToEndVectorSquare = startToEndVectorX * startToEndVectorX + startToEndVectorY * startToEndVectorY
        if startToEndVectorSquare == 0 { return stationMapPoint.distance(to: startMapPoint) }
        
        let projectedParameter = max(0, min(1, (startToStationVectorX * startToEndVectorX + startToStationVectorY * startToEndVectorY) / startToEndVectorSquare))
        let projectedMapPoint = MKMapPoint(x: startMapPoint.x + projectedParameter * startToEndVectorX, y: startMapPoint.y + projectedParameter * startToEndVectorY)
        return stationMapPoint.distance(to: projectedMapPoint)
    }

    private func assembleRoute(routeA: MKRoute, routeB: MKRoute) -> MKPolyline {
        var coordsA = routeA.polyline.coordinates
        let coordsB = routeB.polyline.coordinates
        coordsA.append(contentsOf: coordsB)
        return MKPolyline(coordinates: coordsA, count: coordsA.count)
    }
    
    private func clearRoute() {
        activeRoute = nil
        activeRoutePolyline = nil
        compositePolyline = nil
        compositeDistance = 0
        compositeTime = 0
        searchResultItem = nil
    }
    
    private func displayRouteInfo() -> String? {
        if compositePolyline != nil {
            return routeInfo(distance: compositeDistance, time: compositeTime)
        }
        return activeRoute.map { routeInfo(distance: $0.distance, time: $0.expectedTravelTime) }
    }

    private func routeInfo(distance: CLLocationDistance, time: TimeInterval) -> String {
        let km = distance / 1000.0
        let distanceText = String(format: "%.1f km", km)

        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let timeText = hours > 0
            ? String(format: "%d:%02d h", hours, minutes)
            : String(format: "%d min", minutes)

        return "\(timeText) • \(distanceText)"
    }
    
    private struct CarRouteInfo {
        let socText: String
        let rangeText: String
        let isCritical: Bool
    }

    private func displayCarRouteInfo() -> CarRouteInfo? {
        guard let car = selectedCar else { return nil }

        let tripKm: Double? = compositePolyline != nil
            ? compositeDistance / 1000
            : activeRoute.map { $0.distance / 1000 }

        guard let tripKm else { return nil }

        let startKm = Calc.extractNumber(from: car.remainingRangeKm) ?? 0
        let maxKm = Calc.extractNumber(from: car.maxRangeKm) ?? 0

        let adjustedKm = max(0, startKm - tripKm)
        let socPercent = maxKm > 0 ? max(0, min(1, adjustedKm / maxKm)) * 100 : 0

        let rangeText = String(format: "%.0f km", adjustedKm.rounded())
        let socText = String(format: "%.0f%%", socPercent.rounded())
        let isCritical = socPercent <= 0

        return CarRouteInfo(socText: socText, rangeText: rangeText, isCritical: isCritical)
    }
    
    private var hasActiveRoute: Bool {
        activeRoutePolyline != nil || compositePolyline != nil
    }

    private func showTransientToast(_ text: String) {
        navToastText = text
        showNavToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showNavToast = false
        }
    }
}

private extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: self.pointCount)
        self.getCoordinates(&coords, range: NSRange(location: 0, length: self.pointCount))
        return coords
    }
}

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

private struct MapDetailView: View {
    let station: Station
    let onClose: () -> Void
    let onNavigate: (Station) -> Void

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

                        Button(action: {onNavigate(station)}){
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
}

