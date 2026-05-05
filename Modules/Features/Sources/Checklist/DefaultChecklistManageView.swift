import SwiftUI
import CoreSharedUI

public struct DefaultChecklistManageView: View {
    @State private var items: [String] = ChecklistStorage.load()
    @State private var newItem = ""
    @FocusState private var isInputFocused: Bool

    public init() {}

    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            List {
                Section {
                    if items.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "checklist")
                                    .font(.system(size: 28, weight: .light))
                                    .foregroundStyle(Color(.tertiaryLabel))
                                Text("준비물을 추가해보세요")
                                    .font(Typography.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 20)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(items, id: \.self) { item in
                            HStack(spacing: Spacing.md) {
                                Image(systemName: "circle")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color(.tertiaryLabel))
                                Text(item)
                                    .font(Typography.body)
                            }
                            .padding(.vertical, 2)
                        }
                        .onDelete { offsets in
                            items.remove(atOffsets: offsets)
                            ChecklistStorage.save(items)
                        }
                        .onMove { source, destination in
                            items.move(fromOffsets: source, toOffset: destination)
                            ChecklistStorage.save(items)
                        }
                    }
                } header: {
                    Text("기본 준비물")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))

                Section {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(newItem.isEmpty ? Color(.tertiaryLabel) : Brand.pink)
                        TextField("새 항목 추가", text: $newItem)
                            .font(Typography.body)
                            .focused($isInputFocused)
                            .submitLabel(.done)
                            .onSubmit { addItem() }
                        if !newItem.isEmpty {
                            Button("추가") { addItem() }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Brand.pink)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("기본 준비물 관리")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Brand.pink)
        .toolbarBackground(Brand.softPink, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton().tint(Brand.pink)
            }
        }
    }

    private func addItem() {
        let trimmed = newItem.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        items.append(trimmed)
        ChecklistStorage.save(items)
        newItem = ""
        isInputFocused = false
    }
}
