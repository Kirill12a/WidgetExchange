//
//  RatesCache.swift
//  Widget
//
//  Created by Kirill Drozdov on 09.11.2025.
//

import Foundation

struct ConverterSnapshot: Codable {
    let baseCurrency: String
    let targetCurrency: String
    let rate: Double
    let amount: Double
    let amountText: String
    let converted: Double
    let timestamp: Date
    let chartSeries: [RatePoint]
}

final class RatesCache {
    static let shared = RatesCache()

    private enum CacheKey {
        static let snapshot = "widgetfx.latestSnapshot"
        static let rates = "widgetfx.latestRates"
        static let presets = "widgetfx.widgetPresets"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults? = nil) {
        self.defaults = defaults ?? UserDefaults(suiteName: SharedConstants.appGroupIdentifier) ?? .standard
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func saveSnapshot(_ snapshot: ConverterSnapshot) {
        do {
            let data = try encoder.encode(snapshot)
            defaults.set(data, forKey: CacheKey.snapshot)
        } catch {
            print("RatesCache save snapshot error: \(error)")
        }
    }

    func loadSnapshot() -> ConverterSnapshot? {
        guard let data = defaults.data(forKey: CacheKey.snapshot) else { return nil }
        return try? decoder.decode(ConverterSnapshot.self, from: data)
    }

    func saveRates(_ rates: CurrencyRates) {
        do {
            let data = try encoder.encode(rates)
            defaults.set(data, forKey: CacheKey.rates)
        } catch {
            print("RatesCache save rates error: \(error)")
        }
    }

    func loadRates() -> CurrencyRates? {
        guard let data = defaults.data(forKey: CacheKey.rates) else { return nil }
        return try? decoder.decode(CurrencyRates.self, from: data)
    }

    func savePresets(_ presets: [WidgetPreset]) {
        do {
            let data = try encoder.encode(presets)
            defaults.set(data, forKey: CacheKey.presets)
        } catch {
            print("RatesCache save presets error: \(error)")
        }
    }

    func loadPresets() -> [WidgetPreset]? {
        guard let data = defaults.data(forKey: CacheKey.presets) else { return nil }
        return try? decoder.decode([WidgetPreset].self, from: data)
    }
}

extension ConverterSnapshot {
    static var placeholder: ConverterSnapshot {
        ConverterSnapshot(
            baseCurrency: "USD",
            targetCurrency: "EUR",
            rate: 0.93,
            amount: 100,
            amountText: "100",
            converted: 93,
            timestamp: Date(),
            chartSeries: RatePoint.placeholderSeries(seed: 0.94, days: 7)
        )
    }
}

extension RatesCache {
    var defaultPresets: [WidgetPreset] {
        WidgetPreset.defaults
    }
}
