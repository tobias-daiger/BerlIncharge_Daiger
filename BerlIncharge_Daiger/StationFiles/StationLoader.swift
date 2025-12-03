//
//  CarLoader.swift
//  BerlIncharge_Daiger
//
//  Created by Tobi on 25.10.25.
//

import Foundation

enum StationLoader {
    static func load() -> [Station] {
        guard let url = Bundle.main.url(forResource: "stations", withExtension: "json") else {
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let stations = try JSONDecoder().decode([Station].self, from: data)
            return stations
        } catch {
            return []
        }
    }
}
