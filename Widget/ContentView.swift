//
//  ContentView.swift
//  Widget
//
//  Created by Kirill Drozdov on 09.11.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CurrencyViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        Group {
            if hasSeenOnboarding {
                ConverterDashboardView(viewModel: viewModel)
            } else {
                OnboardingView {
                    hasSeenOnboarding = true
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: hasSeenOnboarding)
    }
}

#Preview {
    ContentView()
        .environmentObject(PurchaseManager(previewMode: true))
}
