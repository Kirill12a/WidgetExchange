//
//  AppTheme.swift
//  Widget
//
//  Centralized palette for light and dark modes in the main app.
//

import SwiftUI

enum AppTheme {
    static func palette(for scheme: ColorScheme) -> Palette {
        scheme == .dark ? Palette.dark : Palette.light
    }

    struct Palette {
        let screenBackground: Color
        let cardBackground: Color
        let secondaryCardBackground: Color
        let accentGradient: [Color]
        let textPrimary: Color
        let textSecondary: Color
        let chipBackground: Color
        let chipForeground: Color
        let overlayBackground: Color
        let overlayCard: Color

        static let light = Palette(
            screenBackground: Color(red: 0.96, green: 0.97, blue: 1.0),
            cardBackground: Color.white,
            secondaryCardBackground: Color(red: 0.93, green: 0.95, blue: 1.0),
            accentGradient: [Color(red: 0.48, green: 0.61, blue: 0.99), Color(red: 0.39, green: 0.84, blue: 0.86)],
            textPrimary: Color(red: 0.09, green: 0.11, blue: 0.18),
            textSecondary: Color(red: 0.32, green: 0.36, blue: 0.46),
            chipBackground: Color(red: 0.89, green: 0.9, blue: 0.96),
            chipForeground: Color(red: 0.15, green: 0.19, blue: 0.31),
            overlayBackground: Color.white.opacity(0.96),
            overlayCard: Color.white
        )

        static let dark = Palette(
            screenBackground: Color(red: 0.05, green: 0.07, blue: 0.12),
            cardBackground: Color(red: 0.1, green: 0.13, blue: 0.2),
            secondaryCardBackground: Color(red: 0.13, green: 0.17, blue: 0.25),
            accentGradient: [Color(red: 0.33, green: 0.44, blue: 0.85), Color(red: 0.33, green: 0.67, blue: 0.72)],
            textPrimary: Color(red: 0.93, green: 0.96, blue: 1.0),
            textSecondary: Color(red: 0.67, green: 0.73, blue: 0.87),
            chipBackground: Color(red: 0.18, green: 0.21, blue: 0.32),
            chipForeground: Color(red: 0.81, green: 0.85, blue: 0.96),
            overlayBackground: Color(red: 0.04, green: 0.05, blue: 0.09).opacity(0.96),
            overlayCard: Color(red: 0.09, green: 0.11, blue: 0.18)
        )
    }
}
