//
//  WidgetInputController.swift
//  Widget
//
//  Created by Kirill Drozdov on 09.11.2025.
//

import Foundation
import WidgetKit

enum WidgetKeypadError: Error {
    case storageUnavailable
}

final class WidgetInputController {
    static let shared = WidgetInputController(cache: .shared)

    private let cache: RatesCache
    private let allowedCharacters = CharacterSet(charactersIn: "0123456789.")
    private let maxLength = 9

    init(cache: RatesCache) {
        self.cache = cache
    }

    func handle(button: WidgetKeypadButton) {
        let snapshot = cache.loadSnapshot() ?? .placeholder
        var amountText = snapshot.amountText

        switch button {
        case .decimal:
            if !amountText.contains("."), amountText.count < maxLength {
                amountText += "."
            }
        case .backspace:
            amountText = String(amountText.dropLast())
            if amountText.isEmpty {
                amountText = "0"
            }
        default:
            let digit = button.symbol
            if amountText == "0" {
                amountText = digit
            } else if amountText.count < maxLength {
                amountText += digit
            }
        }

        amountText = sanitize(amountText)

        let amountValue = Double(amountText) ?? 0
        let convertedValue = amountValue * snapshot.rate

        let updatedSnapshot = ConverterSnapshot(
            baseCurrency: snapshot.baseCurrency,
            targetCurrency: snapshot.targetCurrency,
            rate: snapshot.rate,
            amount: amountValue,
            amountText: amountText,
            converted: convertedValue,
            timestamp: Date(),
            chartSeries: snapshot.chartSeries
        )

        cache.saveSnapshot(updatedSnapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: SharedConstants.widgetKind)
    }

    private func sanitize(_ text: String) -> String {
        var sanitized = text.filter { allowedCharacters.contains($0.unicodeScalars.first!) }
        if sanitized.filter({ $0 == "." }).count > 1 {
            var hasDot = false
            sanitized = sanitized.filter { character in
                if character == "." {
                    if hasDot { return false }
                    hasDot = true
                }
                return true
            }
        }
        if sanitized.first == "." {
            sanitized = "0" + sanitized
        }
        if sanitized.isEmpty {
            sanitized = "0"
        }
        return sanitized
    }
}
