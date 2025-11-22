//
//  ConverterDashboardView.swift
//  Widget
//
//  Created by Kirill Drozdov on 09.11.2025.
//

import SwiftUI
import StoreKit

struct ConverterDashboardView: View {
    @ObservedObject var viewModel: CurrencyViewModel
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var isEditingPresets = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let errorMessage = viewModel.errorMessage {
                        OfflineBanner(message: errorMessage)
                    }

                    HeroConversionCard(viewModel: viewModel, isSubscribed: purchaseManager.isSubscribed)

                    AmountInputCard(viewModel: viewModel)

                    QuickPairsView { base, target in
                        viewModel.selectBase(base)
                        viewModel.selectTarget(target)
                    }

                    RateTrendCard(viewModel: viewModel)

                    if purchaseManager.isSubscribed {
                        ProStatusCard()
                    } else {
                        AdBannerView(
                            title: "Нативный баннер",
                            message: "Брендированные размещения рядом с калькулятором. CTR выше на 43%.",
                            accent: .indigo,
                            cta: "Подключить"
                        )
                    }

                    SubscriptionCard(purchaseManager: purchaseManager)

                    if !purchaseManager.isSubscribed {
                        AdBannerView(
                            title: "Баннер в аналитике",
                            message: "Мягкий показ во вкладке графиков. Алгоритм не раздражает частых пользователей.",
                            accent: .orange,
                            cta: "Показать пример"
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Widget FX")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.refreshRates()
                            await viewModel.refreshTrend()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                    }
                }
            }
            .task {
                viewModel.load()
            }
            .refreshable {
                await viewModel.refreshRates()
                await viewModel.refreshTrend()
            }
            .sheet(isPresented: $isEditingPresets) {
                WidgetPresetEditorSheet(viewModel: viewModel)
                    .presentationDetents([.large])
            }
        }
    }
}

// MARK: - Hero card

private struct HeroConversionCard: View {
    @ObservedObject var viewModel: CurrencyViewModel
    let isSubscribed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Виджет онлайн", systemImage: "antenna.radiowaves.left.and.right")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if isSubscribed {
                Label("Converter Pro активна", systemImage: "crown.fill")
                    .font(.caption)
                    .padding(8)
                    .background(Color.yellow.opacity(0.2), in: Capsule())
            }

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(viewModel.formattedResult)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.7)
                Text(viewModel.targetCurrency)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Text(viewModel.formattedRate)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            HStack {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Веб/TV/банкомат")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(viewModel.heroCopy)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(colors: [Color.accentColor.opacity(0.15), Color(.systemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .topTrailing) {
            if let updated = viewModel.lastUpdated {
                Text(updated, style: .time)
                    .font(.caption2)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .offset(x: -12, y: 12)
            }
        }
    }
}

// MARK: - Amount + selectors

private struct AmountInputCard: View {
    @ObservedObject var viewModel: CurrencyViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Сумма")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    TextField("0", text: Binding(
                        get: { viewModel.amountText },
                        set: { viewModel.updateAmount($0) }
                    ))
                    .keyboardType(.decimalPad)
                    .font(.title2.weight(.semibold))
                }

                Spacer()

                Button {
                    viewModel.swapCurrencies()
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                        .font(.title2)
                        .symbolEffect(.pulse.byLayer, options: .repeat(1))
                }
                .buttonStyle(.plain)
            }

            CurrencyPickerRow(label: "Из", selection: viewModel.baseCurrency, options: viewModel.availableCurrencies) { code in
                viewModel.selectBase(code)
            }

            CurrencyPickerRow(label: "В", selection: viewModel.targetCurrency, options: viewModel.availableCurrencies) { code in
                viewModel.selectTarget(code)
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 8)
    }
}

