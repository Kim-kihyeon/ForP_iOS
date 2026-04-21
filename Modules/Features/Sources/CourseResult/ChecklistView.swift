import SwiftUI
import CoreSharedUI

struct ChecklistView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var checked: Set<String> = []
    @State private var customItems: [String] = []
    @State private var newItem = ""
    @FocusState private var isInputFocused: Bool

    private var defaultItems: [String] { ChecklistStorage.load() }

    private var totalCount: Int { defaultItems.count + customItems.count }
    private var checkedCount: Int { checked.count }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    progressCard
                    defaultSection
                    customSection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("준비물 체크리스트")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Brand.pink)
            .toolbarBackground(Brand.softPink, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(Brand.pink)
                }
            }
        }
    }

    // MARK: - Progress

    private var progressCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Brand.softPink, lineWidth: 4)
                    .frame(width: 44, height: 44)
                Circle()
                    .trim(from: 0, to: totalCount > 0 ? CGFloat(checkedCount) / CGFloat(totalCount) : 0)
                    .stroke(Brand.pink, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.4), value: checkedCount)
                Text("\(checkedCount)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.pink)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(checkedCount == totalCount && totalCount > 0 ? "준비 완료!" : "준비 중")
                    .font(Typography.body.weight(.bold))
                Text("\(totalCount)개 중 \(checkedCount)개 완료")
                    .font(Typography.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Default Section

    private var defaultSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("기본 준비물")
                .font(Typography.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(defaultItems, id: \.self) { item in
                    checkRow(item, isLast: item == defaultItems.last)
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Custom Section

    private var customSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("추가 준비물")
                .font(Typography.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(customItems, id: \.self) { item in
                    checkRow(item, isLast: item == customItems.last && true, isDeletable: true)
                }

                HStack(spacing: 10) {
                    TextField("추가할 준비물 입력", text: $newItem)
                        .font(Typography.caption.weight(.medium))
                        .focused($isInputFocused)
                        .submitLabel(.done)
                        .onSubmit { addItem() }

                    Button { addItem() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(newItem.isEmpty ? Color(.systemFill) : Brand.pink)
                    }
                    .disabled(newItem.isEmpty)
                }
                .padding(Spacing.md)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: customItems.isEmpty ? 16 : 0))
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: customItems.isEmpty ? 16 : 0,
                    bottomLeadingRadius: 16,
                    bottomTrailingRadius: 16,
                    topTrailingRadius: customItems.isEmpty ? 16 : 0
                ))
            }
        }
    }

    // MARK: - Check Row

    private func checkRow(_ item: String, isLast: Bool, isDeletable: Bool = false) -> some View {
        let isChecked = checked.contains(item)
        return HStack(spacing: 12) {
            Button {
                Haptics.impact(.light)
                if isChecked { checked.remove(item) }
                else { checked.insert(item) }
            } label: {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isChecked ? Brand.pink : Color(.systemFill))
                    .animation(.spring(response: 0.2), value: isChecked)
            }

            Text(item)
                .font(Typography.caption.weight(.medium))
                .foregroundStyle(isChecked ? .secondary : .primary)
                .strikethrough(isChecked, color: .secondary)
                .animation(.easeInOut(duration: 0.2), value: isChecked)

            Spacer()

            if isDeletable {
                Button {
                    customItems.removeAll { $0 == item }
                    checked.remove(item)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(.systemFill))
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        if !isLast { Divider().padding(.leading, Spacing.md + 22 + 12) }
    }

    // MARK: - Helper

    private func addItem() {
        let trimmed = newItem.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        customItems.append(trimmed)
        newItem = ""
        isInputFocused = false
    }
}
