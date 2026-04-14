import Foundation

@Observable
final class CourseResultViewModel {
    var isSaving: Bool = false

    func saveCourse(_ course: Course) async {
        // TODO: Supabase에 코스 저장
    }
}
