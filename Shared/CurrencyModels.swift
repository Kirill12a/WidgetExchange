//
//  CurrencyModels.swift
//  Widget
//
//  Created by Kirill Drozdov on 09.11.2025.
//

import Foundation
import SwiftUI

struct CurrencyRates: Codable {
    let base: String
    let date: Date
    let rates: [String: Double]
}

struct RatePoint: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let value: Double

    init(id: UUID = UUID(), date: Date, value: Double) {
        self.id = id
        self.date = date
        self.value = value
    }
}

struct WidgetLink: Identifiable {
    let id = UUID()
    let name: String
    let token: String
    let allowedPairs: [String]
}

struct OnboardingSlide: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let accent: Color
    let icon: String
    let footnote: String
}

struct WidgetPreset: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var amount: Double

    init(id: UUID = UUID(), title: String, amount: Double) {
        self.id = id
        self.title = title
        self.amount = amount
    }
}

enum CurrencyCatalog {
    static let primaryCodes = [
        "USD", "EUR", "GBP", "CHF", "JPY", "CNY", "AUD", "CAD", "AED", "KZT", "TRY"
    ]

    static let extendedCodes = [
        "USD", "EUR", "GBP", "CHF", "JPY", "CNY", "AUD", "CAD",
        "AED", "KZT", "TRY", "SEK", "NOK", "PLN", "UAH", "BRL", "INR", "SGD"
    ]
}

extension RatePoint {
    static func placeholderSeries(seed: Double, days: Int) -> [RatePoint] {
        let calendar = Calendar.current
        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let variance = Double.random(in: -0.004...0.004)
            return RatePoint(date: date, value: max(0.01, seed * (1 + variance)))
        }
        .sorted { $0.date < $1.date }
    }
}

extension WidgetPreset {
    static var defaults: [WidgetPreset] {
        [
            WidgetPreset(title: "25", amount: 25),
            WidgetPreset(title: "50", amount: 50),
            WidgetPreset(title: "100", amount: 100)
        ]
    }
}
