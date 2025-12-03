//
//  GeoLoader.swift
//  BerlIncharge_Daiger
//
//  Created by Tobi on 03.12.25.
//

import Foundation
import MapKit

enum GeoLoader {
    static func loadBerlinGeoJSON() -> (polylines: [MKPolyline], polygons: [MKPolygon]) {
        guard let url = Bundle.main.url(forResource: "berlingeo", withExtension: "geojson") else {
            print("berlingeo.geojson nicht im Bundle gefunden.")
            return ([], [])
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = MKGeoJSONDecoder()
            let features = try decoder.decode(data)

            var polylines: [MKPolyline] = []
            var polygons: [MKPolygon] = []

            for feature in features {
                if let mkFeature = feature as? MKGeoJSONFeature {
                    for geom in mkFeature.geometry {
                        switch geom {
                        case let polyline as MKPolyline:
                            polylines.append(polyline)
                        case let polygon as MKPolygon:
                            polygons.append(polygon)
                        default:
                            break
                        }
                    }
                }
            }

            return (polylines, polygons)
        } catch {
            print("Fehler beim Laden/Decodieren von berlingeo.geojson: \(error)")
            return ([], [])
        }
    }
}

