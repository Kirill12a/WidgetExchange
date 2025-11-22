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
            title: "Конвертер прямо в виджете",
            description: "Добавь виджет на сайт, POS или инфопанель — курсы обновляются каждые 60 секунд и принимают запросы извне.",
            accent: Color.purple,
            icon: "rectangle.connected.to.line.below.fill",
            footnote: "Генерируй токены и ограничивай пары, чтобы не бояться утечек."
        ),
        OnboardingSlide(
            title: "Умные подсказки",
            description: "Создавай пресеты конверсий, лимиты и push-оповещения для команды.",
            accent: Color.cyan,
            icon: "bolt.horizontal.circle.fill",
            footnote: "Поддержка 30+ валют и ночное кэширование, чтобы приложение работало офлайн."
        ),
        OnboardingSlide(
            title: "Pro-подписка",
            description: "Убирай рекламу, получай веб-дэшборд, CSV-экспорт и доступ к истории за год.",
            accent: Color.orange,
            icon: "crown.fill",
            footnote: "Две недели бесплатно — дальше дешевле, чем чашка кофе."
        )
    ]

    @State private var selectedIndex = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [slides[selectedIndex].accent.opacity(0.15), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                TabView(selection: $selectedIndex) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                        OnboardingSlideView(slide: slide)
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
                        Text(selectedIndex == slides.count - 1 ? "Начать конвертировать" : "Дальше")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(slides[selectedIndex].accent)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }

                    if selectedIndex < slides.count - 1 {
                        Button("Пропустить виджет-тур") {
                            onFinish()
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

private struct OnboardingSlideView: View {
    let slide: OnboardingSlide

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
                            Circle()
                                .strokeBorder(slide.accent.opacity(0.3), lineWidth: 2)
                                .frame(width: 180, height: 180)
                                .offset(x: 30, y: 10)
                            Image(systemName: slide.icon)
                                .font(.system(size: 64, weight: .semibold))
                                .foregroundColor(slide.accent)
                                .padding()
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    )

                VStack(alignment: .leading, spacing: 12) {
                    Label("Главная фича", systemImage: "sparkles")
                        .font(.footnote)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(slide.accent.opacity(0.15), in: Capsule())

                    Text("Виджет принимает POST запрос и отвечает конверсией <3 сек.")
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
    }
}