private struct CurrencyPickerRow: View {
    let label: String
    let selection: String
    let options: [String]
    let didSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption)
                .foregroundStyle(.secondary)

            Menu {
                ForEach(options, id: \.self) { code in
                    Button(code) { didSelect(code) }
                }
            } label: {
                HStack {
                    Text(selection)
                        .font(.title3.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

// MARK: - Quick pairs

private struct QuickPairsView: View {
    let action: (String, String) -> Void

    private let quickPairs: [(title: String, base: String, target: String, context: String)] = [
        ("Виджет магазина", "USD", "RUB", "Black Friday"),
        ("POS Казахстан", "EUR", "KZT", "Сеть NB"),
        ("Дубай бутик", "USD", "AED", "VIP lounge")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Быстрые сценарии")
                .font(.headline)

            ForEach(quickPairs, id: \.title) { pair in
                Button {
                    action(pair.base, pair.target)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(pair.title)
                                .fontWeight(.semibold)
                            Text("\(pair.base) → \(pair.target)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(pair.context)
                            .font(.footnote)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6), in: Capsule())
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Trend card

private struct RateTrendCard: View {
    @ObservedObject var viewModel: CurrencyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("7 дней динамики")
                        .font(.headline)
                    Text("Данные кэшируются на бэкенде, чтобы виджеты отвечали за 80 мс.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Label("Pro insight", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.caption)
                    .padding(8)
                    .background(Color(.systemGray6), in: Capsule())
            }

            SparklineView(points: viewModel.chartSeries)
                .frame(height: 140)

            HStack {
                VStack(alignment: .leading) {
                    Text("Формат экспорта")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("CSV • JSON • Webhook")
                        .font(.subheadline)
                }
                Spacer()
                Button("Экспортировать") {}
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
    }
}

private struct SparklineView: View {
    let points: [RatePoint]

    var body: some View {
        GeometryReader { geometry in
            let normalized = normalizedPoints(in: geometry.size)

            ZStack {
                if normalized.count > 1 {
                    Path { path in
                        guard let first = normalized.first else { return }
                        path.move(to: first)
                        normalized.dropFirst().forEach { path.addLine(to: $0) }
                    }
                    .stroke(
                        LinearGradient(colors: [.mint, .blue], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )

                    LinearGradient(colors: [.blue.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom)
                        .mask(
                            Path { path in
                                guard let first = normalized.first,
                                      let last = normalized.last else { return }
                                path.move(to: first)
                                normalized.dropFirst().forEach { path.addLine(to: $0) }
                                path.addLine(to: CGPoint(x: last.x, y: geometry.size.height))
                                path.addLine(to: CGPoint(x: first.x, y: geometry.size.height))
                                path.closeSubpath()
                            }
                        )
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard points.count > 1,
              let minValue = points.map(\.value).min(),
              let maxValue = points.map(\.value).max(),
              maxValue - minValue > 0 else {
            let midY = size.height / 2
            let stepX = points.isEmpty ? 0 : size.width / CGFloat(max(points.count - 1, 1))
            return points.enumerated().map { index, _ in
                CGPoint(x: CGFloat(index) * stepX, y: midY)
            }
        }

        let range = maxValue - minValue
        let stepX = size.width / CGFloat(points.count - 1)
        return points.enumerated().map { index, point in
            let normalizedY = (point.value - minValue) / range
            let x = CGFloat(index) * stepX
            let y = size.height * (1 - CGFloat(normalizedY))
            return CGPoint(x: x, y: y)
        }
    }
}

private struct WidgetSnippetView: View {
    let endpoint: String
    let from: String
    let to: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("curl пример")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("""
            curl -X POST \\
              \(endpoint) \\
              -d '{ "from": "\(from)", "to": "\(to)", "amount": 100 }'
            """)
            .font(.system(.footnote, design: .monospaced))
            .padding(12)
            .background(Color(.black).opacity(0.85), in: RoundedRectangle(cornerRadius: 12))
            .foregroundColor(.green)
        }
    }
}

private struct FlexibleChipGrid: View {
    let presets: [WidgetPreset]
    let base: String
    let target: String
    let rate: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            let rows = Array(presets.chunked(into: 3))
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.id) { preset in
                        WidgetPresetChipView(preset: preset, base: base, target: target, rate: rate)
                    }
                    if row.count < 3 {
                        ForEach(0..<(3 - row.count), id: \.self) { _ in
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

private struct WidgetPresetChipView: View {
    let preset: WidgetPreset
    let base: String
    let target: String
    let rate: Double?

    private var convertedText: String {
        guard let rate else { return "— \(target)" }
        let converted = preset.amount * rate
        return converted.formatted(.number.precision(.fractionLength(2))) + " \(target)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(preset.title)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(preset.amount.formatted(.number.precision(.fractionLength(0...2)))) \(base)")
                .font(.subheadline.weight(.semibold))
            Text(convertedText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct WidgetPresetEditorSheet: View {
    @ObservedObject var viewModel: CurrencyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var localPresets: [WidgetPreset]

    init(viewModel: CurrencyViewModel) {
        self.viewModel = viewModel
        _localPresets = State(initialValue: viewModel.widgetPresets)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Суммы") {
                    ForEach($localPresets) { $preset in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Название", text: $preset.title)
                                .textInputAutocapitalization(.words)
                            TextField("Сумма", value: $preset.amount, format: .number.precision(.fractionLength(0...2)))
                                .keyboardType(.decimalPad)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        localPresets.remove(atOffsets: offsets)
                    }

                    Button {
                        localPresets.append(WidgetPreset(title: "Новая сумма", amount: 10))
                    } label: {
                        Label("Добавить сумму", systemImage: "plus.circle")
                    }
                    .disabled(localPresets.count >= 6)
                }

                Section {
                    Button("Сбросить на дефолт") {
                        localPresets = RatesCache.shared.defaultPresets
                    }
                }
            }
            .navigationTitle("Виджет-суммы")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        let cleaned = localPresets
                            .map { WidgetPreset(id: $0.id, title: $0.title.isEmpty ? "\($0.amount)" : $0.title, amount: max(0, $0.amount)) }
                            .filter { $0.amount > 0.01 }
                        viewModel.updateWidgetPresets(cleaned)
                        dismiss()
                    }
                    .disabled(localPresets.isEmpty)
                }
            }
        }
    }
}

// MARK: - Ads + subscription

private struct AdBannerView: View {
    let title: String
    let message: String
    let accent: Color
    let cta: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button(cta) {}
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accent.opacity(0.15), in: Capsule())
            }
            Spacer()
            Image(systemName: "megaphone.fill")
                .font(.largeTitle)
                .foregroundStyle(accent)
        }
        .padding()
        .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
    }
}

private struct ProStatusCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "waveform.path.ecg.rectangle")
                .font(.title)
                .foregroundColor(.green)
                .padding(12)
                .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 6) {
                Text("Реклама отключена")
                    .font(.headline)
                Text("Converter Pro держит API и виджеты в приоритете. Слоты на экране свободны.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
    }
}

private struct SubscriptionCard: View {
    @ObservedObject var purchaseManager: PurchaseManager
    let perks = [
        "Без рекламы и лимитов",
        "Безлимитные виджеты и веб-дэшборд",
        "Экспорт истории и push на пороговые значения"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Converter Pro")
                        .font(.title2.weight(.bold))
                    Text(purchaseSubtitle)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: purchaseManager.isSubscribed ? "checkmark.seal.fill" : "crown.fill")
                    .foregroundColor(purchaseManager.isSubscribed ? .green : .yellow)
                    .font(.title)
            }

            ForEach(perks, id: \.self) { perk in
                Label(perk, systemImage: "checkmark.seal.fill")
                    .symbolRenderingMode(.multicolor)
            }

            if purchaseManager.isSubscribed {
                Text("Подписка уже активна на всех устройствах. Управляйте в настройках Apple ID.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                SubscriptionProductList(purchaseManager: purchaseManager)
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 12)
    }

    private var purchaseSubtitle: String {
        if purchaseManager.isSubscribed {
            return "Спасибо за поддержку! Converter Pro активен."
        }
        return "14 дней бесплатно, потом ₽399 / мес или ₽3 499 / год."
    }
}

