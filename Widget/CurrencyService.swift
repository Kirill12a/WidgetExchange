//
//  CurrencyService.swift
//  Widget
//
//  Created by Kirill Drozdov on 09.11.2025.
//

import Foundation

enum CurrencyServiceError: Error, LocalizedError {
    case invalidResponse
    case message(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return AppLocale.text(.currencyInvalidResponse)
        case .message(let text):
            return text
        }
    }
}

final class CurrencyService {
    static let shared = CurrencyService()

    private let session: URLSession
    private let calendar = Calendar.current

    private lazy var hostDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchRates(base: String, symbols: [String]) async throws -> CurrencyRates {
        if let hostRates = try? await fetchFromExchangeRateHost(base: base, symbols: symbols) {
            return hostRates
        }
        return try await fetchFromOpenER(base: base, symbols: symbols)
    }

    func fetchTrend(base: String, target: String, days: Int) async throws -> [RatePoint] {
        guard let endDate = calendar.date(byAdding: .day, value: -1, to: Date()),
              let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            throw CurrencyServiceError.message(AppLocale.text(.currencyDateRange))
        }

        if let series = try? await fetchHostTimeseries(base: base, target: target, start: startDate, end: endDate) {
            return series
        }

        return RatePoint.placeholderSeries(seed: 1.0, days: days)
    }

    private func fetchFromExchangeRateHost(base: String, symbols: [String]) async throws -> CurrencyRates {
        var components = URLComponents(string: "https://api.exchangerate.host/latest")
        components?.queryItems = [
            URLQueryItem(name: "base", value: base),
            URLQueryItem(name: "symbols", value: symbols.joined(separator: ","))
        ]

        guard let url = components?.url else {
            throw CurrencyServiceError.invalidResponse
        }

        let (data, response) = try await session.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw CurrencyServiceError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(HostLatestResponse.self, from: data)
        guard let date = hostDateFormatter.date(from: decoded.date) else {
            throw CurrencyServiceError.invalidResponse
        }

        return CurrencyRates(base: decoded.base, date: date, rates: decoded.rates)
    }

    private func fetchFromOpenER(base: String, symbols: [String]) async throws -> CurrencyRates {
        guard let url = URL(string: "https://open.er-api.com/v6/latest/\(base)") else {
            throw CurrencyServiceError.invalidResponse
        }

        let (data, response) = try await session.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw CurrencyServiceError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(OpenERResponse.self, from: data)
        let filtered = decoded.rates.filter { symbols.contains($0.key) }
        let date = Date(timeIntervalSince1970: decoded.time_last_update_unix)

        return CurrencyRates(base: decoded.base_code, date: date, rates: filtered)
    }

    private func fetchHostTimeseries(base: String, target: String, start: Date, end: Date) async throws -> [RatePoint] {
        var components = URLComponents(string: "https://api.exchangerate.host/timeseries")
        components?.queryItems = [
            URLQueryItem(name: "base", value: base),
            URLQueryItem(name: "symbols", value: target),
            URLQueryItem(name: "start_date", value: hostDateFormatter.string(from: start)),
            URLQueryItem(name: "end_date", value: hostDateFormatter.string(from: end))
        ]

        guard let url = components?.url else {
            throw CurrencyServiceError.invalidResponse
        }

        let (data, response) = try await session.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw CurrencyServiceError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(HostTimeseriesResponse.self, from: data)
        guard decoded.success else {
            throw CurrencyServiceError.invalidResponse
        }

        let points = decoded.rates.compactMap { entry -> RatePoint? in
            guard let date = hostDateFormatter.date(from: entry.key),
                  let value = entry.value[target] else { return nil }
            return RatePoint(date: date, value: value)
        }
        .sorted { $0.date < $1.date }

        return points
    }
}

private struct HostLatestResponse: Decodable {
    let success: Bool?
    let base: String
    let date: String
    let rates: [String: Double]
}

private struct OpenERResponse: Decodable {
    let result: String
    let base_code: String
    let time_last_update_unix: Double
    let rates: [String: Double]
}

private struct HostTimeseriesResponse: Decodable {
    let success: Bool
    let rates: [String: [String: Double]]
}
