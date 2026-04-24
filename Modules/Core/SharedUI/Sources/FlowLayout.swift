import SwiftUI

public struct FlowLayout: Layout {
    public var spacing: CGFloat = 8

    public init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(width: proposal.width ?? 0, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.maxHeight } + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(width: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                item.subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += row.maxHeight + spacing
        }
    }

    private func computeRows(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let needed = current.items.isEmpty ? size.width : current.width + spacing + size.width
            if needed > width && !current.items.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.items.append((subview: subview, size: size))
            current.width = current.items.isEmpty ? size.width : current.width + spacing + size.width
            current.maxHeight = max(current.maxHeight, size.height)
        }
        if !current.items.isEmpty { rows.append(current) }
        return rows
    }

    private struct Row {
        var items: [(subview: LayoutSubview, size: CGSize)] = []
        var width: CGFloat = 0
        var maxHeight: CGFloat = 0
    }
}
