import Foundation

public protocol PlaceRepositoryProtocol: Sendable {
    func searchPlaces(keyword: String) async throws -> [CoursePlace]
    func searchPlaces(keyword: String, latitude: Double, longitude: Double, radius: Int) async throws -> [CoursePlace]
    func isValidKoreanRegion(keyword: String) async throws -> Bool
}
