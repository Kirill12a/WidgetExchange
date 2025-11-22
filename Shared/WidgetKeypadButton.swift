//
//  WidgetKeypadButton.swift
//  Widget
//
//  Created by Kirill Drozdov on 09.11.2025.
//

import AppIntents

enum WidgetKeypadButton: String, AppEnum {
    case digit0, digit1, digit2, digit3, digit4, digit5, digit6, digit7, digit8, digit9
    case decimal
    case backspace

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Keypad Button")

    static var caseDisplayRepresentations: [WidgetKeypadButton: DisplayRepresentation] = [
        .digit0: "0",
        .digit1: "1",
        .digit2: "2",
        .digit3: "3",
        .digit4: "4",
        .digit5: "5",
        .digit6: "6",
        .digit7: "7",
        .digit8: "8",
        .digit9: "9",
        .decimal: ".",
        .backspace: "⌫"
    ]

    var symbol: String {
        switch self {
        case .digit0: return "0"
        case .digit1: return "1"
        case .digit2: return "2"
        case .digit3: return "3"
        case .digit4: return "4"
        case .digit5: return "5"
        case .digit6: return "6"
        case .digit7: return "7"
        case .digit8: return "8"
        case .digit9: return "9"
        case .decimal: return "."
        case .backspace: return "⌫"
        }
    }
}
