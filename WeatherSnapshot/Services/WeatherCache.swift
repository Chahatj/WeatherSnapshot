//
//  WeatherCache.swift
//  WeatherSnapshot
//

import Foundation

final class WeatherCache {
    static let shared = WeatherCache()

    private let fileManager = FileManager.default
    private let cacheFileName = "weather_snapshot.json"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var cacheURL: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(cacheFileName)
    }

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func save(_ snapshot: WeatherSnapshot) {
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }

    func load() -> WeatherSnapshot? {
        guard fileManager.fileExists(atPath: cacheURL.path),
              let data = try? Data(contentsOf: cacheURL),
              let snapshot = try? decoder.decode(WeatherSnapshot.self, from: data)
        else { return nil }
        return snapshot
    }

    func clear() {
        try? fileManager.removeItem(at: cacheURL)
    }
}
