//
//  Car.swift
//  BerlIncharge_Daiger
//
//  Created by Tobi on 25.10.25.
//

import Foundation

struct Station: Identifiable, Hashable, Decodable {
    let id: UUID = UUID()
    let pointName: String
    let powerType: String
    let advertisedPower: String
    let status: String
    let publicAccess: Bool
    let latitude: Double
    let longitude: Double
    let street: String
    let houseNumber: String
    let postalCode: String

    private enum CodingKeys: String, CodingKey {
        case pointName
        case powerType
        case advertisedPower
        case status
        case publicAccess
        case latitude
        case longitude
        case street
        case houseNumber
        case postalCode
    }
}
