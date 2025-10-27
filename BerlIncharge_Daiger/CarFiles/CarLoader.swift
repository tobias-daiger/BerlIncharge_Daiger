//
//  CarLoader.swift
//  BerlIncharge_Daiger
//
//  Created by Tobi on 25.10.25.
//

import Foundation

enum CarLoader {
    static func load() -> [Car] {
        guard let url = Bundle.main.url(forResource: "cars", withExtension: "json") else {
            print("cars.json nicht gefunden.")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let cars = try JSONDecoder().decode([Car].self, from: data)
            return cars
        } catch {
            print("Fehler beim Laden/Decodieren von cars.json: \(error)")
            return []
        }
    }
}
