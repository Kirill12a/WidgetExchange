//
//  WidgetTheme.swift
//  WidgetFXWidgetExtension
//
//  Centralized palette and layout metrics for the widget.
//

import SwiftUI

enum WidgetTheme {
    static func palette(for scheme: ColorScheme) -> Palette {
        scheme == .dark ? WidgetTheme.dark : WidgetTheme.light
    }
    static let metrics = Metrics()

    struct Palette {
        let backgroundTop: Color
        let backgroundBottom: Color
        let backgroundAccent: Color

        let surfacePrimary: Color
        let surfaceSecondary: Color
        let surfaceBorder: Color
        let surfaceHighlight: Color

        let textPrimary: Color
        let textSecondary: Color
        let textMuted: Color

        let accentPrimary: Color
        let accentSecondary: Color
        let accentTertiary: Color
        let destructive: Color

        let divider: Color

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

    static let dark = Palette(
        backgroundTop: Color(red: 0.05, green: 0.08, blue: 0.16),
        backgroundBottom: Color(red: 0.07, green: 0.11, blue: 0.24),
        backgroundAccent: Color(red: 0.24, green: 0.41, blue: 0.91),
        surfacePrimary: Color(red: 0.13, green: 0.16, blue: 0.24),
        surfaceSecondary: Color(red: 0.16, green: 0.2, blue: 0.29),
        surfaceBorder: Color.white.opacity(0.08),
        surfaceHighlight: Color.white.opacity(0.2),
        textPrimary: Color.white,
        textSecondary: Color.white.opacity(0.72),
        textMuted: Color.white.opacity(0.5),
        accentPrimary: Color(red: 0.4, green: 0.8, blue: 0.76),
        accentSecondary: Color(red: 0.54, green: 0.69, blue: 0.96),
        accentTertiary: Color(red: 0.78, green: 0.61, blue: 0.98),
        destructive: Color(red: 1.0, green: 0.43, blue: 0.52),
        divider: Color.white.opacity(0.12)
    )

    static let light = Palette(
        backgroundTop: Color(red: 0.87, green: 0.9, blue: 0.98),
        backgroundBottom: Color(red: 0.94, green: 0.96, blue: 1.0),
        backgroundAccent: Color(red: 0.4, green: 0.56, blue: 0.96),
        surfacePrimary: Color.white,
        surfaceSecondary: Color(red: 0.93, green: 0.95, blue: 1.0),
        surfaceBorder: Color.black.opacity(0.06),
        surfaceHighlight: Color.white.opacity(0.6),
        textPrimary: Color(red: 0.1, green: 0.12, blue: 0.18),
        textSecondary: Color(red: 0.32, green: 0.36, blue: 0.46),
        textMuted: Color(red: 0.53, green: 0.57, blue: 0.67),
        accentPrimary: Color(red: 0.19, green: 0.57, blue: 0.93),
        accentSecondary: Color(red: 0.37, green: 0.63, blue: 1.0),
        accentTertiary: Color(red: 0.58, green: 0.54, blue: 0.96),
        destructive: Color(red: 0.92, green: 0.33, blue: 0.39),
        divider: Color.black.opacity(0.08)
    )


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
