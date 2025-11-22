//
//  CurrencyViewModel.swift
//  Widget
//
//  Created by Kirill Drozdov on 09.11.2025.
//

import Foundation
import Combine
import WidgetKit

@MainActor
final class CurrencyViewModel: ObservableObject {
    @Published var availableCurrencies = CurrencyCatalog.extendedCodes
    @Published var baseCurrency = "USD"
    @Published var targetCurrency = "EUR"
    @Published var amountText = "100"
    @Published var convertedValue: Double?
    @Published var lastUpdated: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var widgetLinks: [WidgetLink] = [
        WidgetLink(name: "Dashboard KPI", token: "wgt-kpi-73A9", allowedPairs: ["USD/EUR", "USD/GBP"]),
        WidgetLink(name: "Retail POS", token: "wgt-retail-55B1", allowedPairs: ["EUR/RUB", "EUR/TRY"]),
        WidgetLink(name: "Premium Club", token: "wgt-prem-903C", allowedPairs: ["USD/AED"])
    ]
    @Published var chartSeries: [RatePoint] = []
    @Published var widgetPresets: [WidgetPreset] = []

    var heroCopy: String {
        if widgetLinks.count > 2 {
            return AppLocale.text(.heroCopyMany, widgetLinks.count)
        }
        return AppLocale.text(.heroCopyDefault)
    }

    var formattedResult: String {
        guard let convertedValue else { return "--" }
        return convertedValue.formatted(.number.precision(.fractionLength(2)))
    }

    var formattedRate: String {
        guard let rate = latestRates?.rates[targetCurrency] else { return AppLocale.text(.rateUnavailable) }
        let rateText = rate.formatted(.number.precision(.fractionLength(4)))
        return AppLocale.text(.rateFormatted, baseCurrency, rateText, targetCurrency)
    }

    private(set) var latestRates: CurrencyRates?
    private let service: CurrencyService
    private let cache: RatesCache

    init(service: CurrencyService = .shared, cache: RatesCache = .shared) {
        self.service = service
        self.cache = cache

        if let cachedRates = cache.loadRates() {
            latestRates = cachedRates
            lastUpdated = cachedRates.date
            baseCurrency = cachedRates.base
        }

        if let snapshot = cache.loadSnapshot() {
            baseCurrency = snapshot.baseCurrency
            targetCurrency = snapshot.targetCurrency
            amountText = snapshot.amountText
            convertedValue = snapshot.converted
            lastUpdated = snapshot.timestamp
            chartSeries = snapshot.chartSeries
        }

        widgetPresets = cache.loadPresets() ?? cache.defaultPresets
    }

    func load() {
        Task {
            await refreshRates()
            await refreshTrend()
        }
    }

    func refreshRates() async {
        isLoading = true
        errorMessage = nil
        do {
            let rates = try await service.fetchRates(base: baseCurrency, symbols: availableCurrencies)
            latestRates = rates
            lastUpdated = rates.date
            cache.saveRates(rates)
            updateConversion()
        } catch {
        errorMessage = AppLocale.text(.errorRatesUnavailable, error.localizedDescription)
            if let cachedRates = cache.loadRates(), cachedRates.base == baseCurrency {
                latestRates = cachedRates
                lastUpdated = cachedRates.date
                updateConversion()
            }
        }
        isLoading = false
    }

    func refreshTrend() async {
        do {
            chartSeries = try await service.fetchTrend(base: baseCurrency, target: targetCurrency, days: 7)
        } catch {
            chartSeries = RatePoint.placeholderSeries(seed: latestRates?.rates[targetCurrency] ?? 1.0, days: 7)
        }
        persistSnapshot()
    }

    func updateAmount(_ newValue: String) {
        let sanitized = newValue
            .replacingOccurrences(of: ",", with: ".")
            .filter { "0123456789.".contains($0) }

        if sanitized.filter({ $0 == "." }).count > 1 {
            return
        }

        amountText = sanitized
        updateConversion()
    }

    func swapCurrencies() {
        let previousBase = baseCurrency
        baseCurrency = targetCurrency
        targetCurrency = previousBase

        Task {
            await refreshRates()
            await refreshTrend()
        }
    }

    func selectBase(_ code: String) {
        guard baseCurrency != code else { return }
        baseCurrency = code
        Task {
            await refreshRates()
            await refreshTrend()
        }
    }

    func selectTarget(_ code: String) {
        guard targetCurrency != code else { return }
        targetCurrency = code
        updateConversion()
        Task {
            await refreshTrend()
        }
    }

    func widgetEndpoint(for token: String) -> String {
        "\(SharedConstants.widgetEndpointBase)?token=\(token)"
    }

    func updateWidgetPresets(_ presets: [WidgetPreset]) {
        widgetPresets = presets.filter { $0.amount > 0 }
        if widgetPresets.isEmpty {
            widgetPresets = cache.defaultPresets
        }
        cache.savePresets(widgetPresets)
#if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: SharedConstants.widgetKind)
#endif
    }

    private func updateConversion() {
        guard let rate = latestRates?.rates[targetCurrency] else {
            convertedValue = nil
            return
        }
        let amount = Double(amountText.isEmpty ? "0" : amountText) ?? 0
        convertedValue = amount * rate
        persistSnapshot(amountOverride: amount, rateOverride: rate)
    }

    private func persistSnapshot(amountOverride: Double? = nil, rateOverride: Double? = nil) {
        guard let convertedValue,
              let rate = rateOverride ?? latestRates?.rates[targetCurrency] else {
            return
        }
        let amount = amountOverride ?? Double(amountText.isEmpty ? "0" : amountText) ?? 0
        let timestamp = lastUpdated ?? Date()
        let persistedText = amountText.isEmpty ? "0" : amountText

        let snapshot = ConverterSnapshot(
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rate: rate,
            amount: amount,
            amountText: persistedText,
            converted: convertedValue,
            timestamp: timestamp,
            chartSeries: chartSeries
        )
        cache.saveSnapshot(snapshot)
#if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: SharedConstants.widgetKind)
#endif
    }
}
