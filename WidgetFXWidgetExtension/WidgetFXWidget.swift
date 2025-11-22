//
//  WidgetFXWidget.swift
//  WidgetFXWidgetExtension
//
//  Created by Kirill Drozdov on 09.11.2025.
//

import SwiftUI
import WidgetKit
import AppIntents

@available(iOSApplicationExtension 17.0, *)
struct WidgetFXEntry: TimelineEntry {
    let date: Date
    let snapshot: ConverterSnapshot
    let presets: [WidgetPreset]
    let conversions: [WidgetConversionDisplay]
}

struct WidgetConversionDisplay: Identifiable, Hashable {
    let id = UUID()
    let code: String
    let rate: Double
    let converted: Double
}

@available(iOSApplicationExtension 17.0, *)
struct WidgetFXTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = WidgetFXEntry
    typealias Intent = WidgetFXConfigurationIntent

    func placeholder(in context: Context) -> WidgetFXEntry {
        let placeholderSnapshot = ConverterSnapshot.placeholder
        return WidgetFXEntry(
            date: Date(),
            snapshot: placeholderSnapshot,
            presets: RatesCache.shared.defaultPresets,
            conversions: WidgetConversionBuilder.makePlaceholder(base: placeholderSnapshot.baseCurrency)
        )
    }

    func snapshot(for configuration: WidgetFXConfigurationIntent, in context: Context) async -> WidgetFXEntry {
        let snapshot = RatesCache.shared.loadSnapshot() ?? .placeholder
        let presets = RatesCache.shared.loadPresets() ?? RatesCache.shared.defaultPresets
        let conversions = WidgetConversionBuilder.make(with: snapshot)
        return WidgetFXEntry(date: snapshot.timestamp, snapshot: snapshot, presets: presets, conversions: conversions)
    }

    func timeline(for configuration: WidgetFXConfigurationIntent, in context: Context) async -> Timeline<WidgetFXEntry> {
        let snapshot = RatesCache.shared.loadSnapshot() ?? .placeholder
        let presets = RatesCache.shared.loadPresets() ?? RatesCache.shared.defaultPresets
        let conversions = WidgetConversionBuilder.make(with: snapshot)

        let now = Date()
        let entry = WidgetFXEntry(date: now, snapshot: snapshot, presets: presets, conversions: conversions)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)

        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

@available(iOSApplicationExtension 17.0, *)
struct WidgetFXWidgetEntryView: View {
    var entry: WidgetFXEntry
    @Environment(\.widgetFamily) private var family

    @ViewBuilder
    var body: some View {
        switch family {
        case .systemLarge:
            WidgetFXLargeView(entry: entry)
        default:
            UnsupportedSizeView()
        }
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct WidgetFXLargeView: View {
    let entry: WidgetFXEntry

    var body: some View {
        ZStack {
            angularGradientBackground
            VStack(spacing: 12) {
                InputValueCard(amountText: entry.snapshot.amountText, currency: entry.snapshot.baseCurrency)
                OutputValueCard(conversion: entry.conversions.first, targetCurrency: entry.snapshot.targetCurrency)
                KeypadMockView(amountText: entry.snapshot.amountText)
                TimestampRow(date: entry.snapshot.timestamp)
            }
            .padding(16)
        }
        .widgetURL(nil)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .transaction { $0.animation = nil }
    }

    private var angularGradientBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                AngularGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.12, blue: 0.2),
                        Color(red: 0.2, green: 0.08, blue: 0.35),
                        Color(red: 0.08, green: 0.22, blue: 0.32),
                        Color(red: 0.12, green: 0.12, blue: 0.2)
                    ]),
                    center: .center
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 18, x: 0, y: 12)
    }
}

