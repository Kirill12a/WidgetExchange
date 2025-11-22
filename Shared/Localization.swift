//
//  Localization.swift
//  Widget
//
//  Simple localization helper shared between app and widget targets.
//

import Foundation

enum AppLocale {
    enum Key: String {
        case dashboardTitle = "dashboard.title"
        case heroStatusOnline = "hero.status.online"
        case heroStatusPro = "hero.status.pro"
        case heroChannelTag = "hero.channel.tag"
        case heroCopyMany = "hero.copy.many"
        case heroCopyDefault = "hero.copy.default"
        case amountLabel = "amount.label"
        case pickerFrom = "picker.from"
        case pickerTo = "picker.to"
        case quickInputTitle = "overlay.quickInput"
        case overlayDone = "overlay.done"
        case overlayDismissAccessibility = "overlay.dismiss"
        case overlayBaseCurrency = "overlay.baseCurrency"
        case overlayConversion = "overlay.conversion"
        case rateUnavailable = "rate.unavailable"
        case rateFormatted = "rate.formatted"
        case errorRatesUnavailable = "error.ratesUnavailable"
        case purchaseLoadError = "purchase.loadError"
        case purchaseUnknownStatus = "purchase.unknownStatus"
        case purchaseUnverified = "purchase.unverified"
        case onboardingSlide1Title = "onboarding.slide1.title"
        case onboardingSlide1Description = "onboarding.slide1.description"
        case onboardingSlide1Footnote = "onboarding.slide1.footnote"
        case onboardingSlide2Title = "onboarding.slide2.title"
        case onboardingSlide2Description = "onboarding.slide2.description"
        case onboardingSlide2Footnote = "onboarding.slide2.footnote"
        case onboardingSlide3Title = "onboarding.slide3.title"
        case onboardingSlide3Description = "onboarding.slide3.description"
        case onboardingSlide3Footnote = "onboarding.slide3.footnote"
        case onboardingFeatureTag = "onboarding.feature.tag"
        case onboardingFeatureDescription = "onboarding.feature.description"
        case onboardingPrimaryNext = "onboarding.primary.next"
        case onboardingPrimaryFinish = "onboarding.primary.finish"
        case onboardingSkip = "onboarding.skip"
        case currencyInvalidResponse = "currency.invalidResponse"
        case currencyDateRange = "currency.dateRange"
        case intentKeypadDescription = "intent.keypad.description"
        case intentWidgetDescription = "intent.widget.description"
        case widgetAmountTitle = "widget.amountTitle"
        case widgetBaseSubtitle = "widget.baseSubtitle"
        case widgetConversionTitle = "widget.conversionTitle"
        case widgetKeypadTitle = "widget.keypadTitle"
        case widgetTimestamp = "widget.timestamp"
        case widgetDisplayName = "widget.displayName"
        case widgetDescription = "widget.description"
        case widgetUnsupported = "widget.unsupported"
    }

