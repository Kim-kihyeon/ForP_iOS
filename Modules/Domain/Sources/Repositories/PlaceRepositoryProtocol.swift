import Foundation

public protocol PlaceRepositoryProtocol: Sendable {
    func searchPlaces(keyword: String) async throws -> [CoursePlace]
}
