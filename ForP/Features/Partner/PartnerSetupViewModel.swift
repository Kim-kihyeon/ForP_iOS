import Foundation

@Observable
final class PartnerSetupViewModel {
    var nickname: String = ""
    var preferredCategories: [String] = []
    var dislikedCategories: [String] = []
    var preferredThemes: [String] = []
    var notes: String = ""

    func save() async {
        // TODO: Supabase에 파트너 정보 저장
    }

    func reset() async {
        // TODO: 파트너 정보 초기화
    }
}
