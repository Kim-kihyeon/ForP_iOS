import Foundation
import SwiftData

public struct LocalStoreContainer {
    public static func make() throws -> ModelContainer {
        try ModelContainer(for: CourseCache.self)
    }
}
