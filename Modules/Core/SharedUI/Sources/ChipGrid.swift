import SwiftUI

public struct ChipGrid: View {
    let items: [String]
    let selected: [String]
    let onTap: (String) -> Void

    public init(items: [String], selected: [String], onTap: @escaping (String) -> Void) {
        self.items = items
        self.selected = selected
        self.onTap = onTap
    }

    public var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76))], spacing: Spacing.sm) {
            ForEach(items, id: \.self) { item in
                let isSelected = selected.contains(item)
                Text(item)
                    .font(Typography.caption)
                    .padding(.horizontal, Spacing.sm + 2)
                    .padding(.vertical, Spacing.xs + 2)
                    .background(isSelected ? Brand.pink : Color(.secondarySystemBackground))
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .clipShape(Capsule())
                    .onTapGesture { onTap(item) }
            }
        }
    }
}
