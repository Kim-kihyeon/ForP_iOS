import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain

public struct AnniversaryView: View {
    @Bindable var store: StoreOf<AnniversaryFeature>

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        return f
    }()

    public init(store: StoreOf<AnniversaryFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if store.anniversaries.isEmpty && !store.isLoading {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(store.anniversaries) { anniversary in
                            anniversaryCard(anniversary)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.md)
                }
            }

            if store.isLoading { LoadingView() }
        }
        .navigationTitle("기념일")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Brand.pink)
        .toolbarBackground(Brand.softPink, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    store.send(.addTapped)
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Brand.pink)
                }
            }
        }
        .sheet(isPresented: $store.isEditing) {
            editSheet
        }
        .onAppear { store.send(.onAppear) }
        .alert($store.scope(state: \.alert, action: \.alert))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Text("💑")
                .font(.system(size: 64))
            Text("아직 기념일이 없어요")
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(.primary)
            Text("우리 둘만의 소중한 날을\n기록해보세요")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Anniversary Card

    private func anniversaryCard(_ anniversary: Anniversary) -> some View {
        AnniversaryFormCard {
            HStack(spacing: Spacing.md) {
                dateBadge(anniversary.date)

                VStack(alignment: .leading, spacing: 3) {
                    Text(anniversary.name)
                        .font(Typography.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(Self.dateFormatter.string(from: anniversary.date))
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    let days = anniversary.daysUntilThisYear
                    Text(days == 0 ? "D-Day" : "D-\(days)")
                        .font(Typography.caption.weight(.bold))
                        .foregroundStyle(Brand.pink)
                    if anniversary.yearsElapsed > 0 {
                        Text("\(anniversary.yearsElapsed)주년")
                            .font(Typography.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 4) {
                    Button {
                        store.send(.editTapped(anniversary))
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        store.send(.deleteTapped(anniversary))
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.red)
                            .frame(width: 32, height: 32)
                            .background(Color.red.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func dateBadge(_ date: Date) -> some View {
        let month = Calendar.current.component(.month, from: date)
        let day = Calendar.current.component(.day, from: date)
        return ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Brand.softPink)
                .frame(width: 48, height: 48)
            VStack(spacing: 0) {
                Text("\(month)월")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Brand.pink)
                Text("\(day)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.pink)
            }
        }
    }

    // MARK: - Edit Sheet

    private var editSheet: some View {
        NavigationStack {
            Form {
                Section("이름") {
                    TextField("예: 사귄 날, 첫 만남", text: $store.editingName)
                }
                Section("날짜") {
                    DatePicker("", selection: $store.editingDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .environment(\.locale, Locale(identifier: "ko_KR"))
                        .labelsHidden()
                }
            }
            .navigationTitle(store.editingId == nil ? "기념일 추가" : "기념일 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { store.send(.cancelTapped) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { store.send(.saveTapped) }
                        .disabled(store.editingName.isEmpty)
                }
            }
        }
        .tint(Brand.pink)
    }
}

private struct AnniversaryFormCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            content
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
