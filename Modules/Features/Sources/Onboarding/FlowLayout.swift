import SwiftUI
import CoreSharedUI

struct FlowLayout: View {
    let items: [String]
    let selected: [String]
    let onTap: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: Spacing.sm) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(Typography.caption)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(selected.contains(item) ? Color.accentColor : Color(.secondarySystemBackground))
                    .foregroundStyle(selected.contains(item) ? .white : .primary)
                    .cornerRadius(8)
                    .onTapGesture { onTap(item) }
            }
        }
    }
}