@available(iOSApplicationExtension 17.0, *)
struct WidgetFXWidget: Widget {
    let kind: String = SharedConstants.widgetKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WidgetFXConfigurationIntent.self, provider: WidgetFXTimelineProvider()) { entry in
            WidgetFXWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Widget FX конвертер")
        .description("Набирай сумму и смотри конверсию в пяти валютах.")
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Helper views

@available(iOSApplicationExtension 17.0, *)
private struct InputValueCard: View {
    let amountText: String
    let currency: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Сумма")
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack {
                Text(amountText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .lineLimit(1)
                Spacer()
                Text(currency)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                )
        )
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct OutputValueCard: View {
    let conversion: WidgetConversionDisplay?
    let targetCurrency: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Конвертация")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if let conversion {
                HStack {
                    Text(conversion.converted.formatted(.number.precision(.fractionLength(2))))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .lineLimit(1)
                    Spacer()
                    Text(conversion.code)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Text("курс \(conversion.rate.formatted(.number.precision(.fractionLength(4)))) • \(targetCurrency)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Нет данных")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                )
        )
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct TimestampRow: View {
    let date: Date

    private var formatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }

    var body: some View {
        HStack {
            Text("Обновлено \(formatter.localizedString(for: date, relativeTo: Date()))")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct KeypadMockView: View {
    let amountText: String
    private let keys = [
        [WidgetKeypadButton.digit1, .digit2, .digit3],
        [.digit4, .digit5, .digit6],
        [.digit7, .digit8, .digit9],
        [.decimal, .digit0, .backspace]
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Набери сумму")
                .font(.caption2)
                .foregroundStyle(.secondary)

            ForEach(Array(keys.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { button in
                        Button(intent: WidgetKeypadIntent(button: button)) {
                            KeypadButton(label: button.symbol, accent: accentColor(for: button, row: rowIndex))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 5)
        )
    }

    private func accentColor(for button: WidgetKeypadButton, row: Int) -> Color {
        switch button {
        case .backspace:
            return .red.opacity(0.8)
        case .decimal, .digit0:
            return .orange.opacity(0.8)
        default:
            if row == 0 {
                return Color(red: 0.35, green: 0.68, blue: 0.98).opacity(0.9)
            } else if row == 1 {
                return Color(red: 0.4, green: 0.5, blue: 0.95).opacity(0.9)
            } else if row == 2 {
                return Color(red: 0.55, green: 0.45, blue: 0.98).opacity(0.9)
            } else {
                return Color(red: 0.95, green: 0.65, blue: 0.3).opacity(0.9)
            }
        }
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct KeypadButton: View {
    let label: String
    let accent: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        accent.opacity(0.85),
                        accent.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .frame(height: 18)
            .overlay(
                Text(label)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
            )
            .shadow(color: accent.opacity(0.3), radius: 4, x: 0, y: 3)
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct UnsupportedSizeView: View {
    var body: some View {
        VStack {
            Image(systemName: "rectangle.split.3x1.fill")
                .font(.largeTitle)
            Text("Добавь большой виджет\nв Стеке, чтобы увидеть клавиатуру.")
                .font(.footnote)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Conversion builder

enum WidgetConversionBuilder {
    static func make(with snapshot: ConverterSnapshot) -> [WidgetConversionDisplay] {
        guard let rates = RatesCache.shared.loadRates(), rates.base == snapshot.baseCurrency else {
            return makePlaceholder(base: snapshot.baseCurrency)
        }

        let desiredCodes = CurrencyCatalog.primaryCodes
            .filter { $0 != snapshot.baseCurrency }
            .prefix(5)

        var result: [WidgetConversionDisplay] = []
        for code in desiredCodes {
            guard let rate = rates.rates[code] else { continue }
            let converted = snapshot.amount * rate
            result.append(WidgetConversionDisplay(code: code, rate: rate, converted: converted))
        }

        if result.count < 5 {
            result.append(contentsOf: makePlaceholder(base: snapshot.baseCurrency).dropFirst(result.count))
        }

        return Array(result.prefix(1))
    }

    static func makePlaceholder(base: String) -> [WidgetConversionDisplay] {
        let fallbackCodes = CurrencyCatalog.extendedCodes.filter { $0 != base }.prefix(5)
        let displays = fallbackCodes.map { code in
            let mockRate = Double.random(in: 0.5...120)
            return WidgetConversionDisplay(code: code, rate: mockRate, converted: 100 * mockRate)
        }
        return Array(displays.prefix(1))
    }
}
