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

                    if selectedIndex < slides.count - 1 {
                        Button(AppLocale.text(.onboardingSkip)) {
                            onFinish()
                        }
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                    }
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
            WidgetPreviewCard(slide: slide, isActive: isActive, iconPulse: iconPulse)

            VStack(alignment: .leading, spacing: 12) {
                Text(slide.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(slide.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

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
            if !active {
                iconPulse = false
            } else {
                iconPulse = true
            }
        }
    }
}

private struct WidgetPreviewCard: View {
    let slide: OnboardingSlide
    let isActive: Bool
    let iconPulse: Bool

    private var showsOfflineBadge: Bool {
        slide.icon == "bolt.horizontal.circle.fill"
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 32)
            .fill(
                LinearGradient(
                    colors: [slide.accent.opacity(0.4), slide.accent.opacity(0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Label(AppLocale.text(.onboardingWidgetBadge), systemImage: "rectangle.grid.2x2")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.15), in: Capsule())
                        Spacer()
                        Image(systemName: slide.icon)
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.12), in: Circle())
                            .shadow(color: .black.opacity(0.2), radius: iconPulse ? 20 : 10, x: 0, y: 8)
                            .scaleEffect(isActive ? 1 : 0.92)
                    }

                    VStack(spacing: 12) {
                        PreviewRow(title: AppLocale.text(.widgetAmountTitle), value: "12 970 USD")
                        PreviewRow(title: AppLocale.text(.widgetConversionTitle), value: "11 985 EUR")
                        PreviewRow(title: AppLocale.text(.rateFormatted, "USD", "0.92", "EUR"), value: AppLocale.text(.overlayConversion))
                    }

                    if showsOfflineBadge {
                        Label(AppLocale.text(.onboardingOfflineBadge), systemImage: "wifi.slash")
                            .font(.footnote)
                            .foregroundStyle(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.white.opacity(0.15), in: Capsule())
                    }
                }
                .padding(24)
            )
            .frame(height: 260)
            .scaleEffect(isActive ? 1 : 0.97)
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: isActive)
    }
}

private struct PreviewRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.7))
                Text(value)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 18))
    }
}
