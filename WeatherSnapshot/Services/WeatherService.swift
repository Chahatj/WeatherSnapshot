//
//  WeatherService.swift
//  WeatherSnapshot
//

import Foundation

enum WeatherServiceError: LocalizedError {
    case cityNotFound
    case invalidResponse
    case networkError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .cityNotFound:
            "City not found. Try another name."
        case .invalidResponse:
            "Could not read weather data."
        case .networkError(let underlying):
            underlying.localizedDescription
        }
    }
}

final class WeatherService {
    static let shared = WeatherService()

    private let session: URLSession
    private let decoder = JSONDecoder()

    private init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchWeather(for city: String) async throws -> WeatherSnapshot {
        let location = try await geocode(city: city)
        let forecast = try await fetchForecast(
            latitude: location.latitude,
            longitude: location.longitude
        )

        return WeatherSnapshot(
            city: location.name,
            country: location.country,
            temperatureCelsius: forecast.current.temperature2m,
            humidity: forecast.current.relativeHumidity2m,
            windSpeedKmh: forecast.current.windSpeed10m,
            condition: WeatherCondition.description(for: forecast.current.weatherCode),
            fetchedAt: Date()
        )
    }

    private func geocode(city: String) async throws -> GeocodingResult {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "name", value: city),
            URLQueryItem(name: "count", value: "1"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components.url else { throw WeatherServiceError.invalidResponse }

        let data: Data
        do {
            (data, _) = try await session.data(from: url)
        } catch {
            throw WeatherServiceError.networkError(underlying: error)
        }

        let response = try decoder.decode(GeocodingResponse.self, from: data)
        guard let result = response.results?.first else {
            throw WeatherServiceError.cityNotFound
        }
        return result
    }

    private func fetchForecast(latitude: Double, longitude: Double) async throws -> ForecastResponse {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        guard let url = components.url else { throw WeatherServiceError.invalidResponse }

        let data: Data
        do {
            (data, _) = try await session.data(from: url)
        } catch {
            throw WeatherServiceError.networkError(underlying: error)
        }

        do {
            return try decoder.decode(ForecastResponse.self, from: data)
        } catch {
            throw WeatherServiceError.invalidResponse
        }
    }
}
