import Foundation

public struct Anniversary: Identifiable, Codable, Equatable {
    public var id: UUID
    public var userId: UUID
    public var name: String
    public var date: Date

    public init(id: UUID = UUID(), userId: UUID, name: String, date: Date) {
        self.id = id
        self.userId = userId
        self.name = name
        self.date = date
    }

    // 올해 기준 D-day (양수: 남은 날, 0: 오늘, 음수: 지남)
    public var daysUntilThisYear: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var components = calendar.dateComponents([.month, .day], from: date)
        components.year = calendar.component(.year, from: today)
        guard let thisYear = calendar.date(from: components) else { return 0 }
        let target = thisYear < today
            ? calendar.date(byAdding: .year, value: 1, to: thisYear)! // 이미 지났으면 내년
            : thisYear
        return calendar.dateComponents([.day], from: today, to: target).day ?? 0
    }

    public var yearsElapsed: Int {
        Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
    }
}
