import SwiftUI
import ComposableArchitecture
import CoreSharedUI
import Domain

public struct AnniversaryView: View {
    @Bindable var store: StoreOf<AnniversaryFeature>

    public init(store: StoreOf<AnniversaryFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if store.anniversaries.isEmpty && !store.isLoading {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "heart.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(Brand.softPink)
                    Text("기념일을 등록해보세요")
                        .font(Typography.body)
                        .foregroundStyle(.secondary)
                }
            } else {
                List {
                    ForEach(store.anniversaries) { anniversary in
                        anniversaryRow(anniversary)
                            .listRowBackground(Color(.systemBackground))
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.send(.deleteTapped(anniversary))
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                                Button {
                                    store.send(.editTapped(anniversary))
                                } label: {
                                    Label("수정", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                    }
                }
                .listStyle(.insetGrouped)
            }

            if store.isLoading { LoadingView() }
        }
        .navigationTitle("기념일")
        .navigationBarTitleDisplayMode(.inline)
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

    private func anniversaryRow(_ anniversary: Anniversary) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(anniversary.name)
                    .font(Typography.body.weight(.medium))

                let formatter: DateFormatter = {
                    let f = DateFormatter()
                    f.locale = Locale(identifier: "ko_KR")
                    f.dateFormat = "M월 d일"
                    return f
                }()
                Text(formatter.string(from: anniversary.date))
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            let days = anniversary.daysUntilThisYear
            VStack(alignment: .trailing, spacing: 2) {
                if days == 0 {
                    Text("D-Day")
                        .font(Typography.caption.weight(.bold))
                        .foregroundStyle(Brand.pink)
                } else {
                    Text("D-\(days)")
                        .font(Typography.caption.weight(.bold))
                        .foregroundStyle(Brand.pink)
                }
                if anniversary.yearsElapsed > 0 {
                    Text("\(anniversary.yearsElapsed)주년")
                        .font(Typography.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

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
    }
}
