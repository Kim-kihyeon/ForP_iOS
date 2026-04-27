import Foundation
import SwiftData
import Supabase
import Domain

public final class CourseRepository: CourseRepositoryProtocol, @unchecked Sendable {
    private let supabase: SupabaseClient
    private let modelContext: ModelContext

    public init(supabase: SupabaseClient, modelContext: ModelContext) {
        self.supabase = supabase
        self.modelContext = modelContext
    }

    public func fetchRecentCourses(userId: UUID, limit: Int) async throws -> [Course] {
        do {
            let rows: [CourseFetchRow] = try await supabase
                .from("courses")
                .select()
                .or("user_id.eq.\(userId),partner_id.eq.\(userId)")
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            return rows.map { $0.toDomain() }
        } catch {
            let descriptor = FetchDescriptor<CourseCache>(
                predicate: #Predicate { $0.userId == userId },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let cached = try modelContext.fetch(descriptor)
            return try cached.prefix(limit).map { try $0.toDomain() }
        }
    }

    public func fetchCoursesByMonth(userId: UUID, year: Int, month: Int) async throws -> [Course] {
        let startDate = String(format: "%04d-%02d-01", year, month)
        let endMonth = month == 12 ? 1 : month + 1
        let endYear = month == 12 ? year + 1 : year
        let endDate = String(format: "%04d-%02d-01", endYear, endMonth)
        do {
            let rows: [CourseFetchRow] = try await supabase
                .from("courses")
                .select()
                .eq("user_id", value: userId)
                .gte("date", value: startDate)
                .lt("date", value: endDate)
                .order("date", ascending: false)
                .execute()
                .value
            return rows.map { $0.toDomain() }
        } catch {
            let descriptor = FetchDescriptor<CourseCache>(
                predicate: #Predicate { $0.userId == userId },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let cached = try modelContext.fetch(descriptor)
            let cal = Calendar.current
            return try cached.compactMap { cache -> Course? in
                let course = try cache.toDomain()
                let comps = cal.dateComponents([.year, .month], from: course.date)
                guard comps.year == year, comps.month == month else { return nil }
                return course
            }
        }
    }

    public func saveCourse(_ course: Course) async throws {
        let row = CourseInsertRow(from: course)
        try await supabase
            .from("courses")
            .upsert(row)
            .execute()

        let cache = try CourseCache(from: course)
        modelContext.insert(cache)
        try modelContext.save()
    }

    public func toggleLike(id: UUID, isLiked: Bool) async throws {
        try await supabase
            .from("courses")
            .update(["is_liked": isLiked])
            .eq("id", value: id)
            .execute()

        let descriptor = FetchDescriptor<CourseCache>(predicate: #Predicate { $0.id == id })
        if let cache = try modelContext.fetch(descriptor).first {
            cache.isLiked = isLiked
            try modelContext.save()
        }
    }

    public func updateTitle(id: UUID, title: String) async throws {
        try await supabase
            .from("courses")
            .update(["title": title])
            .eq("id", value: id)
            .execute()

        let descriptor = FetchDescriptor<CourseCache>(predicate: #Predicate { $0.id == id })
        if let cache = try modelContext.fetch(descriptor).first {
            cache.title = title
            try modelContext.save()
        }
    }

    public func updateRating(id: UUID, rating: Int, review: String) async throws {
        struct RatingUpdate: Encodable {
            let rating: Int
            let review: String
        }
        try await supabase
            .from("courses")
            .update(RatingUpdate(rating: rating, review: review))
            .eq("id", value: id)
            .execute()

        let descriptor = FetchDescriptor<CourseCache>(predicate: #Predicate { $0.id == id })
        if let cache = try modelContext.fetch(descriptor).first {
            cache.rating = rating
            cache.review = review.isEmpty ? nil : review
            try modelContext.save()
        }
    }

    public func updatePartnerRating(id: UUID, rating: Int, review: String) async throws {
        struct Params: Encodable {
            let courseId: UUID
            let pRating: Int
            let pReview: String
            enum CodingKeys: String, CodingKey {
                case courseId = "course_id"
                case pRating = "p_rating"
                case pReview = "p_review"
            }
        }
        try await supabase
            .rpc("update_partner_rating", params: Params(courseId: id, pRating: rating, pReview: review))
            .execute()
    }

    public func endCourse(id: UUID) async throws {
        try await supabase
            .rpc("end_course", params: ["course_id": id])
            .execute()

        let descriptor = FetchDescriptor<CourseCache>(predicate: #Predicate { $0.id == id })
        if let cache = try modelContext.fetch(descriptor).first {
            cache.isEnded = true
            try modelContext.save()
        }
    }

    public func observeIsEnded(courseId: UUID) -> AsyncStream<Void> {
        AsyncStream { continuation in
            let channel = supabase.channel("course-ended-\(courseId.uuidString)")
            let task = Task {
                let updates = channel.postgresChange(
                    UpdateAction.self,
                    schema: "public",
                    table: "courses",
                    filter: "id=eq.\(courseId.uuidString)"
                )
                await channel.subscribe()
                for await change in updates {
                    if case .bool(true) = change.record["is_ended"] {
                        continuation.yield(())
                    }
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
                Task { await channel.unsubscribe() }
            }
        }
    }

    public func notifyPartner(courseId: UUID) async {
        do {
            try await supabase.functions
                .invoke("notify-partner", options: .init(body: ["course_id": courseId.uuidString]))
        } catch {
            print("[notifyPartner] error: \(error)")
        }
    }

    public func deleteCourse(id: UUID) async throws {
        try await supabase
            .from("courses")
            .delete()
            .eq("id", value: id)
            .execute()

        let descriptor = FetchDescriptor<CourseCache>(
            predicate: #Predicate { $0.id == id }
        )
        if let cache = try modelContext.fetch(descriptor).first {
            modelContext.delete(cache)
            try modelContext.save()
        }
    }
}

private struct CourseInsertRow: Encodable {
    let id: UUID
    let userId: UUID
    let partnerId: UUID?
    let title: String
    let mode: String
    let date: String
    let places: [CoursePlace]
    let candidates: [CoursePlace]
    let outfitSuggestion: String?
    let courseReason: String
    let isLiked: Bool
    let isEnded: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, mode, date, places, candidates
        case userId = "user_id"
        case partnerId = "partner_id"
        case outfitSuggestion = "outfit_suggestion"
        case courseReason = "course_reason"
        case isLiked = "is_liked"
        case isEnded = "is_ended"
    }

    init(from course: Course) {
        id = course.id
        userId = course.userId
        partnerId = course.partnerId
        title = course.title
        mode = course.mode.rawValue
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        date = f.string(from: course.date)
        places = course.places
        candidates = course.candidates
        outfitSuggestion = course.outfitSuggestion
        courseReason = course.courseReason
        isLiked = course.isLiked
        isEnded = course.isEnded
    }
}

private struct CourseFetchRow: Decodable {
    let id: UUID
    let userId: UUID
    let partnerId: UUID?
    let title: String
    let mode: String
    let date: String?
    let places: [CoursePlace]
    let candidates: [CoursePlace]?
    let createdAt: String
    let outfitSuggestion: String?
    let courseReason: String?
    let isLiked: Bool?
    let rating: Int?
    let review: String?
    let partnerRating: Int?
    let partnerReview: String?
    let isEnded: Bool?

    enum CodingKeys: String, CodingKey {
        case id, title, mode, date, places, candidates, rating, review
        case userId = "user_id"
        case partnerId = "partner_id"
        case createdAt = "created_at"
        case outfitSuggestion = "outfit_suggestion"
        case courseReason = "course_reason"
        case isLiked = "is_liked"
        case partnerRating = "partner_rating"
        case partnerReview = "partner_review"
        case isEnded = "is_ended"
    }

    func toDomain() -> Course {
        let parsedDate: Date = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            if let d = date, let parsed = f.date(from: d) { return parsed }
            return ISO8601DateFormatter().date(from: createdAt) ?? Date()
        }()
        return Course(
            id: id,
            userId: userId,
            partnerId: partnerId,
            title: title,
            date: parsedDate,
            mode: CourseMode(rawValue: mode) ?? .ordered,
            places: places,
            candidates: candidates ?? [],
            outfitSuggestion: outfitSuggestion,
            courseReason: courseReason ?? "",
            isLiked: isLiked ?? false,
            rating: rating,
            review: review,
            partnerRating: partnerRating,
            partnerReview: partnerReview,
            isEnded: isEnded ?? false
        )
    }
}
