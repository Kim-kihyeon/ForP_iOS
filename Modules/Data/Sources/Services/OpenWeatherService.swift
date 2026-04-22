import Foundation
import Domain

public struct OpenWeatherService: WeatherServiceProtocol {
    private let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func fetchWeather(latitude: Double, longitude: Double, date: Date) async throws -> WeatherInfo {
        let daysFromNow = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0

        if daysFromNow == 0 {
            return try await fetchCurrentWeather(latitude: latitude, longitude: longitude)
        } else if daysFromNow <= 4 {
            return try await fetchForecast(latitude: latitude, longitude: longitude, date: date)
        } else {
            return seasonalEstimate(for: date)
        }
    }

    private func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> WeatherInfo {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric&lang=kr"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OWCurrentResponse.self, from: data)

        let condition = response.weather.first?.description ?? "맑음"
        let temp = Int(response.main.temp.rounded())
        return WeatherInfo(
            condition: condition,
            temperature: temp,
            description: "\(temp)°C, \(condition)"
        )
    }

    private func fetchForecast(latitude: Double, longitude: Double, date: Date) async throws -> WeatherInfo {
        let urlString = "https://api.openweathermap.org/data/2.5/forecast?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric&lang=kr"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OWForecastResponse.self, from: data)

        let target = date.timeIntervalSince1970
        let best = response.list.min { abs($0.dt - target) < abs($1.dt - target) }

        guard let forecast = best else { return seasonalEstimate(for: date) }

        let condition = forecast.weather.first?.description ?? "맑음"
        let temp = Int(forecast.main.temp.rounded())
        return WeatherInfo(
            condition: condition,
            temperature: temp,
            description: "\(temp)°C, \(condition)"
        )
    }

    private func seasonalEstimate(for date: Date) -> WeatherInfo {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 12, 1, 2:
            return WeatherInfo(condition: "맑음", temperature: 2, description: "2°C 내외, 쌀쌀한 겨울 날씨")
        case 3, 4, 5:
            return WeatherInfo(condition: "맑음", temperature: 15, description: "15°C 내외, 따뜻한 봄 날씨")
        case 6:
            return WeatherInfo(condition: "흐림", temperature: 24, description: "24°C 내외, 장마 전 흐린 날씨")
        case 7, 8:
            return WeatherInfo(condition: "흐림", temperature: 30, description: "30°C 내외, 덥고 습한 여름 날씨")
        case 9, 10, 11:
            return WeatherInfo(condition: "맑음", temperature: 16, description: "16°C 내외, 선선한 가을 날씨")
        default:
            return WeatherInfo(condition: "맑음", temperature: 15, description: "15°C 내외")
        }
    }
}

// MARK: - Response Models

private struct OWCurrentResponse: Decodable {
    let main: OWMain
    let weather: [OWWeather]
}

private struct OWForecastResponse: Decodable {
    let list: [OWForecastItem]
}

private struct OWForecastItem: Decodable {
    let dt: TimeInterval
    let main: OWMain
    let weather: [OWWeather]
}

private struct OWMain: Decodable {
    let temp: Double
}

private struct OWWeather: Decodable {
    let description: String
}
