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
            presets: RatesCache.shared.defaultPresets
        )
    }

    func snapshot(for configuration: WidgetFXConfigurationIntent, in context: Context) async -> WidgetFXEntry {
        let snapshot = RatesCache.shared.loadSnapshot() ?? .placeholder
        let presets = RatesCache.shared.loadPresets() ?? RatesCache.shared.defaultPresets
        return WidgetFXEntry(date: snapshot.timestamp, snapshot: snapshot, presets: presets)
    }

    func timeline(for configuration: WidgetFXConfigurationIntent, in context: Context) async -> Timeline<WidgetFXEntry> {
        let snapshot = RatesCache.shared.loadSnapshot() ?? .placeholder
        let presets = RatesCache.shared.loadPresets() ?? RatesCache.shared.defaultPresets

        let now = Date()
        let entry = WidgetFXEntry(date: now, snapshot: snapshot, presets: presets)
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
    @Environment(\.colorScheme) private var colorScheme
    private var palette: WidgetTheme.Palette { WidgetTheme.palette(for: colorScheme) }

    var body: some View {
        ZStack {
            WidgetBackground(palette: palette)
                .padding(4)
            VStack(alignment: .leading, spacing: WidgetTheme.metrics.sectionSpacing) {
                AmountSummaryCard(amountText: entry.snapshot.amountText, currency: entry.snapshot.baseCurrency, palette: palette)
                    // Выносим ключевую сумму в отдельную карточку, чтобы взгляд сразу находил главный показатель.
                ConversionSummaryCard(snapshot: entry.snapshot, palette: palette)
                    // Показываем актуальный таргет из снапшота, избегая рассинхрона с приложением.
                KeypadMockView(amountText: entry.snapshot.amountText, palette: palette)
            }
            .padding(WidgetTheme.metrics.contentPadding)
        }
        .widgetURL(nil)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .transaction { $0.animation = nil }
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
        .configurationDisplayName(LocalizedStringKey(AppLocale.text(.widgetDisplayName)))
        .description(LocalizedStringKey(AppLocale.text(.widgetDescription)))
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Helper views

@available(iOSApplicationExtension 17.0, *)
private struct AmountSummaryCard: View {
    let amountText: String
    let currency: String
    let palette: WidgetTheme.Palette

    var body: some View {
        WidgetSurfaceCard(palette: palette) {
            VStack(alignment: .leading, spacing: WidgetTheme.metrics.cardSpacing) {
                WidgetSectionHeader(title: AppLocale.text(.widgetAmountTitle), subtitle: AppLocale.text(.widgetBaseSubtitle), palette: palette)
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(amountText)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.textPrimary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    CurrencyTag(text: currency, palette: palette)
                }
            }
        }
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct ConversionSummaryCard: View {
    let snapshot: ConverterSnapshot
    let palette: WidgetTheme.Palette

    private var convertedText: String {
        snapshot.converted.formatted(.number.precision(.fractionLength(2)))
    }

    private var rateText: String {
        snapshot.rate.formatted(.number.precision(.fractionLength(4)))
    }

    var body: some View {
        WidgetSurfaceCard(background: palette.surfaceSecondary, palette: palette) {
            VStack(alignment: .leading, spacing: WidgetTheme.metrics.cardSpacing) {
                WidgetSectionHeader(title: AppLocale.text(.widgetConversionTitle), subtitle: nil, palette: palette)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(convertedText)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 6)
                    CurrencyTag(text: snapshot.targetCurrency, palette: palette)
                }
                WidgetDivider(palette: palette)
                Text(AppLocale.text(.rateFormatted, snapshot.baseCurrency, rateText, snapshot.targetCurrency))
                    .font(.caption)
                    .foregroundStyle(palette.textMuted)
            }
        }
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct KeypadMockView: View {
    let amountText: String
    let palette: WidgetTheme.Palette
    private let keys = [
        [WidgetKeypadButton.digit1, .digit2, .digit3],
        [.digit4, .digit5, .digit6],
        [.digit7, .digit8, .digit9],
        [.decimal, .digit0, .backspace]
    ]

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: WidgetTheme.metrics.gridSpacing), count: 3)
    }

    var body: some View {
        WidgetSurfaceCard(background: palette.surfaceSecondary, palette: palette) {
            VStack(alignment: .leading, spacing: WidgetTheme.metrics.cardSpacing) {
                WidgetSectionHeader(title: AppLocale.text(.widgetKeypadTitle), subtitle: nil, palette: palette)
                LazyVGrid(columns: columns, spacing: WidgetTheme.metrics.gridSpacing) {
                    ForEach(Array(keys.enumerated()), id: \.offset) { rowIndex, row in
                        ForEach(row, id: \.self) { button in
                            Button(intent: WidgetKeypadIntent(button: button)) {
                                Text(button.symbol)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(WidgetKeypadButtonStyle(tone: palette.keypadTone(for: button, row: rowIndex)))
#if os(iOS)
                            .hoverEffect(.lift)
#endif
                        }
                    }
                }
            }
        }
    }
}

private struct WidgetDivider: View {
    let palette: WidgetTheme.Palette

    var body: some View {
        Rectangle()
            .fill(palette.divider)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}

private struct CurrencyTag: View {
    let text: String
    let palette: WidgetTheme.Palette

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(palette.textPrimary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(palette.accentSecondary.opacity(0.25))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(palette.accentSecondary.opacity(0.35), lineWidth: 1)
            )
    }
}

private struct WidgetSectionHeader: View {
    let title: String
    var subtitle: String?
    let palette: WidgetTheme.Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2)
                .kerning(0.6)
                .foregroundStyle(palette.textSecondary)
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(palette.textMuted)
            }
        }
    }
}

