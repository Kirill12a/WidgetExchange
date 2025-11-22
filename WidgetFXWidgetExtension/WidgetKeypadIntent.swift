//
//  WidgetKeypadIntent.swift
//  WidgetFXWidgetExtension
//
//  Created by Kirill Drozdov on 09.11.2025.
//

import AppIntents

struct WidgetKeypadIntent: AppIntent {
    static var title: LocalizedStringResource = "Widget Keypad Input"
    static var description = IntentDescription("Instantly updates widget input field.")

    @Parameter(title: "Button")
    var button: WidgetKeypadButton

    init() {}

    init(button: WidgetKeypadButton) {
        self.button = button
    }

    func perform() async throws -> some IntentResult {
        WidgetInputController.shared.handle(button: button)
        return .result()
    }
}

struct WidgetFXConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Widget FX"
    static var description = IntentDescription("Widget FX configuration")
}
