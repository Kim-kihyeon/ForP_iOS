import SwiftUI
import CoreSharedUI
import Domain

struct BudgetCalculatorView: View {
    let places: [CoursePlace]
    @Environment(\.dismiss) private var dismiss
    @State private var budgets: [Int: String] = [:]

    private var sortedPlaces: [CoursePlace] { places.sorted { $0.order < $1.order } }
    private var total: Int { budgets.values.compactMap { Int($0.filter(\.isNumber)) }.reduce(0, +) }
    private var perPerson: Int { total / 2 }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(sortedPlaces, id: \.order) { place in
                        placeRow(place)
                    }
                    totalCard
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("예산 계산")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Brand.pink)
            .toolbarBackground(Brand.softPink, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(Brand.pink)
                }
                ToolbarItem(placement: .keyboard) {
                    Button("완료") { hideKeyboard() }
                        .foregroundStyle(Brand.pink)
                }
            }
        }
        .onAppear {
            for place in sortedPlaces {
                budgets[place.order] = formatWon(defaultBudget(for: place.category))
            }
        }
    }

    // MARK: - Place Row

    private func placeRow(_ place: CoursePlace) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Brand.softPink)
                        .frame(width: 28, height: 28)
                    Text("\(place.order)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Brand.pink)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.placeName ?? place.keyword)
                        .font(Typography.caption.weight(.semibold))
                        .lineLimit(1)
                    Text(place.category)
                        .font(Typography.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 4) {
                Spacer()
                TextField("0", text: Binding(
                    get: { budgets[place.order] ?? "0" },
                    set: { budgets[place.order] = $0 }
                ))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Brand.pink)
                .onChange(of: budgets[place.order] ?? "") { _, new in
                    let digits = new.filter(\.isNumber)
                    let clamped = min(Int(digits) ?? 0, 99_999_999)
                    budgets[place.order] = formatWon(clamped)
                }
                Text("원")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Total Card

    private var totalCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("총 예상 금액")
                    .font(Typography.body.weight(.semibold))
                Spacer()
                Text("\(formatWon(total))원")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.pink)
            }

            Divider()

            HStack {
                Text("1인당")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(formatWon(perPerson))원")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func defaultBudget(for category: String) -> Int {
        if category.contains("카페") || category.contains("커피") || category.contains("디저트") || category.contains("베이커리") { return 15000 }
        if category.contains("레스토랑") || category.contains("식당") || category.contains("맛집") || category.contains("한식") || category.contains("일식") || category.contains("중식") || category.contains("양식") || category.contains("이탈리안") || category.contains("브런치") { return 50000 }
        if category.contains("바") || category.contains("펍") || category.contains("와인") || category.contains("칵테일") { return 40000 }
        if category.contains("영화") { return 25000 }
        if category.contains("쇼핑") { return 50000 }
        if category.contains("공원") || category.contains("자연") || category.contains("산책") { return 0 }
        if category.contains("문화") || category.contains("박물관") || category.contains("미술관") || category.contains("전시") { return 15000 }
        return 20000
    }

    private func formatWon(_ amount: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_US")
        return f.string(from: NSNumber(value: amount)) ?? "0"
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
