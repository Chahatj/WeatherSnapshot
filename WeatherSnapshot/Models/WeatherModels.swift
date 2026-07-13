//
//  WeatherModels.swift
//  WeatherSnapshot
//

import Foundation

enum TemperatureUnit: String, Codable, CaseIterable {
    case celsius = "°C"
    case fahrenheit = "°F"

    func convert(celsius: Double) -> Double {
        switch self {
        case .celsius: celsius
        case .fahrenheit: (celsius * 9 / 5) + 32
        }
    }
}

struct WeatherSnapshot: Codable, Equatable {
    let city: String
    let country: String
    let temperatureCelsius: Double
    let humidity: Int
    let windSpeedKmh: Double
    let condition: String
    let fetchedAt: Date

    func temperature(in unit: TemperatureUnit) -> Double {
        unit.convert(celsius: temperatureCelsius)
    }

    func formattedTemperature(in unit: TemperatureUnit) -> String {
        String(format: "%.1f%@", temperature(in: unit), unit.rawValue)
    }
}

// MARK: - Open-Meteo API responses

struct GeocodingResponse: Decodable {
    let results: [GeocodingResult]?
}

struct GeocodingResult: Decodable {
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String
}

struct ForecastResponse: Decodable {
    let current: CurrentWeather
}

struct CurrentWeather: Decodable {
    let temperature2m: Double
    let relativeHumidity2m: Int
    let windSpeed10m: Double
    let weatherCode: Int

    enum CodingKeys: String, CodingKey {
        case temperature2m = "temperature_2m"
        case relativeHumidity2m = "relative_humidity_2m"
        case windSpeed10m = "wind_speed_10m"
        case weatherCode = "weather_code"
    }
}

enum WeatherCondition {
    static func description(for code: Int) -> String {
        switch code {
        case 0: "Clear sky"
        case 1, 2, 3: "Partly cloudy"
        case 45, 48: "Foggy"
        case 51, 53, 55: "Drizzle"
        case 56, 57: "Freezing drizzle"
        case 61, 63, 65: "Rain"
        case 66, 67: "Freezing rain"
        case 71, 73, 75: "Snow"
        case 77: "Snow grains"
        case 80, 81, 82: "Rain showers"
        case 85, 86: "Snow showers"
        case 95: "Thunderstorm"
        case 96, 99: "Thunderstorm with hail"
        default: "Unknown"
        }
    }
}
