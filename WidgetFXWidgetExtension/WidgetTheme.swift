//
//  WidgetTheme.swift
//  WidgetFXWidgetExtension
//
//  Centralized palette and layout metrics for the widget.
//

import SwiftUI

enum WidgetTheme {
    static let palette = Palette()
    static let metrics = Metrics()

    struct Palette {
        let backgroundTop = Color(red: 0.05, green: 0.08, blue: 0.16)
        let backgroundBottom = Color(red: 0.07, green: 0.11, blue: 0.24)
        let backgroundAccent = Color(red: 0.24, green: 0.41, blue: 0.91)

        let surfacePrimary = Color(red: 0.13, green: 0.16, blue: 0.24)
        let surfaceSecondary = Color(red: 0.16, green: 0.2, blue: 0.29)
        let surfaceBorder = Color.white.opacity(0.08)
        let surfaceHighlight = Color.white.opacity(0.2)

        let textPrimary = Color.white
        let textSecondary = Color.white.opacity(0.72)
        let textMuted = Color.white.opacity(0.5)

        let accentPrimary = Color(red: 0.4, green: 0.8, blue: 0.76)
        let accentSecondary = Color(red: 0.54, green: 0.69, blue: 0.96)
        let accentTertiary = Color(red: 0.78, green: 0.61, blue: 0.98)
        let destructive = Color(red: 1.0, green: 0.43, blue: 0.52)

        let divider = Color.white.opacity(0.12)

        func keypadTone(for button: WidgetKeypadButton, row: Int) -> ButtonTone {
            switch button {
            case .backspace:
                return ButtonTone(start: destructive.opacity(0.85), end: destructive.opacity(0.55), border: destructive.opacity(0.9), shadow: destructive.opacity(0.45), label: textPrimary, inactiveLabel: textMuted)
            case .decimal, .digit0:
                return ButtonTone(start: accentTertiary.opacity(0.85), end: accentTertiary.opacity(0.5), border: accentTertiary.opacity(0.9), shadow: accentTertiary.opacity(0.35), label: textPrimary, inactiveLabel: textMuted)
            default:
                let tiers = [accentPrimary, accentSecondary, accentTertiary.opacity(0.9)]
                let index = min(row, tiers.count - 1)
                let base = tiers[index]
                return ButtonTone(start: base.opacity(0.9), end: base.opacity(0.55), border: base.opacity(0.9), shadow: base.opacity(0.35), label: textPrimary, inactiveLabel: textMuted)
            }
        }
    }

    struct Metrics {
        let containerCorner: CGFloat = 20
        let contentPadding: CGFloat = 8
        let sectionSpacing: CGFloat = 8
        let cardCorner: CGFloat = 14
        let cardPadding: CGFloat = 10
        let subCardPadding: CGFloat = 8
        let cardSpacing: CGFloat = 8
        let gridSpacing: CGFloat = 4
        let keypadButtonHeight: CGFloat = 22
        let keypadButtonCorner: CGFloat = 8
    }

    struct ButtonTone {
        let start: Color
        let end: Color
        let border: Color
        let shadow: Color
        let label: Color
        let inactiveLabel: Color
    }
}
