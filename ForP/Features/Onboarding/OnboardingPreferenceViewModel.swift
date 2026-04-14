import Foundation

@Observable
final class OnboardingPreferenceViewModel {
    var preferredCategories: [String] = []
    var dislikedCategories: [String] = []
    var preferredThemes: [String] = []
    var location: String = ""

    func save() async {
        // TODO: Supabase에 유저 취향 저장
    }
}