private struct SubscriptionProductList: View {
    @ObservedObject var purchaseManager: PurchaseManager

    var body: some View {
        VStack(spacing: 12) {
            if let info = purchaseManager.infoMessage {
                Text(info)
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if purchaseManager.products.isEmpty {
                PlaceholderPlanRow(title: "Месяц", price: "₽399", description: "Для тестов и коротких спринтов.")
                PlaceholderPlanRow(title: "Год", price: "₽3 499", description: "Экономия 27% и бонусные алерты.")
            } else {
                ForEach(purchaseManager.products, id: \.id) { product in
                    ProductRow(product: product, purchaseManager: purchaseManager)
                }
            }

            HStack(spacing: 12) {
                Button("Восстановить покупки") {
                    Task { await purchaseManager.restore() }
                }
                .buttonStyle(.bordered)

                if case .failed(let message) = purchaseManager.purchaseState {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
    }
}

private struct ProductRow: View {
    let product: Product
    @ObservedObject var purchaseManager: PurchaseManager

    var body: some View {
        Button {
            Task {
                await purchaseManager.purchase(product)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .fontWeight(.semibold)
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    if purchaseManager.purchaseState.isPurchasing(productID: product.id) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.primary)
                    }
                    Text(product.displayPrice)
                        .font(.headline)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(purchaseManager.purchaseState.isPurchasing(productID: product.id))
    }
}

private struct PlaceholderPlanRow: View {
    let title: String
    let price: String
    let description: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(price)
                .font(.headline)
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct OfflineBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(16)
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        var chunks: [[Element]] = []
        var index = 0
        while index < count {
            let end = Swift.min(index + size, count)
            chunks.append(Array(self[index..<end]))
            index += size
        }
        return chunks
    }
}
