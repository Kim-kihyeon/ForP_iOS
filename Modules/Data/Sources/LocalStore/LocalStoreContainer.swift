import Foundation
import SwiftData

public struct LocalStoreContainer {
    public static func make() throws -> ModelContainer {
        try ModelContainer(for: CourseCache.self)
    }

    public static func makeInMemory() -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: CourseCache.self, configurations: configuration)
    }
}
