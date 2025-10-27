//
//  Car.swift
//  BerlIncharge_Daiger
//
//  Created by Tobi on 25.10.25.
//

import Foundation

struct Car: Identifiable, Hashable, Decodable {
    let id: UUID
    let name: String
    let model: String
    let brand: String
    let imageName: String
    let batteryCapacityKWh: String
    let stateOfChargePercent: String
    let consumptionPer100km: String
    let maxRangeKm: String
    let remainingRangeKm: String
    let batteryTechnology: String
    let power: String
    let maxSpeed: String
    let accelaration0To100kmh: String

    private enum CodingKeys: String, CodingKey {
        case name, model, brand, imageName, batteryCapacityKWh, stateOfChargePercent, consumptionPer100km, maxRangeKm, remainingRangeKm, batteryTechnology, power, maxSpeed, accelaration0To100kmh
    }

    init(
        id: UUID = UUID(),
        name: String,
        model: String,
        brand: String,
        imageName: String,
        batteryCapacityKWh: String,
        stateOfChargePercent: String,
        consumptionPer100km: String,
        maxRangeKm: String,
        remainingRangeKm: String,
        batteryTechnology: String,
        power: String,
        maxSpeed: String,
        accelaration0To100kmh: String
        
    ) {
        self.id = id
        self.name = name
        self.model = model
        self.brand = brand
        self.imageName = imageName
        self.batteryCapacityKWh = batteryCapacityKWh
        self.stateOfChargePercent = stateOfChargePercent
        self.consumptionPer100km = consumptionPer100km
        self.maxRangeKm = maxRangeKm
        self.remainingRangeKm = remainingRangeKm
        self.batteryTechnology = batteryTechnology
        self.power = power
        self.maxSpeed = maxSpeed
        self.accelaration0To100kmh = accelaration0To100kmh
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try c.decode(String.self, forKey: .name)
        self.model = try c.decode(String.self, forKey: .model)
        self.brand = try c.decode(String.self, forKey: .brand)
        self.imageName = try c.decode(String.self, forKey: .imageName)
        self.batteryCapacityKWh = try c.decode(String.self, forKey: .batteryCapacityKWh)
        self.stateOfChargePercent = try c.decode(String.self, forKey: .stateOfChargePercent)
        self.consumptionPer100km = try c.decode(String.self, forKey: .consumptionPer100km)
        self.maxRangeKm = try c.decode(String.self, forKey: .maxRangeKm)
        self.remainingRangeKm = try c.decode(String.self, forKey: .remainingRangeKm)
        self.batteryTechnology = try c.decode(String.self, forKey: .batteryTechnology)
        self.power = try c.decode(String.self, forKey: .power)
        self.maxSpeed = try c.decode(String.self, forKey: .maxSpeed)
        self.accelaration0To100kmh = try c.decode(String.self, forKey: .accelaration0To100kmh)
    }
}
