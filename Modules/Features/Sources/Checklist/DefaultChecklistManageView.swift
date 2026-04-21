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
                    ForEach(items, id: \.self) { item in
                        Text(item)
                            .font(Typography.body)
                    }
                    .onDelete { offsets in
                        items.remove(atOffsets: offsets)
                        ChecklistStorage.save(items)
                    }
                    .onMove { source, destination in
                        items.move(fromOffsets: source, toOffset: destination)
                        ChecklistStorage.save(items)
                    }
                } header: {
                    Text("기본 준비물")
                }

                Section {
                    HStack(spacing: 10) {
                        TextField("새 항목 추가", text: $newItem)
                            .font(Typography.body)
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
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("기본 준비물 관리")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Brand.pink)
        .toolbarBackground(Brand.softPink, for: .navigationBar)
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
