import Foundation
import SwiftData
import Supabase
import Domain

public final class CourseRepository: CourseRepositoryProtocol {
    private let supabase: SupabaseClient
    private let modelContext: ModelContext

    public init(supabase: SupabaseClient, modelContext: ModelContext) {
        self.supabase = supabase
        self.modelContext = modelContext
    }

    public func fetchRecentCourses(userId: UUID, limit: Int) async throws -> [Course] {
        do {
            // TODO: Supabase에서 코스 목록 조회
            return []
        } catch {
            // 실패 시 로컬 캐시 반환
            let descriptor = FetchDescriptor<CourseCache>(
                predicate: #Predicate { $0.userId == userId },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let cached = try modelContext.fetch(descriptor)
            return try cached.prefix(limit).map { try $0.toDomain() }
        }
    }

    public func saveCourse(_ course: Course) async throws {
        // TODO: Supabase에 저장
        let cache = try CourseCache(from: course)
        modelContext.insert(cache)
        try modelContext.save()
    }

    public func deleteCourse(id: UUID) async throws {
        // TODO: Supabase에서 삭제
        let descriptor = FetchDescriptor<CourseCache>(
            predicate: #Predicate { $0.id == id }
        )
        if let cache = try modelContext.fetch(descriptor).first {
            modelContext.delete(cache)
            try modelContext.save()
        }
    }
}