private struct WidgetSurfaceCard<Content: View>: View {
    var background: Color
    var border: Color
    let content: Content

    init(background: Color? = nil, border: Color? = nil, palette: WidgetTheme.Palette, @ViewBuilder content: () -> Content) {
        self.background = background ?? palette.surfacePrimary
        self.border = border ?? palette.surfaceBorder
        self.content = content()
    }

    var body: some View {
        content
            .padding(WidgetTheme.metrics.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: WidgetTheme.metrics.cardCorner, style: .continuous)
                    .fill(background)
                    .overlay(
                        RoundedRectangle(cornerRadius: WidgetTheme.metrics.cardCorner, style: .continuous)
                            .stroke(border, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
    }
}

private struct WidgetBackground: View {
    let palette: WidgetTheme.Palette

    var body: some View {
        RoundedRectangle(cornerRadius: WidgetTheme.metrics.containerCorner, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [palette.backgroundTop, palette.backgroundBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: WidgetTheme.metrics.containerCorner, style: .continuous)
                    .stroke(palette.surfaceHighlight.opacity(0.3), lineWidth: 1)
            )
            .overlay(
                RadialGradient(
                    colors: [palette.backgroundAccent.opacity(0.35), .clear],
                    center: .topLeading,
                    startRadius: 20,
                    endRadius: 160
                )
                .blendMode(.softLight)
                .clipShape(RoundedRectangle(cornerRadius: WidgetTheme.metrics.containerCorner, style: .continuous))
            )
            .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct WidgetKeypadButtonStyle: ButtonStyle {
    let tone: WidgetTheme.ButtonTone

    func makeBody(configuration: Configuration) -> some View {
        WidgetKeypadButtonBody(configuration: configuration, tone: tone)
    }

    private struct WidgetKeypadButtonBody: View {
        @Environment(\.isEnabled) private var isEnabled
        @State private var isHovered = false

        let configuration: ButtonStyle.Configuration
        let tone: WidgetTheme.ButtonTone

        var body: some View {
            let labelColor = isEnabled ? tone.label : tone.inactiveLabel
            configuration.label
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(labelColor)
                .frame(maxWidth: .infinity, minHeight: WidgetTheme.metrics.keypadButtonHeight)
                .background(
                    RoundedRectangle(cornerRadius: WidgetTheme.metrics.keypadButtonCorner, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [tone.start, tone.end],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(isEnabled ? 1 : 0.4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: WidgetTheme.metrics.keypadButtonCorner, style: .continuous)
                        .stroke(tone.border.opacity(isEnabled ? 1 : 0.4), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: WidgetTheme.metrics.keypadButtonCorner, style: .continuous)
                        .fill(Color.white.opacity(configuration.isPressed ? 0.15 : 0.02))
                        .blendMode(.softLight)
                )
                .shadow(color: tone.shadow.opacity(configuration.isPressed ? 0.2 : (isHovered ? 0.45 : 0.35)), radius: configuration.isPressed ? 4 : (isHovered ? 10 : 7), x: 0, y: configuration.isPressed ? 2 : 6)
                .scaleEffect(configuration.isPressed ? 0.95 : (isHovered ? 1.02 : 1))
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
                .animation(.easeOut(duration: 0.18), value: isHovered)
#if os(iOS) || os(macOS)
                .onHover { hover in
                    isHovered = hover
                }
#endif
        }
    }
}

@available(iOSApplicationExtension 17.0, *)
private struct UnsupportedSizeView: View {
    var body: some View {
        VStack {
            Image(systemName: "rectangle.split.3x1.fill")
                .font(.largeTitle)
            Text(AppLocale.text(.widgetUnsupported))
                .font(.footnote)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
