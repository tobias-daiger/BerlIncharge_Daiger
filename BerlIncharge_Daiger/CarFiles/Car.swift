//
//  Car.swift
//  BerlIncharge_Daiger
//
//  Created by Tobi on 25.10.25.
//

import Foundation

struct Car: Identifiable, Hashable, Decodable {
    let id: UUID = UUID() 
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
        case name
        case model
        case brand
        case imageName
        case batteryCapacityKWh
        case stateOfChargePercent
        case consumptionPer100km
        case maxRangeKm
        case remainingRangeKm
        case batteryTechnology
        case power
        case maxSpeed
        case accelaration0To100kmh
    }
}
