import Foundation

public struct WeatherInfo: Equatable {
    public var condition: String   // 맑음, 흐림, 비, 눈 등
    public var temperature: Int    // 섭씨
    public var description: String // GPT에 전달할 요약 문장

    public init(condition: String, temperature: Int, description: String) {
        self.condition = condition
        self.temperature = temperature
        self.description = description
    }
}

public protocol WeatherServiceProtocol: Sendable {
    func fetchWeather(latitude: Double, longitude: Double, date: Date) async throws -> WeatherInfo
}
