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
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let cars = try JSONDecoder().decode([Car].self, from: data)
            return cars
        } catch {
            return []
        }
    }
}
