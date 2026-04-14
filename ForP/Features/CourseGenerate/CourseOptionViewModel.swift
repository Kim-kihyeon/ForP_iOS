import Foundation

@Observable
final class CourseOptionViewModel {
    var location: String = ""
    var selectedThemes: [String] = []
    var placeCount: Int = 3
    var mode: CourseMode = .ordered
    var isGenerating: Bool = false

    func generateCourse(user: User, partner: Partner?) async {
        // TODO: GenerateCourseUseCase + FetchPlacesUseCase 호출
    }
}
