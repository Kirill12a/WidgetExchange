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
        ZStack {
            if hasSeenOnboarding {
                ConverterDashboardView(viewModel: viewModel)
                    .transition(.dashboardEnter)
                    .zIndex(1)
            }

            if !hasSeenOnboarding {
                OnboardingView {
                    withAnimation(.spring(response: 0.65, dampingFraction: 0.85)) {
                        hasSeenOnboarding = true
                    }
                }
                .transition(.onboardingExit)
                .zIndex(2)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .animation(.spring(response: 0.65, dampingFraction: 0.85, blendDuration: 0.2), value: hasSeenOnboarding)
    }
}

#Preview {
    ContentView()
        .environmentObject(PurchaseManager(previewMode: true))
}

private struct DepthTransitionModifier: ViewModifier {
    let scale: CGFloat
    let opacity: Double
    let rotation: Double
    let blur: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .rotation3DEffect(.degrees(rotation), axis: (x: 1, y: 0, z: 0), perspective: 0.9)
            .blur(radius: blur)
    }
}

private extension AnyTransition {
    static var onboardingExit: AnyTransition {
        .modifier(
            active: DepthTransitionModifier(scale: 0.85, opacity: 0, rotation: 18, blur: 6),
            identity: DepthTransitionModifier(scale: 1, opacity: 1, rotation: 0, blur: 0)
        )
    }

    static var dashboardEnter: AnyTransition {
        .modifier(
            active: DepthTransitionModifier(scale: 1.08, opacity: 0, rotation: -10, blur: 4),
            identity: DepthTransitionModifier(scale: 1, opacity: 1, rotation: 0, blur: 0)
        )
    }
}
