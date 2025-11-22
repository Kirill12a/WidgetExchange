//
//  OnboardingView.swift
//  Widget
//
//  Created by Kirill Drozdov on 09.11.2025.
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            title: AppLocale.text(.onboardingSlide1Title),
            description: AppLocale.text(.onboardingSlide1Description),
            accent: Color.purple,
            icon: "rectangle.connected.to.line.below.fill",
            footnote: AppLocale.text(.onboardingSlide1Footnote)
        ),
        OnboardingSlide(
            title: AppLocale.text(.onboardingSlide2Title),
            description: AppLocale.text(.onboardingSlide2Description),
            accent: Color.cyan,
            icon: "bolt.horizontal.circle.fill",
            footnote: AppLocale.text(.onboardingSlide2Footnote)
        ),
        OnboardingSlide(
            title: AppLocale.text(.onboardingSlide3Title),
            description: AppLocale.text(.onboardingSlide3Description),
            accent: Color.orange,
            icon: "crown.fill",
            footnote: AppLocale.text(.onboardingSlide3Footnote)
        )
    ]

    @State private var selectedIndex = 0
    @Namespace private var ctaNamespace

    var body: some View {
        let accent = slides[selectedIndex].accent
        ZStack {
            LinearGradient(
                colors: [accent.opacity(0.2), Color(.systemBackground)],
                startPoint: selectedIndex.isMultiple(of: 2) ? .topLeading : .bottomTrailing,
                endPoint: selectedIndex.isMultiple(of: 2) ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.65), value: selectedIndex)

            VStack(spacing: 32) {
                TabView(selection: $selectedIndex) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                        OnboardingSlideView(slide: slide, isActive: selectedIndex == index)
                            .tag(index)
                            .padding(.horizontal, 24)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                HStack(spacing: 8) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        Circle()
                            .fill(index == selectedIndex ? slides[selectedIndex].accent : Color.gray.opacity(0.3))
                            .frame(width: index == selectedIndex ? 10 : 8, height: index == selectedIndex ? 10 : 8)
                    }
                }

                VStack(spacing: 16) {
                    Button {
                        if selectedIndex < slides.count - 1 {
                            withAnimation(.spring()) {
                                selectedIndex += 1
                            }
                        } else {
                            onFinish()
                        }
                    } label: {
                        Text(selectedIndex == slides.count - 1 ? AppLocale.text(.onboardingPrimaryFinish) : AppLocale.text(.onboardingPrimaryNext))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(accent)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .matchedGeometryEffect(id: "cta", in: ctaNamespace)
                    }
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: selectedIndex)

                    ZStack {
                        if selectedIndex < slides.count - 1 {
                            Button(AppLocale.text(.onboardingSkip)) {
                                onFinish()
                            }
                            .foregroundColor(.secondary)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: selectedIndex)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: selectedIndex)
        }
    }
}

private struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    let isActive: Bool
    @State private var iconPulse = false

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(slide.accent.opacity(0.12))
                    .frame(height: 280)
                    .overlay(
                        ZStack {
                            Circle()
                                .fill(slide.accent.opacity(0.18))
                                .frame(width: 220, height: 220)
                                .offset(x: -20, y: -40)
                                .scaleEffect(iconPulse ? 1.05 : 0.95)
                                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: iconPulse)
                            Circle()
                                .strokeBorder(slide.accent.opacity(0.3), lineWidth: 2)
                                .frame(width: 180, height: 180)
                                .offset(x: 30, y: 10)
                                .scaleEffect(iconPulse ? 1.1 : 0.9)
                                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: iconPulse)
                            Image(systemName: slide.icon)
                                .font(.system(size: 64, weight: .semibold))
                                .foregroundColor(slide.accent)
                                .padding()
                                .background(.ultraThinMaterial, in: Circle())
                                .shadow(color: slide.accent.opacity(0.4), radius: iconPulse ? 18 : 8, x: 0, y: 8)
                                .scaleEffect(isActive ? 1 : 0.9)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isActive)
                        }
                    )

                VStack(alignment: .leading, spacing: 12) {
                    Label(AppLocale.text(.onboardingFeatureTag), systemImage: "sparkles")
                        .font(.footnote)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(slide.accent.opacity(0.15), in: Capsule())

                    Text(AppLocale.text(.onboardingFeatureDescription))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(slide.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(slide.description)
                    .font(.body)
                    .foregroundStyle(.secondary)

                Divider().padding(.vertical, 8)

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "sparkle.magnifyingglass")
                        .foregroundColor(slide.accent)
                    Text(slide.footnote)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scaleEffect(isActive ? 1 : 0.97)
        .opacity(isActive ? 1 : 0.8)
        .animation(.spring(response: 0.55, dampingFraction: 0.85), value: isActive)
        .onAppear {
            iconPulse = true
        }
        .onChange(of: isActive) { active in
            if active {
                iconPulse = true
            }
        }
    }
}
