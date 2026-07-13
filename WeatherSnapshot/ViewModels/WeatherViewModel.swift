//
//  WeatherViewModel.swift
//  WeatherSnapshot
//

import Foundation
import Observation

@Observable
final class WeatherViewModel {
    var weather: WeatherSnapshot?
    var isLoading = false
    var isStale = false
    var errorMessage: String?
    var cityQuery = "London"

    private let service: WeatherService
    private let cache: WeatherCache

    init(service: WeatherService = .shared, cache: WeatherCache = .shared) {
        self.service = service
        self.cache = cache
    }

    func loadCachedIfAvailable() {
        if let cached = cache.load() {
            DispatchQueue.main.async { [weak self] in
                self?.weather = cached
                self?.isStale = true
                self?.cityQuery = cached.city
            }
        }
    }

    func fetchWeather() {
        let city = cityQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !city.isEmpty else { return }

        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
            self?.errorMessage = nil
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            Task {
                do {
                    let snapshot = try await self.service.fetchWeather(for: city)
                    self.cache.save(snapshot)

                    DispatchQueue.main.async { [weak self] in
                        self?.weather = snapshot
                        self?.isStale = false
                        self?.isLoading = false
                        self?.errorMessage = nil
                    }
                } catch {
                    let cached = self.cache.load()

                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        self.isLoading = false

                        if let cached {
                            self.weather = cached
                            self.isStale = true
                            self.errorMessage = nil
                        } else {
                            self.weather = nil
                            self.isStale = false
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
    }

    func retry() {
        fetchWeather()
    }
}
