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
            return "Виджеты рассылают конверсии за \(widgetLinks.count) сценария."
        }
        return "Передавайте курсы прямо из виджета на сайты и панели мониторинга."
    }

    var formattedResult: String {
        guard let convertedValue else { return "--" }
        return convertedValue.formatted(.number.precision(.fractionLength(2)))
    }

    var formattedRate: String {
        guard let rate = latestRates?.rates[targetCurrency] else { return "—" }
        return "1 \(baseCurrency) = \(rate.formatted(.number.precision(.fractionLength(4)))) \(targetCurrency)"
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
            errorMessage = "Не удалось обновить курс: \(error.localizedDescription). Показаны данные из кэша."
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

        amountText = sanitized.isEmpty ? "0" : sanitized
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
        guard let amount = Double(amountText),
              let rate = latestRates?.rates[targetCurrency] else {
            convertedValue = nil
            return
        }
        convertedValue = amount * rate
        persistSnapshot()
    }

    private func persistSnapshot() {
        guard let amount = Double(amountText),
              let convertedValue,
              let rate = latestRates?.rates[targetCurrency] else {
            return
        }
        let timestamp = lastUpdated ?? Date()

        let snapshot = ConverterSnapshot(
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            rate: rate,
            amount: amount,
            amountText: amountText,
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
