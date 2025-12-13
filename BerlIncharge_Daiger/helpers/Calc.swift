//
//  calc.swift
//  BerlIncharge_Daiger
//
//  Created by Tobi on 03.12.25.
//

import SwiftUI

struct Calc {
    static func isDC(powerType: String) -> Bool {
        powerType.lowercased().contains("dc")
    }
    
    static func assetName(pointName: String, powerType: String) -> String {
        let lowerName = pointName.lowercased()
        if lowerName.contains("alf") { return "alf" }
        if lowerName.contains("evb") { return "evb" }
        if lowerName.contains("kba") { return "keba" }
        if Calc.isDC(powerType: powerType) {
            return "terra"
        }
        return "keba"
    }
    
    static func twoColumnGridItems(spacing: CGFloat = 12) -> [GridItem] {
        [
            GridItem(.flexible(), spacing: spacing),
            GridItem(.flexible(), spacing: spacing)
        ]
    }
    
    static func extractNumber(from s: String) -> Double? {
        let digits = s
            .replacingOccurrences(of: ",", with: ".")
            .filter { ("0"..."9").contains($0) || $0 == "." }
        return Double(digits)
    }
    
    static func computedSocPercentText(for car: Car) -> String {
        let remaining = extractNumber(from: car.remainingRangeKm) ?? 0
        let maxRange = extractNumber(from: car.maxRangeKm) ?? 0
        guard maxRange > 0 else { return "0%" }

        let ratio = max(0, min(1, remaining / maxRange))
        let percent = (ratio * 100).rounded()
        return String(format: "%.0f%%", percent)
    }
}
