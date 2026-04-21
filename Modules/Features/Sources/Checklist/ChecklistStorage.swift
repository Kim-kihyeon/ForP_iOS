import Foundation

public enum ChecklistStorage {
    static let key = "defaultChecklistItems"

    public static let defaults: [String] = [
        "예약 시간/장소 재확인",
        "날씨 확인 및 우산 챙기기",
        "코디 미리 준비",
        "향수/그루밍",
        "보조배터리 충전",
        "현금 & 카드 확인",
        "사진 저장공간 확인",
        "주차/교통편 확인",
    ]

    public static func load() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? defaults
    }

    public static func save(_ items: [String]) {
        UserDefaults.standard.set(items, forKey: key)
    }
}