    static func text(_ key: Key, _ args: CVarArg...) -> String {
        let languageCode: String
        if #available(iOS 16.0, *) {
            languageCode = Locale.current.language.languageCode?.identifier ?? Locale.current.identifier
        } else {
            languageCode = Locale.current.languageCode ?? Locale.current.identifier
        }
        let normalized = languageCode.starts(with: "ru") ? "ru" : "en"
        let template = translations[normalized]?[key.rawValue] ?? translations["en"]?[key.rawValue] ?? key.rawValue
        guard !args.isEmpty else { return template }
        return String(format: template, locale: Locale(identifier: normalized), arguments: args)
    }

    private static let translations: [String: [String: String]] = [
        "en": [
            Key.dashboardTitle.rawValue: "Widget FX",
            Key.heroStatusOnline.rawValue: "Widget is online",
            Key.heroStatusPro.rawValue: "Converter Pro active",
            Key.heroChannelTag.rawValue: "Omnichannel",
            Key.heroCopyMany.rawValue: "Widgets deliver rates for %d scenarios.",
            Key.heroCopyDefault.rawValue: "Ship fresh FX rates to dashboards and TV walls.",
            Key.amountLabel.rawValue: "Amount",
            Key.pickerFrom.rawValue: "From",
            Key.pickerTo.rawValue: "To",
            Key.quickInputTitle.rawValue: "Quick input",
            Key.overlayDone.rawValue: "Done",
            Key.overlayDismissAccessibility.rawValue: "Dismiss keyboard",
            Key.overlayBaseCurrency.rawValue: "Base currency — %@",
            Key.overlayConversion.rawValue: "Conversion",
            Key.rateUnavailable.rawValue: "Rate unavailable",
            Key.rateFormatted.rawValue: "1 %@ = %@ %@",
            Key.errorRatesUnavailable.rawValue: "Could not refresh rates: %@. Showing cached data.",
            Key.purchaseLoadError.rawValue: "Unable to load subscriptions: %@",
            Key.purchaseUnknownStatus.rawValue: "Unknown purchase status",
            Key.purchaseUnverified.rawValue: "Purchase not verified.",
            Key.onboardingSlide1Title.rawValue: "One-touch widget",
            Key.onboardingSlide1Description.rawValue: "Enter the amount and choose currencies right from the Home Screen — no full app launch needed.",
            Key.onboardingSlide1Footnote.rawValue: "Large digits, bold contrast, and haptics make daily input effortless.",
            Key.onboardingSlide2Title.rawValue: "Offline resiliency",
            Key.onboardingSlide2Description.rawValue: "Latest rates stay cached, so conversions keep working even in airplane mode or tunnels.",
            Key.onboardingSlide2Footnote.rawValue: "When network returns, background sync refreshes data automatically.",
            Key.onboardingSlide3Title.rawValue: "Everywhere, consistent",
            Key.onboardingSlide3Description.rawValue: "Phone, tablet, or info panel — the widget layout adapts while keeping the same flow.",
            Key.onboardingSlide3Footnote.rawValue: "Portrait and landscape states are tuned for thumb reach and kiosk displays.",
            Key.onboardingFeatureTag.rawValue: "Built for operators",
            Key.onboardingFeatureDescription.rawValue: "All controls sit within the thumb zone and respond with subtle haptics.",
            Key.onboardingPrimaryNext.rawValue: "Continue",
            Key.onboardingPrimaryFinish.rawValue: "Start converting",
            Key.onboardingSkip.rawValue: "Skip tour",
            Key.currencyInvalidResponse.rawValue: "Failed to process server response.",
            Key.currencyDateRange.rawValue: "Unable to prepare date range.",
            Key.intentKeypadDescription.rawValue: "Updates the widget input field instantly.",
            Key.intentWidgetDescription.rawValue: "Widget FX configuration",
            Key.widgetAmountTitle.rawValue: "Amount",
            Key.widgetBaseSubtitle.rawValue: "Base currency",
            Key.widgetConversionTitle.rawValue: "Conversion",
            Key.widgetKeypadTitle.rawValue: "Keypad",
            Key.widgetTimestamp.rawValue: "Updated %@",
            Key.widgetDisplayName.rawValue: "Widget FX Converter",
            Key.widgetDescription.rawValue: "Type the amount and get instant multi-currency quotes.",
            Key.widgetUnsupported.rawValue: "Add a large widget to access the keypad."
        ],
        "ru": [
            Key.dashboardTitle.rawValue: "Widget FX",
            Key.heroStatusOnline.rawValue: "Виджет подключён",
            Key.heroStatusPro.rawValue: "Converter Pro активна",
            Key.heroChannelTag.rawValue: "Omnichannel",
            Key.heroCopyMany.rawValue: "Виджеты рассылают курсы для %d сценариев.",
            Key.heroCopyDefault.rawValue: "Показывай свежие курсы на панелях, сайтах и витринах.",
            Key.amountLabel.rawValue: "Сумма",
            Key.pickerFrom.rawValue: "Из",
            Key.pickerTo.rawValue: "В",
            Key.quickInputTitle.rawValue: "Быстрый ввод",
            Key.overlayDone.rawValue: "Готово",
            Key.overlayDismissAccessibility.rawValue: "Скрыть клавиатуру",
            Key.overlayBaseCurrency.rawValue: "Базовая валюта — %@",
            Key.overlayConversion.rawValue: "Конвертация",
            Key.rateUnavailable.rawValue: "Курс недоступен",
            Key.rateFormatted.rawValue: "1 %@ = %@ %@",
            Key.errorRatesUnavailable.rawValue: "Не удалось обновить курс: %@. Показаны данные из кэша.",
            Key.purchaseLoadError.rawValue: "Не удалось загрузить подписки: %@",
            Key.purchaseUnknownStatus.rawValue: "Неизвестный статус покупки",
            Key.purchaseUnverified.rawValue: "Покупка не верифицирована.",
            Key.onboardingSlide1Title.rawValue: "Виджет в одно касание",
            Key.onboardingSlide1Description.rawValue: "Вводи сумму и выбирай валюты прямо с экрана блокировки — приложение не нужно открывать.",
            Key.onboardingSlide1Footnote.rawValue: "Крупные цифры, высокий контраст и лёгкая вибро-обратная связь упрощают ввод.",
            Key.onboardingSlide2Title.rawValue: "Работает офлайн",
            Key.onboardingSlide2Description.rawValue: "Последние курсы кэшируются, поэтому конвертация доступна даже в самолёте или метро.",
            Key.onboardingSlide2Footnote.rawValue: "Как только сеть вернётся, данные обновятся в фоне без вашего участия.",
            Key.onboardingSlide3Title.rawValue: "Один сценарий везде",
            Key.onboardingSlide3Description.rawValue: "Телефон, планшет или инфопанель — виджет подстраивается под размер, сохраняя привычный флоу.",
            Key.onboardingSlide3Footnote.rawValue: "Портретные и альбомные состояния оптимизированы под работу одной рукой и на киосках.",
            Key.onboardingFeatureTag.rawValue: "Для операторов",
            Key.onboardingFeatureDescription.rawValue: "Все контролы в зоне большого пальца и откликаются тактильно.",
            Key.onboardingPrimaryNext.rawValue: "Дальше",
            Key.onboardingPrimaryFinish.rawValue: "Начать конвертировать",
            Key.onboardingSkip.rawValue: "Пропустить тур",
            Key.currencyInvalidResponse.rawValue: "Не удалось обработать ответ сервера.",
            Key.currencyDateRange.rawValue: "Не удалось подготовить диапазон дат.",
            Key.intentKeypadDescription.rawValue: "Обновляет поле ввода прямо в виджете.",
            Key.intentWidgetDescription.rawValue: "Конфигурация виджета Widget FX",
            Key.widgetAmountTitle.rawValue: "Сумма",
            Key.widgetBaseSubtitle.rawValue: "Базовая валюта",
            Key.widgetConversionTitle.rawValue: "Конвертация",
            Key.widgetKeypadTitle.rawValue: "Клавиатура",
            Key.widgetTimestamp.rawValue: "Обновлено %@",
            Key.widgetDisplayName.rawValue: "Конвертер Widget FX",
            Key.widgetDescription.rawValue: "Вводи сумму и смотри курсы сразу в нескольких валютах.",
            Key.widgetUnsupported.rawValue: "Добавь большой виджет, чтобы увидеть клавиатуру."
        ]
    ]
}
