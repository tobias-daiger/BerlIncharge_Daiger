//
//  style.swift
//  BerlIncharge_Daiger
//
//  Created by Tobi on 03.12.25.
//

import SwiftUI

struct StatBox: View {
    let title: String
    let value: String
    let symbol: String

    init(_ title: String, _ value: String, _ symbol: String) {
        self.title = title
        self.value = value
        self.symbol = symbol
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .foregroundStyle(.tint)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            Text(value)
                .font(.title3).bold()
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct ToastView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline).bold()
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.8))
            )
            .shadow(radius: 8)
    }
}

struct CarImagePlaceholder: View {
    enum ContentMode {
        case fill
        case fit
    }

    let imageName: String
    var contentMode: ContentMode = .fill

    var body: some View {
        ZStack {
            if let uiImage = UIImage(named: imageName) {
                let image = Image(uiImage: uiImage).resizable()
                switch contentMode {
                case .fill:
                    image.scaledToFill()
                case .fit:
                    image.scaledToFit()
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.gray.opacity(0.15))
                    Image(systemName: "car.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.gray)
                }
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .clipped()
    }
}

struct StationImagePlaceholder: View {
    let pointName: String
    let powerType: String

    private var normalizedName: String { pointName.lowercased() }
    private var isDC: Bool { Calc.isDC(powerType: powerType) }
    private var assetName: String { Calc.assetName(pointName: pointName, powerType: powerType) }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.secondarySystemBackground))

            if let uiImage = UIImage(named: assetName) {
                let image = Image(uiImage: uiImage).resizable()
                if isDC {
                    image.scaledToFit()
                } else {
                    image.scaledToFill()
                }
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .clipped()
    }
}
