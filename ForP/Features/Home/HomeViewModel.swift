import Foundation

@Observable
final class HomeViewModel {
    var recentCourses: [Course] = []

    func loadRecentCourses() async {
        // TODO: Supabase에서 최근 코스 불러오기
    }
}
