//
//  ContentView.swift
//  WeatherSnapshot
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = WeatherViewModel()
    @AppStorage("temperatureUnit") private var unitRawValue = TemperatureUnit.celsius.rawValue

    private var unit: TemperatureUnit {
        TemperatureUnit(rawValue: unitRawValue) ?? .celsius
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                searchSection
                contentSection
            }
            .padding()
            .navigationTitle("Weather Snapshot")
            .onAppear {
                viewModel.loadCachedIfAvailable()
                if viewModel.weather == nil {
                    viewModel.fetchWeather()
                }
            }
        }
    }

    // MARK: - Search

    private var searchSection: some View {
        HStack(spacing: 12) {
            TextField("City", text: $viewModel.cityQuery)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)
                .submitLabel(.search)
                .onSubmit { viewModel.fetchWeather() }

            Button("Go") { viewModel.fetchWeather() }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentSection: some View {
        if viewModel.isLoading && viewModel.weather == nil {
            ProgressView("Fetching weather…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let weather = viewModel.weather {
            weatherCard(weather)
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        } else {
            ContentUnavailableView(
                "No Weather Data",
                systemImage: "cloud.slash",
                description: Text("Enter a city and tap Go.")
            )
        }
    }

    private func weatherCard(_ weather: WeatherSnapshot) -> some View {
        VStack(spacing: 20) {
            if viewModel.isStale {
                staleBanner(for: weather)
            }

            VStack(spacing: 4) {
                Text("\(weather.city), \(weather.country)")
                    .font(.title2.bold())
                Text(weather.condition)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(weather.formattedTemperature(in: unit))
                .font(.system(size: 64, weight: .thin, design: .rounded))

            unitPicker

            VStack(spacing: 12) {
                dataRow(icon: "humidity", label: "Humidity", value: "\(weather.humidity)%")
                dataRow(icon: "wind", label: "Wind", value: String(format: "%.0f km/h", weather.windSpeedKmh))
                dataRow(
                    icon: "clock",
                    label: "Cached at",
                    value: weather.fetchedAt.formatted(date: .abbreviated, time: .shortened)
                )
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

            if viewModel.isLoading {
                ProgressView()
            }

            Button("Refresh") { viewModel.fetchWeather() }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func staleBanner(for weather: WeatherSnapshot) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            VStack(alignment: .leading, spacing: 2) {
                Text("Offline — showing cached data")
                    .font(.subheadline.bold())
                Text("Last updated \(weather.fetchedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
        )
    }

    private var unitPicker: some View {
        Picker("Unit", selection: $unitRawValue) {
            ForEach(TemperatureUnit.allCases, id: \.rawValue) { unit in
                Text(unit.rawValue).tag(unit.rawValue)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 200)
    }

    private func dataRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text("Unable to Load Weather")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") { viewModel.retry() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
