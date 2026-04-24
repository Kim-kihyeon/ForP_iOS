import SwiftUI
import Domain
import CoreSharedUI

struct CourseCalendarView: View {
    let courses: [Course]
    let anniversaries: [Anniversary]
    let onSelectCourse: (Course) -> Void
    let onDismiss: () -> Void

    @State private var displayedMonth: Date = {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
    }()
    @State private var selectedDate: Date? = nil

    private let cal = Calendar.current
    private let weekdayLabels = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                monthHeader
                weekdayHeader
                calendarGrid
                    .padding(.bottom, Spacing.sm)
                Divider()
                detailPanel
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("데이트 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { onDismiss() }
                        .tint(Brand.pink)
                }
            }
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
            }
            Spacer()
            Text(monthTitle)
                .font(.system(size: 17, weight: .bold))
            Spacer()
            Button { shiftMonth(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
            }
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color(.systemBackground))
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdayLabels, id: \.self) { label in
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(label == "일" ? Color(.systemRed).opacity(0.7) : .secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color(.systemBackground))
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(days.indices, id: \.self) { i in
                if let date = days[i] {
                    dayCell(date)
                } else {
                    Color.clear.frame(height: 56)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
        .background(Color(.systemBackground))
    }

    private func dayCell(_ date: Date) -> some View {
        let isToday = cal.isDateInToday(date)
        let isSelected = selectedDate.map { cal.isDate($0, inSameDayAs: date) } ?? false
        let dayCourses = coursesOn(date)
        let dayAnns = anniversariesOn(date)
        let isSunday = cal.component(.weekday, from: date) == 1

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDate = isSelected ? nil : date
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(cal.component(.day, from: date))")
                    .font(.system(size: 15, weight: (isToday || isSelected) ? .bold : .regular))
                    .foregroundStyle(
                        isSelected ? .white :
                        isToday ? Brand.pink :
                        isSunday ? Color(.systemRed).opacity(0.8) : .primary
                    )
                    .frame(width: 34, height: 34)
                    .background(
                        isSelected ? Brand.pink :
                        isToday ? Brand.softPink : Color.clear
                    )
                    .clipShape(Circle())

                HStack(spacing: 3) {
                    if !dayCourses.isEmpty {
                        Circle()
                            .fill(isSelected ? .white : Brand.pink)
                            .frame(width: 5, height: 5)
                    }
                    if !dayAnns.isEmpty {
                        Circle()
                            .fill(isSelected ? .white : Color(.systemYellow))
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            }
            .frame(height: 56)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Detail Panel

    @ViewBuilder
    private var detailPanel: some View {
        if let selected = selectedDate {
            let dayCourses = coursesOn(selected)
            let dayAnns = anniversariesOn(selected)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(dayAnns) { ann in
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemYellow).opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Text("💛").font(.system(size: 16))
                            }
                            Text(ann.name)
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, 12)
                        Divider().padding(.leading, 64)
                    }

                    ForEach(Array(dayCourses.enumerated()), id: \.element.id) { idx, course in
                        Button { onSelectCourse(course) } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Brand.softPink)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "map.fill")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Brand.pink)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 4) {
                                        Text(course.title)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.primary)
                                        if course.isLiked {
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 10))
                                                .foregroundStyle(Brand.pink)
                                        }
                                    }
                                    Text(course.places.compactMap { $0.placeName ?? $0.keyword }.prefix(3).joined(separator: " · "))
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color(.tertiaryLabel))
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        if idx < dayCourses.count - 1 {
                            Divider().padding(.leading, 64)
                        }
                    }

                    if dayCourses.isEmpty && dayAnns.isEmpty {
                        Text("이 날엔 기록이 없어요")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(Spacing.md)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            VStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Color(.tertiaryLabel))
                Text("날짜를 탭하면 코스가 표시돼요")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }

    // MARK: - Helpers

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월"
        return f.string(from: displayedMonth)
    }

    private func shiftMonth(_ delta: Int) {
        displayedMonth = cal.date(byAdding: .month, value: delta, to: displayedMonth) ?? displayedMonth
        selectedDate = nil
    }

    private func daysInMonth() -> [Date?] {
        var result: [Date?] = []
        let comps = cal.dateComponents([.year, .month], from: displayedMonth)
        guard let firstDay = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: firstDay) else { return result }

        let weekdayOffset = (cal.component(.weekday, from: firstDay) - 1 + 7) % 7
        result.append(contentsOf: Array(repeating: nil, count: weekdayOffset))
        for day in range {
            result.append(cal.date(byAdding: .day, value: day - 1, to: firstDay))
        }
        while result.count < 42 {
            result.append(nil)
        }
        return result
    }

    private func coursesOn(_ date: Date) -> [Course] {
        courses.filter { cal.isDate($0.date, inSameDayAs: date) }
    }

    private func anniversariesOn(_ date: Date) -> [Anniversary] {
        let month = cal.component(.month, from: date)
        let day = cal.component(.day, from: date)
        return anniversaries.filter {
            cal.component(.month, from: $0.date) == month &&
            cal.component(.day, from: $0.date) == day
        }
    }
}
