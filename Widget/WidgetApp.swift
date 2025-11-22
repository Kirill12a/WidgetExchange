//
//  WidgetApp.swift
//  Widget
//
//  Created by Kirill Drozdov on 09.11.2025.
//

import SwiftUI

@main
struct WidgetApp: App {
    @StateObject private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchaseManager)
        }
    }
}
