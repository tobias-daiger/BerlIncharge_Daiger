//
//  Car.swift
//  BerlIncharge_Daiger
//
//  Created by Tobi on 25.10.25.
//

import Foundation

struct Station: Identifiable, Hashable, Decodable {
    let id: UUID
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
        case pointName, powerType, advertisedPower,  status, publicAccess, latitude, longitude, street, houseNumber, postalCode
    }

    init(
        id: UUID = UUID(),
        pointName: String,
        powerType: String,
        advertisedPower: String,
        status: String,
        publicAccess: Bool,
        latitude: Double,
        longitude: Double,
        street: String,
        houseNumber: String,
        postalCode: String

        
    ) {
        self.id = id
        self.pointName = pointName
        self.powerType = powerType
        self.advertisedPower = advertisedPower
        self.status = status
        self.publicAccess = publicAccess
        self.latitude = latitude
        self.longitude = longitude
        self.street = street
        self.houseNumber = houseNumber
        self.postalCode = postalCode

    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.pointName = try c.decode(String.self, forKey: .pointName)
        self.powerType = try c.decode(String.self, forKey: .powerType)
        self.advertisedPower = try c.decode(String.self, forKey: .advertisedPower)
        self.status = try c.decode(String.self, forKey: .status)
        self.publicAccess = try c.decode(Bool.self, forKey: .publicAccess)
        self.latitude = try c.decode(Double.self, forKey: .latitude)
        self.longitude = try c.decode(Double.self, forKey: .longitude)
        self.street = try c.decode(String.self, forKey: .street)
        self.houseNumber = try c.decode(String.self, forKey: .houseNumber)
        self.postalCode = try c.decode(String.self, forKey: .postalCode)
    }
}
