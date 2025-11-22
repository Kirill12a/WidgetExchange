//
//  ConverterDashboardView.swift
//  Widget
//
//  Created by Kirill Drozdov on 09.11.2025.
//

import SwiftUI
import StoreKit
#if canImport(UIKit)
import UIKit
#endif

struct ConverterDashboardView: View {
    @ObservedObject var viewModel: CurrencyViewModel
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var isKeyboardVisible = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        if let errorMessage = viewModel.errorMessage {
                            OfflineBanner(message: errorMessage)
                        }

                        HeroConversionCard(viewModel: viewModel, isSubscribed: purchaseManager.isSubscribed)

                        AmountInputCard(viewModel: viewModel)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 32)
                }
                .opacity(isKeyboardVisible ? 0 : 1)
                .allowsHitTesting(!isKeyboardVisible)

                if isKeyboardVisible {
                    KeyboardFocusOverlay(viewModel: viewModel) {
#if canImport(UIKit)
                        dismissKeyboardGlobally()
#endif
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isKeyboardVisible = false
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
                }
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
        }
#if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                isKeyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                isKeyboardVisible = false
            }
        }
#endif
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

private struct KeyboardFocusOverlay: View {
    @ObservedObject var viewModel: CurrencyViewModel
    var onDismiss: () -> Void

    @FocusState private var isAmountFieldFocused: Bool

    private var amountBinding: Binding<String> {
        Binding(
            get: { viewModel.amountText },
            set: { viewModel.updateAmount($0) }
        )
    }

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Label("Быстрый ввод", systemImage: "keyboard")
                    .font(.headline)
                Spacer()
                Button {
                    isAmountFieldFocused = false
                    onDismiss()
                } label: {
                    Label("Готово", systemImage: "keyboard.chevron.compact.down")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .padding(10)
                        .background(Color(.secondarySystemBackground), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Скрыть клавиатуру")
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Сумма")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("0", text: amountBinding)
                    .keyboardType(.decimalPad)
                    .textInputAutocapitalization(.never)
                    .focused($isAmountFieldFocused)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                Text("Базовая валюта — \(viewModel.baseCurrency)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 8)

            VStack(alignment: .leading, spacing: 10) {
                Text("Конвертация")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(viewModel.formattedResult)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text(viewModel.targetCurrency)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Text(viewModel.formattedRate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 8)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 40)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            Color(.systemBackground)
                .opacity(0.96)
                .ignoresSafeArea()
        )
        .onAppear {
            DispatchQueue.main.async {
                isAmountFieldFocused = true
            }
        }
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

#if canImport(UIKit)
private func dismissKeyboardGlobally() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
#endif
